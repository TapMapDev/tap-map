import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tap_map/src/features/userFlow/chat/data/local/chat_data_source.dart';
import 'package:tap_map/src/features/userFlow/chat/data/local/chat_database.dart';
import 'package:tap_map/src/features/userFlow/chat/models/chat_model.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

/// Константы для работы с кэшем
class ChatCacheConfig {
  /// Время жизни кэша сообщений в минутах
  static const int messageCacheTTLMinutes = 5;
  
  /// Префикс для ключей в SharedPreferences
  static const String cacheKeyPrefix = 'chat_messages_cache_time_';
}

/// Реализация локального источника данных для чатов
class LocalChatDataSource implements ChatDataSource {
  final ChatDatabase _database;
  SharedPreferences? _prefs;

  LocalChatDataSource(this._database) {
    _initSharedPreferences();
  }
  
  /// Инициализация SharedPreferences
  Future<void> _initSharedPreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      print('📂 LocalChatDataSource: SharedPreferences инициализирован');
    } catch (e) {
      print('❌ LocalChatDataSource: Ошибка при инициализации SharedPreferences: $e');
    }
  }

  @override
  Future<List<ChatModel>> getChats() async {
    print(
        '📂 LocalChatDataSource: Получение всех чатов из локальной базы данных');
    final chats = await _database.getAllChats();
    print('📂 LocalChatDataSource: Получено ${chats.length} чатов из локальной базы данных');
    final models = chats.map(_mapChatToModel).toList();
    models.sort((a, b) {
      if (a.isPinned == b.isPinned) {
        return (a.pinOrder ?? 0).compareTo(b.pinOrder ?? 0);
      }
      return a.isPinned ? -1 : 1;
    });
    return models;
  }

  @override
  Stream<List<ChatModel>> watchChats() {
    print('📂 LocalChatDataSource: Настройка наблюдения за списком чатов');
    return _database.watchAllChats().map(
      (chats) {
        print('📂 LocalChatDataSource: Обновление списка чатов, получено ${chats.length} чатов');
        final models = chats.map(_mapChatToModel).toList();
        models.sort((a, b) {
          if (a.isPinned == b.isPinned) {
            return (a.pinOrder ?? 0).compareTo(b.pinOrder ?? 0);
          }
          return a.isPinned ? -1 : 1;
        });
        return models;
      },
    );
  }

  @override
  Future<ChatModel?> getChatById(int chatId) async {
    print(
        '📂 LocalChatDataSource: Поиск чата с ID $chatId в локальной базе данных');
    final chat = await _database.getChatById(chatId);
    if (chat == null) {
      print(
          '📂 LocalChatDataSource: Чат с ID $chatId не найден в локальной базе данных');
      return null;
    }
    print(
        '📂 LocalChatDataSource: Чат с ID $chatId найден в локальной базе данных');
    return _mapChatToModel(chat);
  }

  @override
  Future<List<MessageModel>> getMessagesForChat(int chatId) async {
    print(
        '📂 LocalChatDataSource: Получение сообщений для чата $chatId из локальной базы данных');
    final messages = await _database.getMessagesForChat(chatId);
    print(
        '📂 LocalChatDataSource: Получено ${messages.length} сообщений для чата $chatId из локальной базы данных');
    return messages.map(_messageEntityToModel).toList();
  }

  @override
  Stream<List<MessageModel>> watchMessages(int chatId) {
    print(
        '📂 LocalChatDataSource: Настройка наблюдения за сообщениями чата $chatId');
    return _database.watchMessagesForChat(chatId).map(
      (messages) {
        print(
            '📂 LocalChatDataSource: Обновление сообщений чата $chatId, получено ${messages.length} сообщений');
        return messages.map(_messageEntityToModel).toList();
      },
    );
  }

  @override
  Future<int> createChat({required String type, required int participantId}) {
    // Локальный источник не может создавать чаты
    throw UnimplementedError('Локальный источник не может создавать чаты');
  }

  @override
  Future<void> markChatAsRead(int chatId) async {
    print(
        '📂 LocalChatDataSource: Отметка чата $chatId как прочитанного в локальной базе данных');
    await _database.markMessagesAsRead(chatId);
    print('📂 LocalChatDataSource: Чат $chatId отмечен как прочитанный');
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
    throw UnimplementedError(
        'Локальный источник не может отправлять сообщения');
  }

  @override
  Future<void> deleteMessage(int chatId, int messageId, String action) async {
    print(
        '📂 LocalChatDataSource: Удаление сообщения с ID $messageId из чата $chatId');
    await _database.deleteMessage(messageId);
    print('📂 LocalChatDataSource: Сообщение с ID $messageId удалено');
  }

  @override
  Future<void> editMessage(int chatId, int messageId, String text) async {
    print(
        '📂 LocalChatDataSource: Редактирование сообщения с ID $messageId из чата $chatId');
    final message = await _database.getMessageById(chatId, messageId);
    if (message != null) {
      await _database.insertMessage(
        MessagesCompanion(
          messageId: Value(messageId),
          chatId: Value(chatId),
          messageText: Value(text),
          senderUsername: Value(message.senderUsername),
          senderUserId: Value(message.senderUserId),
          createdAt: Value(message.createdAt),
          editedAt: Value(DateTime.now()),
          replyToId: Value(message.replyToId),
          forwardedFromId: Value(message.forwardedFromId),
          attachmentsJson: Value(message.attachmentsJson),
          messageType: Value(message.messageType),
          isPinned: Value(message.isPinned),
          isRead: Value(message.isRead),
          isMe: Value(message.isMe),
        ),
      );
      print(
          '📂 LocalChatDataSource: Сообщение с ID $messageId отредактировано');
    }
  }

  @override
  Future<void> pinMessage({required int chatId, required int messageId}) async {
    print(
        '📂 LocalChatDataSource: Закрепление сообщения с ID $messageId в чате $chatId');
    // Обновляем флаг в сообщении
    final message = await _database.getMessageById(chatId, messageId);
    if (message != null) {
      await _database.insertMessage(
        MessagesCompanion(
          messageId: Value(messageId),
          chatId: Value(chatId),
          messageText: Value(message.messageText),
          senderUsername: Value(message.senderUsername),
          senderUserId: Value(message.senderUserId),
          createdAt: Value(message.createdAt),
          editedAt: Value(message.editedAt),
          replyToId: Value(message.replyToId),
          forwardedFromId: Value(message.forwardedFromId),
          attachmentsJson: Value(message.attachmentsJson),
          messageType: Value(message.messageType),
          isPinned: const Value(true),
          isRead: Value(message.isRead),
          isMe: Value(message.isMe),
        ),
      );
      print('📂 LocalChatDataSource: Сообщение с ID $messageId закреплено');
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
      print(
          '📂 LocalChatDataSource: ID закрепленного сообщения обновлен в чате $chatId');
    }
  }

  @override
  Future<void> unpinMessage(
      {required int chatId, required int messageId}) async {
    print(
        '📂 LocalChatDataSource: Отмена закрепления сообщения с ID $messageId в чате $chatId');
    // Обновляем флаг в сообщении
    final message = await _database.getMessageById(chatId, messageId);
    if (message != null) {
      await _database.insertMessage(
        MessagesCompanion(
          messageId: Value(messageId),
          chatId: Value(chatId),
          messageText: Value(message.messageText),
          senderUsername: Value(message.senderUsername),
          senderUserId: Value(message.senderUserId),
          createdAt: Value(message.createdAt),
          editedAt: Value(message.editedAt),
          replyToId: Value(message.replyToId),
          forwardedFromId: Value(message.forwardedFromId),
          attachmentsJson: Value(message.attachmentsJson),
          messageType: Value(message.messageType),
          isPinned: const Value(false),
          isRead: Value(message.isRead),
          isMe: Value(message.isMe),
        ),
      );
      print(
          '📂 LocalChatDataSource: Сообщение с ID $messageId отменено закрепление');
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
      print(
          '📂 LocalChatDataSource: ID закрепленного сообщения обновлен в чате $chatId');
    }
  }

  @override
  Future<int?> getPinnedMessageId(int chatId) async {
    print(
        '📂 LocalChatDataSource: Получение ID закрепленного сообщения в чате $chatId');
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
    print(
        '📂 LocalChatDataSource: Получение кэшированных сообщений для чата $chatId');
    final messages = await getMessagesForChat(chatId);
    print(
        '📂 LocalChatDataSource: Возвращено ${messages.length} кэшированных сообщений для чата $chatId');
    return messages;
  }

  @override
  Future<void> cacheMessages(int chatId, List<MessageModel> messages) async {
    print(
        '📂 LocalChatDataSource: Кэширование ${messages.length} сообщений для чата $chatId');
    int successCount = 0;

    for (final message in messages) {
      try {
        await cacheMessage(chatId, message);
        successCount++;
      } catch (e) {
        print(
            '❌ LocalChatDataSource: Ошибка при кэшировании сообщения ${message.id}: $e');
      }
    }

    print(
        '📂 LocalChatDataSource: Успешно кэшировано $successCount из ${messages.length} сообщений для чата $chatId');
  }

  @override
  Future<void> cacheMessage(int chatId, MessageModel message) async {
    print(
        '📂 LocalChatDataSource: Кэширование сообщения ${message.id} для чата $chatId');

    try {
      // Преобразование attachments в JSON строку
      final String? attachmentsJson = message.attachments.isNotEmpty
          ? jsonEncode(message.attachments)
          : null;

      // Преобразование reactions в JSON строку
      final String? reactionsJson = message.reactionsSummary != null
          ? jsonEncode(message.reactionsSummary)
          : null;

      // Вставка сообщения в базу данных
      await _database.insertMessage(
        MessagesCompanion(
          messageId: Value(message.id),
          chatId: Value(chatId),
          messageText: Value(message.text),
          senderUsername: Value(message.senderUsername),
          createdAt: Value(message.createdAt),
          editedAt: Value(message.editedAt),
          replyToId: Value(message.replyToId),
          forwardedFromId: Value(message.forwardedFromId),
          attachmentsJson: Value(attachmentsJson),
          messageType: Value(message.type.toString().split('.').last),
          isPinned: Value(message.isPinned),
          isRead: Value(message.isRead),
          senderUserId: Value(message.senderUserId),
          commentsCount: Value(message.commentsCount),
          reactionsJson: Value(reactionsJson),
          pinOrder: Value(message.pinOrder),
        ),
      );

      // Если сообщение закреплено, обновляем информацию о чате
      if (message.isPinned) {
        await _database.updateChatPinnedMessage(chatId, message.id);
      }

      // Обновляем метку времени кэширования
      await _saveCacheTimestamp(chatId);

      print('✅ LocalChatDataSource: Сообщение ${message.id} успешно кэшировано');
    } catch (e) {
      print('❌ LocalChatDataSource: Ошибка при кэшировании сообщения: $e');
      rethrow;
    }
  }

  @override
  Future<void> cacheChat(ChatModel chat) async {
    print('📂 LocalChatDataSource: Кэширование чата с ID ${chat.chatId}');
    try {
      await _database.insertChat(
        ChatsCompanion(
          chatId: Value(chat.chatId),
          chatName: Value(chat.chatName),
          chatPhoto: Value(chat.chatPhoto),
          lastMessageText: Value(chat.lastMessageText),
          lastMessageSenderUsername: Value(chat.lastMessageSenderUsername),
          lastMessageCreatedAt: Value(chat.lastMessageCreatedAt),
          unreadCount: Value(chat.unreadCount),
          pinnedMessageId: Value(chat.pinnedMessageId),
          isPinned: Value(chat.isPinned),
          pinOrder: Value(chat.pinOrder),
          updatedAt: Value(DateTime.now()),
        ),
      );
      print(
          '📂 LocalChatDataSource: Чат с ID ${chat.chatId} успешно кэширован');
    } catch (e) {
      print(
          '❌ LocalChatDataSource: Ошибка при кэшировании чата ${chat.chatId}: $e');
    }
  }

  @override
  Future<void> cacheChats(List<ChatModel> chats) async {
    print('📂 LocalChatDataSource: Кэширование ${chats.length} чатов');
    int successCount = 0;

    for (final chat in chats) {
      try {
        await cacheChat(chat);
        successCount++;
      } catch (e) {
        print(
            '❌ LocalChatDataSource: Ошибка при кэшировании чата ${chat.chatId}: $e');
      }
    }

    print(
        '📂 LocalChatDataSource: Успешно кэшировано $successCount из ${chats.length} чатов');
  }

  @override
  Future<void> cacheMediaFile(
      String url, String localPath, String contentType) async {
    print(
        '📂 LocalChatDataSource: Кэширование медиафайла с URL $url в $localPath');

    try {
      final attachments = await (_database.messageAttachments.select()
            ..where((a) => a.url.equals(url)))
          .get();

      if (attachments.isNotEmpty) {
        print(
            '📂 LocalChatDataSource: Найдено ${attachments.length} вложений с URL $url');
        for (final attachment in attachments) {
          await _database.updateAttachmentLocalPath(attachment.id, localPath);
        }
        print(
            '📂 LocalChatDataSource: Локальный путь обновлен для всех вложений');
      } else {
        print(
            '📂 LocalChatDataSource: Вложения с URL $url не найдены в базе данных');
      }
    } catch (e) {
      print('❌ LocalChatDataSource: Ошибка при кэшировании медиафайла: $e');
    }
  }

  @override
  Future<String?> getMediaFilePath(String url) async {
    print(
        '📂 LocalChatDataSource: Поиск локального пути для медиафайла с URL $url');

    try {
      final attachments = await (_database.messageAttachments.select()
            ..where((a) => a.url.equals(url)))
          .get();

      if (attachments.isNotEmpty && attachments.first.localPath != null) {
        final filePath = attachments.first.localPath!;
        final file = File(filePath);
        if (await file.exists()) {
          print('📂 LocalChatDataSource: Медиафайл найден локально: $filePath');
          return filePath;
        } else {
          print(
              '📂 LocalChatDataSource: Локальный путь найден, но файл не существует: $filePath');
        }
      } else {
        print('📂 LocalChatDataSource: Локальный путь для URL $url не найден');
      }

      return null;
    } catch (e) {
      print(
          '❌ LocalChatDataSource: Ошибка при поиске локального пути медиафайла: $e');
      return null;
    }
  }

  /// Получить сообщение по его ID из локального кэша
  Future<MessageModel?> getMessageById(int chatId, int messageId) async {
    try {
      print(
          '📂 LocalChatDataSource: Получение сообщения $messageId для чата $chatId из кэша');
      final message = await _database.getMessageById(chatId, messageId);
      if (message == null) {
        print('📂 LocalChatDataSource: Сообщение $messageId не найдено в кэше');
        return null;
      }
      print('📂 LocalChatDataSource: Сообщение $messageId найдено в кэше');
      return _messageEntityToModel(message);
    } catch (e) {
      print('❌ LocalChatDataSource: Ошибка при получении сообщения по ID: $e');
      return null;
    }
  }

  @override
  Future<List<MessageModel>> getPinnedMessages(int chatId) async {
    try {
      print(
          '📂 LocalChatDataSource: Получение закрепленных сообщений для чата $chatId');
      final pinnedMessageId = await getPinnedMessageId(chatId);
      if (pinnedMessageId == null) {
        print(
            '📂 LocalChatDataSource: ID закрепленного сообщения не найден для чата $chatId');
        return [];
      }

      final message = await getMessageById(chatId, pinnedMessageId);
      if (message != null) {
        print(
            '📂 LocalChatDataSource: Найдено закрепленное сообщение для чата $chatId');
        return [message];
      } else {
        print(
            '📂 LocalChatDataSource: Закрепленное сообщение не найдено в локальной базе данных');
        return [];
      }
    } catch (e) {
      print(
          '❌ LocalChatDataSource: Ошибка при получении закрепленных сообщений: $e');
      return [];
    }
  }

  /// Сохранение времени последнего обновления кэша сообщений для чата
  Future<void> _saveCacheTimestamp(int chatId) async {
    if (_prefs == null) await _initSharedPreferences();
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await _prefs?.setInt('${ChatCacheConfig.cacheKeyPrefix}$chatId', timestamp);
    print('📂 LocalChatDataSource: Обновлена метка времени кэша для чата $chatId: $timestamp');
  }
  
  /// Получение времени последнего обновления кэша для чата
  Future<DateTime?> getCacheTimestamp(int chatId) async {
    if (_prefs == null) await _initSharedPreferences();
    
    final timestamp = _prefs?.getInt('${ChatCacheConfig.cacheKeyPrefix}$chatId');
    if (timestamp == null) return null;
    
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
  
  /// Проверка свежести кэша сообщений для чата
  Future<bool> isCacheFresh(int chatId) async {
    final timestamp = await getCacheTimestamp(chatId);
    if (timestamp == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(timestamp).inMinutes;
    
    return difference < ChatCacheConfig.messageCacheTTLMinutes;
  }

  /// Кэширование списка сообщений для чата
  Future<void> cacheMessages(int chatId, List<MessageModel> messages) async {
    print('📂 LocalChatDataSource: Кэширование ${messages.length} сообщений для чата $chatId');
    
    try {
      for (final message in messages) {
        await cacheMessage(chatId, message);
      }
      
      // Обновляем метку времени кэширования
      await _saveCacheTimestamp(chatId);
      
      print('✅ LocalChatDataSource: ${messages.length} сообщений успешно кэшированы');
    } catch (e) {
      print('❌ LocalChatDataSource: Ошибка при кэшировании сообщений: $e');
      rethrow;
    }
  }

  /// Получение кэшированных сообщений для чата с информацией о свежести кэша
  Future<Map<String, dynamic>> getCachedMessagesWithFreshness(int chatId) async {
    final messages = await getMessagesForChat(chatId);
    final isFresh = await isCacheFresh(chatId);
    
    return {
      'messages': messages,
      'isFresh': isFresh,
      'lastUpdated': await getCacheTimestamp(chatId),
    };
  }

  // Вспомогательные методы для конвертации между моделями базы данных и бизнес-моделями

  ChatModel _mapChatToModel(Chat chat) {
    return ChatModel(
      chatId: chat.chatId,
      chatName: chat.chatName,
      chatPhoto: chat.chatPhoto,
      lastMessageText: chat.lastMessageText,
      lastMessageSenderUsername: chat.lastMessageSenderUsername,
      lastMessageCreatedAt: chat.lastMessageCreatedAt,
      unreadCount: chat.unreadCount,
      pinnedMessageId: chat.pinnedMessageId,
      isPinned: chat.isPinned,
      pinOrder: chat.pinOrder,
    );
  }

  MessageModel _messageEntityToModel(Message message) {
    return MessageModel(
      id: message.messageId,
      chatId: message.chatId,
      text: message.messageText,
      senderUsername: message.senderUsername,
      createdAt: message.createdAt,
      editedAt: message.editedAt,
      replyToId: message.replyToId,
      forwardedFromId: message.forwardedFromId,
      attachments: _decodeAttachments(message.attachmentsJson),
      type: _parseMessageType(message.messageType),
      isPinned: message.isPinned,
      isRead: message.isRead,
      senderUserId: message.senderUserId,
      isMe: false,
      commentsCount: message.commentsCount,
      reactionsSummary: _decodeReactions(message.reactionsJson),
      pinOrder: message.pinOrder,
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
      final dynamic decoded = jsonDecode(encodedAttachments);

      if (decoded is List) {
        return decoded
            .map((item) => Map<String, String>.from(item as Map))
            .toList();
      } else if (decoded is Map) {
        return [Map<String, String>.from(decoded)];
      }

      return [];
    } catch (e) {
      print('❌ LocalChatDataSource: Ошибка при декодировании вложений: $e');
      return [];
    }
  }

  Map<String, dynamic>? _decodeReactions(String? reactionsJson) {
    if (reactionsJson == null || reactionsJson.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(reactionsJson) as Map<String, dynamic>;
    } catch (e) {
      print('❌ LocalChatDataSource: Ошибка при декодировании реакций: $e');
      return null;
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
