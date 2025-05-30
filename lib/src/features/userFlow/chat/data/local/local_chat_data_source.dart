import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tap_map/src/features/userFlow/chat/data/local/chat_data_source.dart';
import 'package:tap_map/src/features/userFlow/chat/data/local/chat_database.dart';
import 'package:tap_map/src/features/userFlow/chat/models/chat_model.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

/// Реализация локального источника данных для чатов
class LocalChatDataSource implements ChatDataSource {
  final ChatDatabase _database;
  
  LocalChatDataSource(this._database);
  
  @override
  Future<List<ChatModel>> getChats() async {
    final chats = await _database.getAllChats();
    return chats.map(_mapChatToModel).toList();
  }
  
  @override
  Stream<List<ChatModel>> watchChats() {
    return _database.watchAllChats().map(
      (chats) => chats.map(_mapChatToModel).toList(),
    );
  }
  
  @override
  Future<ChatModel?> getChatById(int chatId) async {
    final chat = await _database.getChatById(chatId);
    if (chat == null) return null;
    return _mapChatToModel(chat);
  }
  
  @override
  Future<List<MessageModel>> getMessagesForChat(int chatId) async {
    final messages = await _database.getMessagesForChat(chatId);
    return messages.map(_mapMessageToModel).toList();
  }
  
  @override
  Stream<List<MessageModel>> watchMessages(int chatId) {
    return _database.watchMessagesForChat(chatId).map(
      (messages) => messages.map(_mapMessageToModel).toList(),
    );
  }
  
  @override
  Future<int> createChat({required String type, required int participantId}) {
    // Локальный источник не может создавать чаты
    throw UnimplementedError('Локальный источник не может создавать чаты');
  }
  
  @override
  Future<void> markChatAsRead(int chatId) async {
    await _database.markMessagesAsRead(chatId);
  }
  
  @override
  Future<MessageModel> sendMessage({
    required int chatId, 
    required String text, 
    int? replyToId, 
    int? forwardedFromId,
    List<Map<String, String>>? attachments,
  }) {
    // Локальный источник не может отправлять сообщения
    throw UnimplementedError('Локальный источник не может отправлять сообщения');
  }
  
  @override
  Future<void> deleteMessage(int chatId, int messageId, String action) async {
    await _database.deleteMessage(messageId);
  }
  
  @override
  Future<void> editMessage(int chatId, int messageId, String text) async {
    final message = await _database.getMessageById(messageId);
    if (message != null) {
      await _database.insertMessage(
        MessagesCompanion(
          messageId: Value(messageId),
          chatId: Value(chatId),
          messageText: Value(text), // Обновлено с text на messageText
          senderUsername: Value(message.senderUsername),
          senderUserId: Value(message.senderUserId),
          createdAt: Value(message.createdAt),
          editedAt: Value(DateTime.now()),
          replyToId: Value(message.replyToId),
          forwardedFromId: Value(message.forwardedFromId),
          attachmentsJson: Value(message.attachmentsJson), // Обновлено с attachments на attachmentsJson
          messageType: Value(message.messageType), // Обновлено с type на messageType
          isPinned: Value(message.isPinned),
          isRead: Value(message.isRead),
          isMe: Value(message.isMe),
        ),
      );
    }
  }
  
  @override
  Future<void> pinMessage({required int chatId, required int messageId}) async {
    // Обновляем флаг в сообщении
    final message = await _database.getMessageById(messageId);
    if (message != null) {
      await _database.insertMessage(
        MessagesCompanion(
          messageId: Value(messageId),
          chatId: Value(chatId),
          messageText: Value(message.messageText), // Обновлено с text на messageText
          senderUsername: Value(message.senderUsername),
          senderUserId: Value(message.senderUserId),
          createdAt: Value(message.createdAt),
          editedAt: Value(message.editedAt),
          replyToId: Value(message.replyToId),
          forwardedFromId: Value(message.forwardedFromId),
          attachmentsJson: Value(message.attachmentsJson), // Обновлено с attachments на attachmentsJson
          messageType: Value(message.messageType), // Обновлено с type на messageType
          isPinned: const Value(true),
          isRead: Value(message.isRead),
          isMe: Value(message.isMe),
        ),
      );
    }
    
    // Обновляем ID закрепленного сообщения в чате
    final chat = await _database.getChatById(chatId);
    if (chat != null) {
      await _database.insertChat(
        ChatsCompanion(
          chatId: Value(chatId),
          chatName: Value(chat.chatName),
          lastMessageText: Value(chat.lastMessageText),
          lastMessageSenderUsername: Value(chat.lastMessageSenderUsername),
          lastMessageCreatedAt: Value(chat.lastMessageCreatedAt),
          unreadCount: Value(chat.unreadCount),
          pinnedMessageId: Value(messageId),
          updatedAt: Value(chat.updatedAt),
        ),
      );
    }
  }
  
  @override
  Future<void> unpinMessage({required int chatId, required int messageId}) async {
    // Обновляем флаг в сообщении
    final message = await _database.getMessageById(messageId);
    if (message != null) {
      await _database.insertMessage(
        MessagesCompanion(
          messageId: Value(messageId),
          chatId: Value(chatId),
          messageText: Value(message.messageText), // Обновлено с text на messageText
          senderUsername: Value(message.senderUsername),
          senderUserId: Value(message.senderUserId),
          createdAt: Value(message.createdAt),
          editedAt: Value(message.editedAt),
          replyToId: Value(message.replyToId),
          forwardedFromId: Value(message.forwardedFromId),
          attachmentsJson: Value(message.attachmentsJson), // Обновлено с attachments на attachmentsJson
          messageType: Value(message.messageType), // Обновлено с type на messageType
          isPinned: const Value(false),
          isRead: Value(message.isRead),
          isMe: Value(message.isMe),
        ),
      );
    }
    
    // Обновляем ID закрепленного сообщения в чате
    final chat = await _database.getChatById(chatId);
    if (chat != null) {
      await _database.insertChat(
        ChatsCompanion(
          chatId: Value(chatId),
          chatName: Value(chat.chatName),
          lastMessageText: Value(chat.lastMessageText),
          lastMessageSenderUsername: Value(chat.lastMessageSenderUsername),
          lastMessageCreatedAt: Value(chat.lastMessageCreatedAt),
          unreadCount: Value(chat.unreadCount),
          pinnedMessageId: const Value(null),
          updatedAt: Value(chat.updatedAt),
        ),
      );
    }
  }
  
  @override
  Future<int?> getPinnedMessageId(int chatId) async {
    final chat = await _database.getChatById(chatId);
    return chat?.pinnedMessageId;
  }
  
  @override
  Future<String> uploadFile(String filePath) {
    // Локальный источник не может загружать файлы
    throw UnimplementedError('Локальный источник не может загружать файлы');
  }
  
  @override
  Future<List<MessageModel>> getCachedMessagesForChat(int chatId) async {
    return getMessagesForChat(chatId);
  }
  
  @override
  Future<void> cacheMessages(int chatId, List<MessageModel> messages) async {
    for (final message in messages) {
      await _database.insertMessage(
        MessagesCompanion(
          messageId: Value(message.id),
          chatId: Value(chatId),
          messageText: Value(message.text), // Обновлено с text на messageText
          senderUsername: Value(message.senderUsername),
          senderUserId: Value(message.senderUserId),
          createdAt: Value(message.createdAt),
          editedAt: Value(message.editedAt),
          replyToId: Value(message.replyToId),
          forwardedFromId: Value(message.forwardedFromId),
          attachmentsJson: Value(_encodeAttachments(message.attachments)), // Обновлено с attachments на attachmentsJson
          messageType: Value(message.type.toString().split('.').last), // Обновлено с type на messageType
          isRead: Value(message.isRead),
        ),
      );
    }
  }
  
  @override
  Future<void> cacheMessage(int chatId, MessageModel message) async {
    await _database.insertMessage(
      MessagesCompanion(
        messageId: Value(message.id),
        chatId: Value(chatId),
        messageText: Value(message.text),
        senderUsername: Value(message.senderUsername),
        senderUserId: Value(message.senderUserId),
        createdAt: Value(message.createdAt),
        editedAt: Value(message.editedAt),
        replyToId: Value(message.replyToId),
        forwardedFromId: Value(message.forwardedFromId),
        attachmentsJson: Value(_encodeAttachments(message.attachments)),
        messageType: Value(message.type.toString().split('.').last),
        isRead: Value(message.isRead),
      ),
    );
  }
  
  @override
  Future<void> cacheMediaFile(String url, String localPath, String contentType) async {
    final attachments = await (_database.messageAttachments.select()
      ..where((a) => a.url.equals(url)))
      .get();
      
    if (attachments.isNotEmpty) {
      for (final attachment in attachments) {
        await _database.updateAttachmentLocalPath(attachment.id, localPath);
      }
    }
  }
  
  @override
  Future<String?> getMediaFilePath(String url) async {
    final attachments = await (_database.messageAttachments.select()
      ..where((a) => a.url.equals(url)))
      .get();
      
    if (attachments.isNotEmpty && attachments.first.localPath != null) {
      final file = File(attachments.first.localPath!);
      if (await file.exists()) {
        return attachments.first.localPath;
      }
    }
    
    return null;
  }
  
  // Вспомогательные методы для конвертации между моделями базы данных и бизнес-моделями
  
  ChatModel _mapChatToModel(Chat chat) {
    return ChatModel(
      chatId: chat.chatId,
      chatName: chat.chatName,
      lastMessageText: chat.lastMessageText,
      lastMessageSenderUsername: chat.lastMessageSenderUsername,
      lastMessageCreatedAt: chat.lastMessageCreatedAt,
      unreadCount: chat.unreadCount,
      pinnedMessageId: chat.pinnedMessageId,
    );
  }
  
  MessageModel _mapMessageToModel(Message message) {
    final attachments = _decodeAttachments(message.attachmentsJson); // Обновлено с attachments на attachmentsJson
    
    return MessageModel(
      id: message.messageId,
      chatId: message.chatId,
      text: message.messageText, // Обновлено с text на messageText
      senderUsername: message.senderUsername,
      senderUserId: message.senderUserId,
      createdAt: message.createdAt,
      editedAt: message.editedAt,
      replyToId: message.replyToId,
      forwardedFromId: message.forwardedFromId,
      attachments: attachments,
      type: _parseMessageType(message.messageType), // Обновлено с type на messageType
      isPinned: message.isPinned,
      isRead: message.isRead,
      isMe: message.isMe,
    );
  }
  
  String _encodeAttachments(List<Map<String, String>> attachments) {
    if (attachments.isEmpty) return '';
    return jsonEncode(attachments);
  }
  
  List<Map<String, String>> _decodeAttachments(String? encodedAttachments) {
    if (encodedAttachments == null || encodedAttachments.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = jsonDecode(encodedAttachments);
      return decoded
          .map((item) => Map<String, String>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }
  
  MessageType _parseMessageType(String type) {
    try {
      return MessageType.values.firstWhere(
        (t) => t.toString().split('.').last == type,
        orElse: () => MessageType.text,
      );
    } catch (_) {
      return MessageType.text;
    }
  }
}
