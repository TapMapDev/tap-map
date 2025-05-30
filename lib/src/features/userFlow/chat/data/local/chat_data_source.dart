import 'package:tap_map/src/features/userFlow/chat/models/chat_model.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

/// Абстрактный класс для источников данных чатов
abstract class ChatDataSource {
  /// Получить список всех чатов
  Future<List<ChatModel>> getChats();
  
  /// Получить чат по ID
  Future<ChatModel?> getChatById(int chatId);
  
  /// Получить сообщения для определенного чата
  Future<List<MessageModel>> getMessagesForChat(int chatId);
  
  /// Создать новый чат
  Future<int> createChat({required String type, required int participantId});
  
  /// Отметить чат как прочитанный
  Future<void> markChatAsRead(int chatId);
  
  /// Отправить сообщение
  Future<MessageModel> sendMessage({
    required int chatId,
    required String text,
    int? replyToId,
    int? forwardedFromId,
    List<Map<String, String>>? attachments,
  });
  
  /// Удалить сообщение
  Future<void> deleteMessage(int chatId, int messageId, String action);
  
  /// Редактировать сообщение
  Future<void> editMessage(int chatId, int messageId, String text);
  
  /// Закрепить сообщение
  Future<void> pinMessage({required int chatId, required int messageId});
  
  /// Открепить сообщение
  Future<void> unpinMessage({required int chatId, required int messageId});
  
  /// Получить ID закрепленного сообщения
  Future<int?> getPinnedMessageId(int chatId);
  
  /// Загрузить файл
  Future<String> uploadFile(String filePath);
  
  /// Наблюдать за списком чатов (стрим)
  Stream<List<ChatModel>> watchChats();
  
  /// Наблюдать за сообщениями чата (стрим)
  Stream<List<MessageModel>> watchMessages(int chatId);
  
  /// Получить все локально кэшированные сообщения для чата
  Future<List<MessageModel>> getCachedMessagesForChat(int chatId);
  
  /// Кэшировать сообщения чата
  Future<void> cacheMessages(int chatId, List<MessageModel> messages);
  
  /// Кэшировать медиафайл
  Future<void> cacheMediaFile(String url, String localPath, String contentType);
  
  /// Получить локальный путь к медиафайлу
  Future<String?> getMediaFilePath(String url);
}
