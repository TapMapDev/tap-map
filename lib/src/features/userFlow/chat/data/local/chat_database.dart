import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'chat_database.g.dart';

// Таблица для хранения информации о чатах
class Chats extends Table {
  // Уникальный идентификатор в локальной БД
  IntColumn get id => integer().autoIncrement()();
  // ID чата с сервера
  IntColumn get chatId => integer().unique()();
  TextColumn get chatName => text()();
  TextColumn get lastMessageText => text().nullable()();
  TextColumn get lastMessageSenderUsername => text().nullable()();
  DateTimeColumn get lastMessageCreatedAt => dateTime().nullable()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  IntColumn get pinnedMessageId => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
}

// Таблица для хранения сообщений
class Messages extends Table {
  // Уникальный идентификатор в локальной БД
  IntColumn get id => integer().autoIncrement()();
  // ID сообщения с сервера
  IntColumn get messageId => integer().unique()();
  IntColumn get chatId => integer()();
  TextColumn get messageText => text()();
  TextColumn get senderUsername => text()();
  IntColumn get senderUserId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get editedAt => dateTime().nullable()();
  IntColumn get replyToId => integer().nullable()();
  IntColumn get forwardedFromId => integer().nullable()();
  TextColumn get attachmentsJson => text().nullable()();
  TextColumn get messageType => text().withDefault(const Constant('text'))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  BoolColumn get isMe => boolean().withDefault(const Constant(false))();
}

// Таблица для кэширования файлов, прикрепленных к сообщениям
class MessageAttachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get messageId => integer()();
  TextColumn get url => text()();
  TextColumn get contentType => text()();
  TextColumn get localPath => text().nullable()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  BoolColumn get isDownloaded => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [Chats, Messages, MessageAttachments])
class ChatDatabase extends _$ChatDatabase {
  // Конструктор для передачи соединения
  ChatDatabase(QueryExecutor e) : super(e);

  // Фабричный метод для создания экземпляра базы данных
  factory ChatDatabase.connect() {
    return ChatDatabase(_openConnection());
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Будем добавлять миграции по мере развития базы данных
      },
    );
  }

  // Методы для работы с чатами
  Future<List<Chat>> getAllChats() => select(chats).get();

  Stream<List<Chat>> watchAllChats() {
    return (select(chats)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  }

  Future<Chat?> getChatById(int chatId) {
    return (select(chats)..where((c) => c.chatId.equals(chatId))).getSingleOrNull();
  }

  Future<int> insertChat(ChatsCompanion chat) {
    return into(chats).insert(
      chat,
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<bool> deleteChat(int chatId) async {
    return transaction(() async {
      // Удаляем сообщения чата
      await (delete(messages)..where((m) => m.chatId.equals(chatId))).go();
      // Удаляем чат
      final count = await (delete(chats)..where((c) => c.chatId.equals(chatId))).go();
      return count > 0;
    });
  }

  // Методы для работы с сообщениями
  Future<List<Message>> getMessagesForChat(int chatId) {
    return (select(messages)
          ..where((m) => m.chatId.equals(chatId))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .get();
  }

  Stream<List<Message>> watchMessagesForChat(int chatId) {
    return (select(messages)
          ..where((m) => m.chatId.equals(chatId))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .watch();
  }

  Future<Message?> getMessageById(int messageId) {
    return (select(messages)..where((m) => m.messageId.equals(messageId))).getSingleOrNull();
  }

  Future<int> insertMessage(MessagesCompanion message) {
    return into(messages).insert(
      message,
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<bool> deleteMessage(int messageId) async {
    final count = await (delete(messages)..where((m) => m.messageId.equals(messageId))).go();
    return count > 0;
  }

  Future<bool> markMessagesAsRead(int chatId) async {
    return transaction(() async {
      // Обновляем сообщения
      await (update(messages)..where((m) => m.chatId.equals(chatId) & m.isRead.equals(false)))
        .write(const MessagesCompanion(isRead: Value(true)));
      
      // Обновляем счетчик непрочитанных сообщений в чате
      await (update(chats)..where((c) => c.chatId.equals(chatId)))
        .write(const ChatsCompanion(unreadCount: Value(0)));
      
      return true;
    });
  }

  // Методы для работы с вложениями
  Future<List<MessageAttachment>> getAttachmentsForMessage(int messageId) {
    return (select(messageAttachments)..where((a) => a.messageId.equals(messageId))).get();
  }

  Future<int> insertAttachment(MessageAttachmentsCompanion attachment) {
    return into(messageAttachments).insert(
      attachment,
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<bool> updateAttachmentLocalPath(int id, String localPath) async {
    return transaction(() async {
      await (update(messageAttachments)..where((a) => a.id.equals(id)))
        .write(MessageAttachmentsCompanion(
          localPath: Value(localPath),
          isDownloaded: const Value(true),
        ));
      return true;
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tapmap_chat.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
