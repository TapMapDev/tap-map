import 'dart:io';

import 'package:tap_map/src/features/userFlow/chat/data/local/chat_data_source.dart';
import 'package:tap_map/src/features/userFlow/chat/data/local/local_chat_data_source.dart';
import 'package:tap_map/src/features/userFlow/chat/data/remote/remote_chat_data_source.dart';
import 'package:tap_map/src/features/userFlow/chat/models/chat_model.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_websocket_service.dart';
import 'package:tap_map/src/features/userFlow/user_profile/data/user_repository.dart';

/// Расширенная модель ответа с информацией об источнике данных
class MessagesResponse {
  final List<MessageModel> messages;
  final bool fromCache;
  final DateTime? lastUpdated;
  
  MessagesResponse({
    required this.messages,
    required this.fromCache,
    this.lastUpdated,
  });
}

/// Новая реализация репозитория чатов с поддержкой кэширования
class ChatRepository {
  final RemoteChatDataSource _remoteChatDataSource;
  final ChatDataSource _localChatDataSource;
  final ChatWebSocketService _webSocketService;
  final UserRepository _userRepository;

  ChatRepository({
    required RemoteChatDataSource remoteChatDataSource,
    required ChatDataSource localChatDataSource,
    required ChatWebSocketService webSocketService,
    required UserRepository userRepository,
  })  : _remoteChatDataSource = remoteChatDataSource,
        _localChatDataSource = localChatDataSource,
        _webSocketService = webSocketService,
        _userRepository = userRepository;

  /// Получить список всех чатов с кэшированием
  Future<List<ChatModel>> fetchChats() async {
    try {
      print('📱 ChatRepository: Запрос списка чатов с сервера');
      final remoteChats = await _remoteChatDataSource.getChats();
      print('📱 ChatRepository: Получено ${remoteChats.length} чатов с сервера');

      print('💾 ChatRepository: Кэширование ${remoteChats.length} чатов в локальное хранилище');
      await _localChatDataSource.cacheChats(remoteChats);
      print('💾 ChatRepository: Чаты успешно кэшированы');

      final sorted = List<ChatModel>.from(remoteChats)
        ..sort((a, b) {
          if (a.isPinned == b.isPinned) {
            return (a.pinOrder ?? 0).compareTo(b.pinOrder ?? 0);
          }
          return a.isPinned ? -1 : 1;
        });

      return sorted;
    } catch (e) {
      print('❌ ChatRepository: Ошибка при получении чатов с сервера: $e');
      print('📂 ChatRepository: Получение чатов из локального хранилища');
      final localChats = await _localChatDataSource.getChats();
      print('📂 ChatRepository: Получено ${localChats.length} чатов из локального хранилища');
      return localChats;
    }
  }
  
  /// Получить чат и его сообщения с кэшированием
  /// Обновлено для использования стратегии "сначала кэш, потом сервер"
  Future<Map<String, dynamic>> fetchChatWithMessages(int chatId) async {
    // Проверка на валидность chatId
    if (chatId <= 0) {
      print('❌ ChatRepository: Получен запрос к несуществующему чату с ID $chatId');
      throw Exception('Неверный ID чата: $chatId');
    }
    
    try {
      // Проверяем локальный кэш сначала
      final localChat = await _localChatDataSource.getChatById(chatId);
      
      // Если в кэше есть чат, возвращаем его
      if (localChat != null) {
        print('💾 ChatRepository: Возвращаем чат из локального кэша: ${localChat.chatId}');
        
        // Асинхронно обновляем данные с сервера без блокировки UI
        _updateChatDataAsync(chatId);
        
        return {
          'chat': localChat,
          'fromCache': true
        };
      }
      
      // Если в кэше нет, загружаем с сервера
      print('🌐 ChatRepository: Загружаем чат с сервера: $chatId');
      final remoteChat = await _remoteChatDataSource.getChatById(chatId);
      
      if (remoteChat != null) {
        // Кэшируем результат
        await _localChatDataSource.cacheChat(remoteChat);
        
        return {
          'chat': remoteChat,
          'fromCache': false
        };
      } else {
        // Чат не найден ни в кэше, ни на сервере
        throw Exception('Чат не найден: $chatId');
      }
    } catch (e) {
      print('❌ ChatRepository: Ошибка при загрузке чата $chatId: $e');
      throw Exception('Ошибка при загрузке чата: $e');
    }
  }
  
  /// Асинхронное обновление данных чата с сервера
  void _updateChatDataAsync(int chatId) {
    // Запускаем асинхронную задачу без await
    () async {
      try {
        print('📱 ChatRepository: Начато фоновое обновление данных чата $chatId');
        final remoteChat = await _remoteChatDataSource.getChatById(chatId);
        final pinnedId = await _remoteChatDataSource.getPinnedMessageId(chatId);
        
        if (remoteChat != null) {
          await _localChatDataSource.cacheChat(remoteChat.copyWith(pinnedMessageId: pinnedId));
          print('✅ ChatRepository: Фоновое обновление данных чата $chatId завершено');
        }
      } catch (e) {
        print('❌ ChatRepository: Ошибка при фоновом обновлении данных чата: $e');
      }
    }();
  }
  
  /// Получить только чат по ID (метод для обратной совместимости)
  Future<ChatModel?> getChatById(int chatId) async {
    // Проверка на валидность chatId
    if (chatId <= 0) {
      print('❌ ChatRepository: Попытка получить несуществующий чат с ID $chatId');
      return null;
    }
    
    try {
      final result = await fetchChatWithMessages(chatId);
      return result['chat'] as ChatModel?;
    } catch (e) {
      print('❌ ChatRepository: Ошибка в getChatById для чата $chatId: $e');
      return null;
    }
  }
  
  /// Получить сообщения для чата с использованием стратегии "сначала кэш, потом сервер"
  /// 
  /// Возвращает объект MessagesResponse, содержащий сообщения и информацию об источнике данных
  Future<MessagesResponse> getMessagesWithCacheStrategy(int chatId) async {
    print('📱 ChatRepository: Получение сообщений для чата $chatId со стратегией кэширования');
    
    try {
      // Проверяем, что источник данных - это LocalChatDataSource
      if (_localChatDataSource is! LocalChatDataSource) {
        throw Exception('Источник данных не поддерживает стратегию кэширования');
      }
      
      final localSource = _localChatDataSource as LocalChatDataSource;
      
      // Проверяем наличие и свежесть кэша
      final cachedData = await localSource.getCachedMessagesWithFreshness(chatId);
      
      final List<MessageModel> cachedMessages = cachedData['messages'];
      final bool isCacheFresh = cachedData['isFresh'];
      final DateTime? lastUpdated = cachedData['lastUpdated'];
      
      print('📱 ChatRepository: Получено ${cachedMessages.length} сообщений из кэша, '
          'свежесть кэша: $isCacheFresh, последнее обновление: $lastUpdated');
      
      // Если есть кэшированные сообщения, возвращаем их немедленно
      if (cachedMessages.isNotEmpty) {
        // Асинхронно обновляем данные с сервера, если кэш устарел
        if (!isCacheFresh) {
          print('📱 ChatRepository: Кэш устарел, запускаем фоновое обновление');
          _updateMessagesFromServerAsync(chatId);
        }
        
        return MessagesResponse(
          messages: cachedMessages,
          fromCache: true,
          lastUpdated: lastUpdated,
        );
      }
      
      // Если кэша нет, загружаем с сервера
      print('📱 ChatRepository: Кэш пуст, загружаем с сервера');
      final remoteMessages = await _remoteChatDataSource.getMessagesForChat(chatId);
      
      // Кэшируем полученные данные
      await localSource.cacheMessages(chatId, remoteMessages);
      
      return MessagesResponse(
        messages: remoteMessages,
        fromCache: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('❌ ChatRepository: Ошибка при получении сообщений: $e');
      
      // В случае ошибки пытаемся вернуть кэшированные данные
      try {
        final cachedMessages = await _localChatDataSource.getMessagesForChat(chatId);
        print('📱 ChatRepository: Возвращаем ${cachedMessages.length} сообщений из кэша после ошибки');
        
        DateTime? lastUpdated;
        if (_localChatDataSource is LocalChatDataSource) {
          lastUpdated = await (_localChatDataSource as LocalChatDataSource).getCacheTimestamp(chatId);
        }
        
        return MessagesResponse(
          messages: cachedMessages,
          fromCache: true,
          lastUpdated: lastUpdated,
        );
      } catch (cacheError) {
        print('❌ ChatRepository: Не удалось получить сообщения из кэша: $cacheError');
        // Если и кэш недоступен, возвращаем пустой список
        return MessagesResponse(
          messages: [],
          fromCache: false,
        );
      }
    }
  }
  
  /// Асинхронное обновление сообщений с сервера без блокировки UI
  void _updateMessagesFromServerAsync(int chatId) {
    // Запускаем асинхронную задачу без await
    () async {
      try {
        print('📱 ChatRepository: Начато фоновое обновление сообщений чата $chatId');
        final remoteMessages = await _remoteChatDataSource.getMessagesForChat(chatId);
        print('📱 ChatRepository: Получено ${remoteMessages.length} сообщений с сервера');
        
        // Проверяем, что источник данных - это LocalChatDataSource
        if (_localChatDataSource is LocalChatDataSource) {
          // Кэшируем полученные данные
          await (_localChatDataSource as LocalChatDataSource).cacheMessages(chatId, remoteMessages);
          print('✅ ChatRepository: Фоновое обновление сообщений чата $chatId завершено');
        }
      } catch (e) {
        print('❌ ChatRepository: Ошибка при фоновом обновлении сообщений: $e');
      }
    }();
  }
  
  /// Получить сообщения для чата (метод для обратной совместимости)
  /// Теперь использует стратегию "сначала кэш, потом сервер"
  Future<List<MessageModel>> getMessages(int chatId) async {
    print('📱 ChatRepository: Вызов getMessages с новой стратегией кэширования');
    final response = await getMessagesWithCacheStrategy(chatId);
    return response.messages;
  }
  
  /// Создать новый чат
  Future<int> createChat({required String type, required int participantId}) async {
    return await _remoteChatDataSource.createChat(
      type: type,
      participantId: participantId,
    );
  }
  
  /// Отметить чат как прочитанный
  Future<void> markChatAsRead(int chatId) async {
    try {
      // Отмечаем в локальном кэше
      await _localChatDataSource.markChatAsRead(chatId);
      
      // Отправляем событие прочтения через WebSocket
      try {
        _webSocketService.sendReadAllMessages(chatId);
      } catch (e) {
        print('❌ ChatRepository: Не удалось отправить WebSocket-событие о прочтении: $e');
      }
    } catch (e) {
      print('❌ ChatRepository: Ошибка при отметке чата как прочитанного: $e');
      rethrow;
    }
  }
  
  /// Получить историю чата
  Future<List<MessageModel>> getChatHistory(int chatId) async {
    try {
      // Пытаемся получить с сервера
      final messages = await _remoteChatDataSource.getMessagesForChat(chatId);
      // Кэшируем
      await _localChatDataSource.cacheMessages(chatId, messages);
      return messages;
    } catch (e) {
      // В случае ошибки возвращаем из кэша
      return await _localChatDataSource.getCachedMessagesForChat(chatId);
    }
  }
  
  /// Удалить сообщение
  Future<bool> deleteMessage({
    required int chatId, 
    required int messageId, 
    required bool deleteForAll
  }) async {
    try {
      final action = deleteForAll ? 'all' : 'for_me';
      // Удаляем на сервере
      await _remoteChatDataSource.deleteMessage(chatId, messageId, action);
      // И в локальном кэше
      await _localChatDataSource.deleteMessage(chatId, messageId, action);
      return true;
    } catch (e) {
      // Если только локально (для себя)
      if (!deleteForAll) {
        try {
          await _localChatDataSource.deleteMessage(chatId, messageId, 'for_me');
          return true;
        } catch (_) {
          return false;
        }
      }
      return false;
    }
  }
  
  /// Редактировать сообщение
  Future<MessageModel?> editMessage({
    required int chatId, 
    required int messageId, 
    required String text
  }) async {
    try {
      // Редактируем на сервере
      final editedMessage = await _remoteChatDataSource.editMessage(chatId, messageId, text);
      // И в локальном кэше
      await _localChatDataSource.editMessage(chatId, messageId, text);
      return editedMessage;
    } catch (e) {
      return null;
    }
  }
  
  /// Закрепить сообщение
  Future<bool> pinMessage({
    required int chatId,
    required int messageId,
  }) async {
    try {
      print('📱 ChatRepository: Закрепление сообщения $messageId в чате $chatId');
      // Закрепляем на сервере
      await _remoteChatDataSource.pinMessage(chatId: chatId, messageId: messageId);
      // И в локальном кэше
      await _localChatDataSource.pinMessage(chatId: chatId, messageId: messageId);
      
      // Обновляем кэш закрепленных сообщений после закрепления
      print('📱 ChatRepository: Обновление кэша закрепленных сообщений после закрепления');
      await _updatePinnedMessagesAsync(chatId);
      
      return true;
    } catch (e) {
      print('❌ ChatRepository: Ошибка при закреплении сообщения: $e');
      return false;
    }
  }
  
  /// Открепить сообщение
  Future<bool> unpinMessage({
    required int chatId,
    required int messageId,
  }) async {
    try {
      print('📱 ChatRepository: Открепление сообщения $messageId в чате $chatId');
      // Открепляем на сервере
      await _remoteChatDataSource.unpinMessage(chatId: chatId, messageId: messageId);
      // И в локальном кэше
      await _localChatDataSource.unpinMessage(chatId: chatId, messageId: messageId);
      
      // Обновляем кэш закрепленных сообщений после открепления
      print('📱 ChatRepository: Обновление кэша закрепленных сообщений после открепления');
      await _updatePinnedMessagesAsync(chatId);
      
      return true;
    } catch (e) {
      print('❌ ChatRepository: Ошибка при откреплении сообщения: $e');
      return false;
    }
  }
  
  /// Получить ID закрепленного сообщения
  Future<int?> getPinnedMessageId(int chatId) async {
    try {
      return await _remoteChatDataSource.getPinnedMessageId(chatId);
    } catch (e) {
      return await _localChatDataSource.getPinnedMessageId(chatId);
    }
  }

  /// Получить закрепленное сообщение чата
  Future<MessageModel?> getPinnedMessage(int chatId) async {
    try {
      print('📂 ChatRepository: Получение закрепленного сообщения для чата $chatId');
      final pinnedMessages = await getPinnedMessages(chatId);
      if (pinnedMessages.isNotEmpty) {
        print('📂 ChatRepository: Закрепленное сообщение найдено для чата $chatId');
        return pinnedMessages.first;
      } else {
        print('📂 ChatRepository: Закрепленное сообщение не найдено для чата $chatId');
        return null;
      }
    } catch (e) {
      print('❌ ChatRepository: Ошибка при получении закрепленного сообщения: $e');
      return null;
    }
  }
  
  /// Загрузить файл
  Future<String> uploadFile({
    required File file,
    Function(double)? onProgress,
  }) async {
    // Загрузка файла может происходить только через удаленный источник
    return await _remoteChatDataSource.uploadFile(
      file.path
    );
  }
  
  /// Отправить сообщение
  Future<MessageModel> sendMessage({
    required int chatId,
    required String text,
    int? replyToId,
    int? forwardedFromId,
    List<Map<String, String>>? attachments,
  }) async {
    try {
      // Проверяем, инициализирован ли WebSocketService
      if (_webSocketService.currentUsername == null) {
        print('❌ ChatRepository: Имя пользователя не установлено в WebSocketService');
        throw Exception('Имя пользователя не установлено в WebSocketService');
      }
      
      print('📤 ChatRepository: Отправка сообщения в чат $chatId через WebSocket');
      final message = await _remoteChatDataSource.sendMessage(
        chatId: chatId,
        text: text,
        replyToId: replyToId,
        forwardedFromId: forwardedFromId,
        attachments: attachments,
      );
      
      print('💾 ChatRepository: Кэширование отправленного сообщения в локальное хранилище');
      // Кэшируем сообщение
      await _localChatDataSource.cacheMessage(message.chatId, message);
      print('💾 ChatRepository: Сообщение успешно кэшировано, ID: ${message.id}');
      
      return message;
    } catch (e) {
      print('❌ ChatRepository: Ошибка при отправке сообщения: $e');
      throw Exception('Ошибка при отправке сообщения: $e');
    }
  }
  
  /// Кэшировать медиафайл
  Future<void> cacheMediaFile(String url, String contentType) async {
    try {
      print('🖼️ ChatRepository: Проверка наличия медиафайла в кэше: $url');
      // Проверяем, есть ли уже файл в кэше
      final existingPath = await _localChatDataSource.getMediaFilePath(url);
      if (existingPath != null) {
        print('🖼️ ChatRepository: Медиафайл уже в кэше: $existingPath');
        return; // Файл уже в кэше
      }
      
      print('🖼️ ChatRepository: Подготовка директории для кэширования медиафайла');
      // Создаем директорию для кэша, если её нет
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
        print('🖼️ ChatRepository: Создана директория для кэша: ${cacheDir.path}');
      }
      
      // Генерируем уникальное имя файла
      final fileName = _generateFileName(url, contentType);
      final localPath = '${cacheDir.path}/$fileName';
      
      print('🖼️ ChatRepository: Кэширование медиафайла в локальное хранилище');
      // Кэшируем информацию о файле
      await _localChatDataSource.cacheMediaFile(url, localPath, contentType);
      print('🖼️ ChatRepository: Медиафайл успешно кэширован');
    } catch (e) {
      // Игнорируем ошибки кэширования
      print('Ошибка кэширования медиафайла: $e');
    }
  }
  
  /// Получить путь к кэшированному медиафайлу
  Future<String?> getMediaFilePath(String url) async {
    return await _localChatDataSource.getMediaFilePath(url);
  }
  
  /// Наблюдать за списком чатов (стрим)
  Stream<List<ChatModel>> watchChats() {
    return _localChatDataSource.watchChats();
  }
  
  /// Наблюдать за сообщениями чата (стрим)
  Stream<List<MessageModel>> watchMessages(int chatId) {
    return _localChatDataSource.watchMessages(chatId);
  }
  
  // Геттеры для доступа к WebSocket
  
  /// Получить поток событий WebSocket
  Stream<WebSocketEventData> get webSocketEvents => _webSocketService.events;
  
  /// Получить сервис WebSocket
  ChatWebSocketService get webSocketService => _webSocketService;
  
  /// Получить текущее состояние соединения
  ConnectionState get currentConnectionState => _webSocketService.connectionState;
  
  // Вспомогательные методы
  
  Future<Directory> _getCacheDirectory() async {
    final cacheDir = Directory('/Users/jkaseq/Documents/projects/tap-map/cache/chat_media');
    return cacheDir;
  }
  
  String _generateFileName(String url, String contentType) {
    final extension = _getExtensionFromContentType(contentType);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${url.hashCode}_$timestamp$extension';
    return fileName;
  }
  
  String _getExtensionFromContentType(String contentType) {
    if (contentType.startsWith('image/jpeg')) return '.jpg';
    if (contentType.startsWith('image/png')) return '.png';
    if (contentType.startsWith('image/gif')) return '.gif';
    if (contentType.startsWith('image/webp')) return '.webp';
    if (contentType.startsWith('video/mp4')) return '.mp4';
    if (contentType.startsWith('video/quicktime')) return '.mov';
    return '';
  }

  /// Подключиться к чату через WebSocket
  Future<bool> connectToChat() async {
    try {
      final success = await _webSocketService.connect();
      
      // Получаем и устанавливаем имя текущего пользователя
      final user = await _userRepository.getCurrentUser();
      if (user.username != null) {
        _webSocketService.setCurrentUsername(user.username!);
      }
      
      return success;
    } catch (e) {
      print('❌ ChatRepository: Ошибка подключения к чату: $e');
      return false;
    }
  }

  /// Отключиться от чата
  void disconnectFromChat() {
    _webSocketService.disconnect();
  }

  /// Отправить статус "Печатает"
  void sendTyping({required int chatId, required bool isTyping}) {
    _webSocketService.sendTyping(chatId: chatId, isTyping: isTyping);
  }

  /// Обработать входящее сообщение из WebSocket и обогатить его данными о пользователе
  Future<MessageModel?> processWebSocketMessage(Map<String, dynamic> messageData) async {
    try {
      print('📩 ChatRepository: Processing WebSocket message: $messageData');
      
      final int? senderId = messageData['sender_id'] ?? messageData['user_id'];
      if (senderId == null) {
        print('❌ ChatRepository: No sender_id or user_id in message data');
        return null;
      }

      final user = await _userRepository.getUserById(senderId);

      final newMessage = MessageModel.fromJson({
        ...messageData,
        'sender_username': user.username,
      });

      print('📨 ChatRepository: Processed message - id: ${newMessage.id}, sender: ${newMessage.senderUsername}, text: ${newMessage.text}');
      
      await _localChatDataSource.cacheMessage(newMessage.chatId, newMessage);

      // Обновляем информацию о чате
      await _updateChatFromMessage(newMessage);

      return newMessage;
    } catch (e) {
      print('❌ ChatRepository: Error processing WebSocket message: $e');
      return null;
    }
  }

  /// Обновить информацию о чате на основе нового сообщения
  Future<void> _updateChatFromMessage(MessageModel message) async {
    try {
      final existingChat = await _localChatDataSource.getChatById(message.chatId);
      ChatModel? chat;

      if (existingChat != null) {
        chat = existingChat.copyWith(
          lastMessageText: message.text,
          lastMessageSenderUsername: message.senderUsername,
          lastMessageCreatedAt: message.createdAt,
          unreadCount: existingChat.unreadCount + 1,
        );
      } else {
        final remoteChat = await _remoteChatDataSource.getChatById(message.chatId);
        if (remoteChat != null) {
          chat = remoteChat.copyWith(
            lastMessageText: message.text,
            lastMessageSenderUsername: message.senderUsername,
            lastMessageCreatedAt: message.createdAt,
            unreadCount: 1,
          );
        }
      }

      if (chat != null) {
        await _localChatDataSource.cacheChat(chat);
      }
    } catch (e) {
      print('❌ ChatRepository: Не удалось обновить чат: $e');
    }
  }

  /// Получить сообщение по его ID
  Future<MessageModel?> getMessageById(int chatId, int messageId) async {
    try {
      // Сначала проверяем в локальном кэше
      final localMessage = await _localChatDataSource.getMessageById(chatId, messageId);
      if (localMessage != null) {
        return localMessage;
      }
      
      // Если нет в кэше, загружаем с сервера
      return await _remoteChatDataSource.getMessageById(chatId, messageId);
    } catch (e) {
      print('❌ ChatRepository: Ошибка при получении сообщения по ID $messageId: $e');
      return null;
    }
  }
  
  /// Получить список закрепленных сообщений чата
  Future<List<MessageModel>> getPinnedMessages(int chatId) async {
    try {
      // Пытаемся получить закрепленные сообщения с сервера
      print('📱 ChatRepository: Запрос закрепленных сообщений для чата $chatId');
      final pinnedMessages = await _remoteChatDataSource.getPinnedMessages(chatId);
      
      print('📱 ChatRepository: Получено ${pinnedMessages.length} закрепленных сообщений с сервера');
      
      // Обеспечиваем кэширование сообщений
      for (var message in pinnedMessages) {
        await _localChatDataSource.cacheMessage(chatId, message);
      }
      
      return pinnedMessages;
    } catch (e) {
      print('❌ ChatRepository: Ошибка при получении закрепленных сообщений: $e');
      
      // В случае ошибки, пытаемся получить из локального хранилища
      try {
        final localPinnedMessages = await _localChatDataSource.getPinnedMessages(chatId);
        print('📂 ChatRepository: Получено ${localPinnedMessages.length} закрепленных сообщений из локального хранилища');
        return localPinnedMessages;
      } catch (e) {
        print('❌ ChatRepository: Ошибка при получении закрепленных сообщений из локального хранилища: $e');
        return [];
      }
    }
  }

  /// Асинхронное обновление закрепленных сообщений с сервера
  Future<void> _updatePinnedMessagesAsync(int chatId) async {
    try {
      print('📱 ChatRepository: Асинхронное обновление закрепленных сообщений для чата $chatId');
      final pinnedMessages = await _remoteChatDataSource.getPinnedMessages(chatId);
      print('📱 ChatRepository: Получено ${pinnedMessages.length} закрепленных сообщений с сервера');
      
      // Обновляем локальное хранилище
      for (var message in pinnedMessages) {
        await _localChatDataSource.cacheMessage(chatId, message);
      }
      
      print('📱 ChatRepository: Закрепленные сообщения для чата $chatId успешно обновлены в кэше');
    } catch (e) {
      print('❌ ChatRepository: Ошибка при асинхронном обновлении закрепленных сообщений: $e');
    }
  }

  /// Сбрасывает счетчик непрочитанных сообщений для указанного чата
  Future<void> resetUnreadCount(int chatId) async {
    try {
      final existingChat = await _localChatDataSource.getChatById(chatId);
      
      if (existingChat != null && existingChat.unreadCount > 0) {
        // Создаем копию чата с обнуленным счетчиком
        final updatedChat = existingChat.copyWith(unreadCount: 0);
        
        // Сохраняем обновленный чат в локальной базе
        await _localChatDataSource.cacheChat(updatedChat);
        
        // Отправляем сообщение о прочтении через WebSocket
        try {
          // Отправка события прочтения через WebSocket вместо HTTP-запроса
          _webSocketService.sendReadAllMessages(chatId);
        } catch (e) {
          print('❌ ChatRepository: Не удалось отправить WebSocket-событие о прочтении: $e');
        }
        
        print('✅ ChatRepository: Счетчик непрочитанных сообщений для чата $chatId сброшен');
      }
    } catch (e) {
      print('❌ ChatRepository: Не удалось сбросить счетчик непрочитанных сообщений: $e');
    }
  }
}
