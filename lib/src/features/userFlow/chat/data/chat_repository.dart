import 'dart:io';

import 'package:tap_map/src/features/userFlow/chat/data/local/chat_data_source.dart';
import 'package:tap_map/src/features/userFlow/chat/data/remote/remote_chat_data_source.dart';
import 'package:tap_map/src/features/userFlow/chat/models/chat_model.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_websocket_service.dart';
import 'package:tap_map/src/features/userFlow/user_profile/data/user_repository.dart';

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
  Future<Map<String, dynamic>> fetchChatWithMessages(int chatId) async {
    print('📂 ChatRepository: Получение чата $chatId из локального хранилища');
    final localChat = await _localChatDataSource.getChatById(chatId);
    print('📂 ChatRepository: Чат $chatId ${localChat != null ? 'найден' : 'не найден'} в локальном хранилище');
    
    final localMessages = await _localChatDataSource.getCachedMessagesForChat(chatId);
    print('📂 ChatRepository: Получено ${localMessages.length} сообщений из локального хранилища для чата $chatId');
    
    final localPinnedId = await _localChatDataSource.getPinnedMessageId(chatId);
    print('📂 ChatRepository: Закрепленное сообщение ID: $localPinnedId для чата $chatId из локального хранилища');

    if (localChat != null && localMessages.isNotEmpty) {
      print('📂 ChatRepository: Возвращаем данные из локального хранилища и асинхронно обновляем с сервера');
      // Асинхронно обновляем данные с сервера
      () async {
        try {
          print('📱 ChatRepository: Асинхронное обновление чата $chatId с сервера');
          final remoteChat = await _remoteChatDataSource.getChatById(chatId);
          final remoteMessages = await _remoteChatDataSource.getMessagesForChat(chatId);
          final pinnedId = await _remoteChatDataSource.getPinnedMessageId(chatId);
          print('📱 ChatRepository: Получено с сервера: чат: ${remoteChat != null}, сообщений: ${remoteMessages.length}, закрепленное ID: $pinnedId');

          if (remoteChat != null) {
            print('💾 ChatRepository: Кэширование обновленных данных чата $chatId');
            await _localChatDataSource.cacheChat(remoteChat.copyWith(pinnedMessageId: pinnedId));
            await _localChatDataSource.cacheMessages(chatId, remoteMessages);
            print('💾 ChatRepository: Данные чата $chatId успешно обновлены в кэше');
          }
        } catch (e) {
          print('❌ ChatRepository: Ошибка при асинхронном обновлении чата: $e');
        }
      }();

      return {
        'chat': localChat,
        'messages': localMessages,
        'pinnedMessageId': localPinnedId,
      };
    }

    try {
      print('📱 ChatRepository: Получение чата $chatId с сервера');
      final chat = await _remoteChatDataSource.getChatById(chatId);
      final messages = await _remoteChatDataSource.getMessagesForChat(chatId);
      print('📱 ChatRepository: Получено с сервера: чат: ${chat != null}, сообщений: ${messages.length}');

      // Получаем ID закрепленного сообщения
      final pinnedMessageId = await _remoteChatDataSource.getPinnedMessageId(chatId);
      print('📱 ChatRepository: Получено закрепленное сообщение ID: $pinnedMessageId с сервера');

      // Кэшируем полученные данные
      if (chat != null) {
        print('💾 ChatRepository: Кэширование данных чата $chatId в локальное хранилище');
        await _localChatDataSource.cacheChat(chat.copyWith(pinnedMessageId: pinnedMessageId));
        await _localChatDataSource.cacheMessages(chatId, messages);
        print('💾 ChatRepository: Данные чата $chatId успешно кэшированы');
      }

      return {
        'chat': chat,
        'messages': messages,
        'pinnedMessageId': pinnedMessageId,
      };
    } catch (e) {
      print('❌ ChatRepository: Ошибка при получении чата с сервера: $e');
      if (localChat != null) {
        print('📂 ChatRepository: Возвращаем данные из локального хранилища после ошибки сервера');
        return {
          'chat': localChat,
          'messages': localMessages,
          'pinnedMessageId': localPinnedId,
        };
      }

      print('❌ ChatRepository: Данные не найдены ни на сервере, ни в локальном хранилище');
      throw Exception('Не удалось получить данные чата: $e');
    }
  }
  
  /// Получить только чат по ID (метод для обратной совместимости)
  Future<ChatModel?> getChatById(int chatId) async {
    try {
      final result = await fetchChatWithMessages(chatId);
      return result['chat'] as ChatModel?;
    } catch (e) {
      return null;
    }
  }
  
  /// Получить сообщения для чата (метод для обратной совместимости)
  Future<List<MessageModel>> getMessages(int chatId) async {
    try {
      final result = await fetchChatWithMessages(chatId);
      return result['messages'] as List<MessageModel>;
    } catch (e) {
      return [];
    }
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
      // Отмечаем на сервере
      await _remoteChatDataSource.markChatAsRead(chatId);
      // И в локальном кэше
      await _localChatDataSource.markChatAsRead(chatId);
    } catch (e) {
      // В случае ошибки отмечаем только в локальном кэше
      await _localChatDataSource.markChatAsRead(chatId);
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

  /// Отметить сообщение как прочитанное
  void markMessageAsRead({required int chatId, required int messageId}) {
    _webSocketService.readMessage(chatId: chatId, messageId: messageId);
  }

  /// Обработать входящее сообщение из WebSocket и обогатить его данными о пользователе
  Future<MessageModel?> processWebSocketMessage(Map<String, dynamic> messageData) async {
    try {
      final senderId = messageData['sender_id'] as int?;
      if (senderId == null) {
        print('❌ ChatRepository: No sender_id in message data');
        return null;
      }

      final user = await _userRepository.getUserById(senderId);
      if (user.username == null) {
        print('❌ ChatRepository: No username for sender_id: $senderId');
        return null;
      }
      
      // Проверка на корректность формата attachments
      final attachments = messageData['attachments'];
      dynamic processedAttachments = attachments;
      
      // Если attachments - это Map, преобразуем его в List
      if (attachments is Map) {
        processedAttachments = [attachments];
      } else if (attachments != null && !(attachments is List)) {
        // Если это не List и не Map, то создаем пустой список
        processedAttachments = [];
      }
      
      final messageDataWithCorrectAttachments = {
        ...messageData,
        'attachments': processedAttachments,
        'sender_username': user.username,
      };

      final newMessage = MessageModel.fromJson(messageDataWithCorrectAttachments);

      print('📨 ChatRepository: Processed message - id: ${newMessage.id}, sender: ${newMessage.senderUsername}, text: ${newMessage.text}');
      
      print('💾 ChatRepository: Кэширование сообщения в локальное хранилище');
      // Кэшируем сообщение
      await _localChatDataSource.cacheMessage(newMessage.chatId, newMessage);
      print('💾 ChatRepository: Сообщение успешно кэшировано');
      
      return newMessage;
    } catch (e) {
      print('❌ ChatRepository: Error processing WebSocket message: $e');
      return null;
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
}
