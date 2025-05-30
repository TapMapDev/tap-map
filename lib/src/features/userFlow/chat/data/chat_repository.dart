import 'dart:io';

import 'package:tap_map/src/features/userFlow/chat/data/local/chat_data_source.dart';
import 'package:tap_map/src/features/userFlow/chat/models/chat_model.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

/// Новая реализация репозитория чатов с поддержкой кэширования
class ChatRepository {
  final ChatDataSource _remoteDataSource;
  final ChatDataSource _localDataSource;
  
  ChatRepository({
    required ChatDataSource remoteDataSource,
    required ChatDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;
        
  /// Получить список всех чатов с кэшированием
  Future<List<ChatModel>> fetchChats() async {
    try {
      // Пытаемся получить данные с сервера
      final remotechats = await _remoteDataSource.getChats();
      
      // Кэшируем полученные чаты
      for (final chat in remotechats) {
        await _localDataSource.cacheMessages(chat.chatId, []);
      }
      
      return remotechats;
    } catch (e) {
      // В случае ошибки возвращаем данные из кэша
      return await _localDataSource.getChats();
    }
  }
  
  /// Получить чат и его сообщения с кэшированием
  Future<Map<String, dynamic>> fetchChatWithMessages(int chatId) async {
    try {
      // Пытаемся получить данные с сервера
      final chat = await _remoteDataSource.getChatById(chatId);
      final messages = await _remoteDataSource.getMessagesForChat(chatId);
      
      // Кэшируем полученные данные
      if (chat != null) {
        await _localDataSource.cacheMessages(chatId, messages);
      }
      
      // Получаем ID закрепленного сообщения
      final pinnedMessageId = await _remoteDataSource.getPinnedMessageId(chatId);
      
      return {
        'chat': chat,
        'messages': messages,
        'pinnedMessageId': pinnedMessageId,
      };
    } catch (e) {
      // В случае ошибки возвращаем данные из кэша
      final chat = await _localDataSource.getChatById(chatId);
      final messages = await _localDataSource.getCachedMessagesForChat(chatId);
      final pinnedMessageId = await _localDataSource.getPinnedMessageId(chatId);
      
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
  
  /// Создать новый чат
  Future<int> createChat({required String type, required int participantId}) async {
    return await _remoteDataSource.createChat(
      type: type,
      participantId: participantId,
    );
  }
  
  /// Отметить чат как прочитанный
  Future<void> markChatAsRead(int chatId) async {
    try {
      // Отмечаем на сервере
      await _remoteDataSource.markChatAsRead(chatId);
      // И в локальном кэше
      await _localDataSource.markChatAsRead(chatId);
    } catch (e) {
      // В случае ошибки отмечаем только в локальном кэше
      await _localDataSource.markChatAsRead(chatId);
      rethrow;
    }
  }
  
  /// Получить историю чата
  Future<List<MessageModel>> getChatHistory(int chatId) async {
    try {
      // Пытаемся получить с сервера
      final messages = await _remoteDataSource.getMessagesForChat(chatId);
      // Кэшируем
      await _localDataSource.cacheMessages(chatId, messages);
      return messages;
    } catch (e) {
      // В случае ошибки возвращаем из кэша
      return await _localDataSource.getCachedMessagesForChat(chatId);
    }
  }
  
  /// Удалить сообщение
  Future<void> deleteMessage(int chatId, int messageId, String action) async {
    try {
      // Удаляем на сервере
      await _remoteDataSource.deleteMessage(chatId, messageId, action);
      // И в локальном кэше
      await _localDataSource.deleteMessage(chatId, messageId, action);
    } catch (e) {
      // Если только локально (для себя)
      if (action == 'for_me') {
        await _localDataSource.deleteMessage(chatId, messageId, action);
      }
      rethrow;
    }
  }
  
  /// Редактировать сообщение
  Future<void> editMessage(int chatId, int messageId, String text) async {
    try {
      // Редактируем на сервере
      await _remoteDataSource.editMessage(chatId, messageId, text);
      // И в локальном кэше
      await _localDataSource.editMessage(chatId, messageId, text);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Закрепить сообщение
  Future<void> pinMessage({
    required int chatId,
    required int messageId,
  }) async {
    try {
      // Закрепляем на сервере
      await _remoteDataSource.pinMessage(chatId: chatId, messageId: messageId);
      // И в локальном кэше
      await _localDataSource.pinMessage(chatId: chatId, messageId: messageId);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Открепить сообщение
  Future<void> unpinMessage({
    required int chatId,
    required int messageId,
  }) async {
    try {
      // Открепляем на сервере
      await _remoteDataSource.unpinMessage(chatId: chatId, messageId: messageId);
      // И в локальном кэше
      await _localDataSource.unpinMessage(chatId: chatId, messageId: messageId);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Получить ID закрепленного сообщения
  Future<int?> getPinnedMessageId(int chatId) async {
    try {
      return await _remoteDataSource.getPinnedMessageId(chatId);
    } catch (e) {
      return await _localDataSource.getPinnedMessageId(chatId);
    }
  }
  
  /// Загрузить файл
  Future<String> uploadFile(String filePath) async {
    // Загрузка файла может происходить только через удаленный источник
    return await _remoteDataSource.uploadFile(filePath);
  }
  
  /// Кэшировать медиафайл
  Future<void> cacheMediaFile(String url, String contentType) async {
    try {
      // Проверяем, есть ли уже файл в кэше
      final existingPath = await _localDataSource.getMediaFilePath(url);
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
      await _localDataSource.cacheMediaFile(url, localPath, contentType);
    } catch (e) {
      // Игнорируем ошибки кэширования
      print('Ошибка кэширования медиафайла: $e');
    }
  }
  
  /// Получить путь к кэшированному медиафайлу
  Future<String?> getMediaFilePath(String url) async {
    return await _localDataSource.getMediaFilePath(url);
  }
  
  /// Наблюдать за списком чатов (стрим)
  Stream<List<ChatModel>> watchChats() {
    return _localDataSource.watchChats();
  }
  
  /// Наблюдать за сообщениями чата (стрим)
  Stream<List<MessageModel>> watchMessages(int chatId) {
    return _localDataSource.watchMessages(chatId);
  }
  
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
}
