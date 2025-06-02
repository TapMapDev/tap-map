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
      // Пытаемся получить данные с сервера
      final remotechats = await _remoteChatDataSource.getChats();
      
      // Кэшируем полученные чаты
      for (final chat in remotechats) {
        await _localChatDataSource.cacheMessages(chat.chatId, []);
      }
      
      return remotechats;
    } catch (e) {
      // В случае ошибки возвращаем данные из кэша
      return await _localChatDataSource.getChats();
    }
  }
  
  /// Получить чат и его сообщения с кэшированием
  Future<Map<String, dynamic>> fetchChatWithMessages(int chatId) async {
    try {
      // Пытаемся получить данные с сервера
      final chat = await _remoteChatDataSource.getChatById(chatId);
      final messages = await _remoteChatDataSource.getMessagesForChat(chatId);
      
      // Кэшируем полученные данные
      if (chat != null) {
        await _localChatDataSource.cacheMessages(chatId, messages);
      }
      
      // Получаем ID закрепленного сообщения
      final pinnedMessageId = await _remoteChatDataSource.getPinnedMessageId(chatId);
      
      return {
        'chat': chat,
        'messages': messages,
        'pinnedMessageId': pinnedMessageId,
      };
    } catch (e) {
      // В случае ошибки возвращаем данные из кэша
      final chat = await _localChatDataSource.getChatById(chatId);
      final messages = await _localChatDataSource.getCachedMessagesForChat(chatId);
      final pinnedMessageId = await _localChatDataSource.getPinnedMessageId(chatId);
      
      if (chat == null) {
        throw Exception('Не удалось получить данные чата: $e');
      }
      
      return {
        'chat': chat,
        'messages': messages,
        'pinnedMessageId': pinnedMessageId,
      };
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
  Future<void> pinMessage({
    required int chatId,
    required int messageId,
  }) async {
    try {
      // Закрепляем на сервере
      await _remoteChatDataSource.pinMessage(chatId: chatId, messageId: messageId);
      // И в локальном кэше
      await _localChatDataSource.pinMessage(chatId: chatId, messageId: messageId);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Открепить сообщение
  Future<bool> unpinMessage({
    required int chatId,
    required int messageId,
  }) async {
    try {
      // Открепляем на сервере
      await _remoteChatDataSource.unpinMessage(chatId: chatId, messageId: messageId);
      // И в локальном кэше
      await _localChatDataSource.unpinMessage(chatId: chatId, messageId: messageId);
      return true;
    } catch (e) {
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

  /// Получить закрепленное сообщение
  Future<MessageModel?> getPinnedMessage(int chatId) async {
    try {
      final pinnedMessageId = await getPinnedMessageId(chatId);
      if (pinnedMessageId == null) {
        return null;
      }
      
      // Пытаемся найти сообщение в кэше
      try {
        final messages = await _localChatDataSource.getMessagesForChat(chatId);
        final pinnedMessage = messages.firstWhere((m) => m.id == pinnedMessageId);
        return pinnedMessage;
      } catch (e) {
        // Если в кэше нет, пробуем получить с сервера
        final messages = await _remoteChatDataSource.getMessagesForChat(chatId);
        try {
          final pinnedMessage = messages.firstWhere((m) => m.id == pinnedMessageId);
          return pinnedMessage;
        } catch (e) {
          // Сообщение не найдено
          return null;
        }
      }
    } catch (e) {
      // Ошибка при получении ID или сообщения
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
      // Отправляем сообщение через удаленный источник данных (WebSocket)
      final message = await _remoteChatDataSource.sendMessage(
        chatId: chatId,
        text: text,
        replyToId: replyToId,
        forwardedFromId: forwardedFromId,
        attachments: attachments,
      );
      
      // Сохраняем сообщение локально для немедленного отображения
      await _localChatDataSource.cacheMessage(chatId, message);
      
      return message;
    } catch (e) {
      // Если произошла ошибка при отправке через сеть,
      // все равно создаем локальное сообщение
      try {
        final message = await _localChatDataSource.sendMessage(
          chatId: chatId,
          text: text,
          replyToId: replyToId,
          forwardedFromId: forwardedFromId,
          attachments: attachments,
        );
        return message;
      } catch (localError) {
        throw Exception('Ошибка при отправке сообщения: $e, локальная ошибка: $localError');
      }
    }
  }
  
  /// Кэшировать медиафайл
  Future<void> cacheMediaFile(String url, String contentType) async {
    try {
      // Проверяем, есть ли уже файл в кэше
      final existingPath = await _localChatDataSource.getMediaFilePath(url);
      if (existingPath != null) {
        return; // Файл уже в кэше
      }
      
      // Создаем директорию для кэша, если её нет
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      // Генерируем уникальное имя файла
      final fileName = _generateFileName(url, contentType);
      final localPath = '${cacheDir.path}/$fileName';
      
      // Кэшируем информацию о файле
      await _localChatDataSource.cacheMediaFile(url, localPath, contentType);
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

      final newMessage = MessageModel.fromJson({
        ...messageData,
        'sender_username': user.username,
      });

      print('📨 ChatRepository: Processed message - id: ${newMessage.id}, sender: ${newMessage.senderUsername}, text: ${newMessage.text}');
      
      // Кэшируем сообщение
      final chatId = newMessage.chatId;
      await _localChatDataSource.cacheMessage(chatId, newMessage);
      
      return newMessage;
    } catch (e) {
      print('❌ ChatRepository: Error processing WebSocket message: $e');
      return null;
    }
  }
}
