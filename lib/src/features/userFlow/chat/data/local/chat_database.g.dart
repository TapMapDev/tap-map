// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_database.dart';

// ignore_for_file: type=lint
class $ChatsTable extends Chats with TableInfo<$ChatsTable, Chat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<int> chatId = GeneratedColumn<int>(
      'chat_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _chatNameMeta =
      const VerificationMeta('chatName');
  @override
  late final GeneratedColumn<String> chatName = GeneratedColumn<String>(
      'chat_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastMessageTextMeta =
      const VerificationMeta('lastMessageText');
  @override
  late final GeneratedColumn<String> lastMessageText = GeneratedColumn<String>(
      'last_message_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastMessageSenderUsernameMeta =
      const VerificationMeta('lastMessageSenderUsername');
  @override
  late final GeneratedColumn<String> lastMessageSenderUsername =
      GeneratedColumn<String>('last_message_sender_username', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastMessageCreatedAtMeta =
      const VerificationMeta('lastMessageCreatedAt');
  @override
  late final GeneratedColumn<DateTime> lastMessageCreatedAt =
      GeneratedColumn<DateTime>('last_message_created_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _unreadCountMeta =
      const VerificationMeta('unreadCount');
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
      'unread_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _pinnedMessageIdMeta =
      const VerificationMeta('pinnedMessageId');
  @override
  late final GeneratedColumn<int> pinnedMessageId = GeneratedColumn<int>(
      'pinned_message_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        chatId,
        chatName,
        lastMessageText,
        lastMessageSenderUsername,
        lastMessageCreatedAt,
        unreadCount,
        pinnedMessageId,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chats';
  @override
  VerificationContext validateIntegrity(Insertable<Chat> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('chat_id')) {
      context.handle(_chatIdMeta,
          chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta));
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('chat_name')) {
      context.handle(_chatNameMeta,
          chatName.isAcceptableOrUnknown(data['chat_name']!, _chatNameMeta));
    } else if (isInserting) {
      context.missing(_chatNameMeta);
    }
    if (data.containsKey('last_message_text')) {
      context.handle(
          _lastMessageTextMeta,
          lastMessageText.isAcceptableOrUnknown(
              data['last_message_text']!, _lastMessageTextMeta));
    }
    if (data.containsKey('last_message_sender_username')) {
      context.handle(
          _lastMessageSenderUsernameMeta,
          lastMessageSenderUsername.isAcceptableOrUnknown(
              data['last_message_sender_username']!,
              _lastMessageSenderUsernameMeta));
    }
    if (data.containsKey('last_message_created_at')) {
      context.handle(
          _lastMessageCreatedAtMeta,
          lastMessageCreatedAt.isAcceptableOrUnknown(
              data['last_message_created_at']!, _lastMessageCreatedAtMeta));
    }
    if (data.containsKey('unread_count')) {
      context.handle(
          _unreadCountMeta,
          unreadCount.isAcceptableOrUnknown(
              data['unread_count']!, _unreadCountMeta));
    }
    if (data.containsKey('pinned_message_id')) {
      context.handle(
          _pinnedMessageIdMeta,
          pinnedMessageId.isAcceptableOrUnknown(
              data['pinned_message_id']!, _pinnedMessageIdMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Chat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chat(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      chatId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chat_id'])!,
      chatName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_name'])!,
      lastMessageText: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_message_text']),
      lastMessageSenderUsername: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}last_message_sender_username']),
      lastMessageCreatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_message_created_at']),
      unreadCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unread_count'])!,
      pinnedMessageId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pinned_message_id']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ChatsTable createAlias(String alias) {
    return $ChatsTable(attachedDatabase, alias);
  }
}

class Chat extends DataClass implements Insertable<Chat> {
  final int id;
  final int chatId;
  final String chatName;
  final String? lastMessageText;
  final String? lastMessageSenderUsername;
  final DateTime? lastMessageCreatedAt;
  final int unreadCount;
  final int? pinnedMessageId;
  final DateTime updatedAt;
  const Chat(
      {required this.id,
      required this.chatId,
      required this.chatName,
      this.lastMessageText,
      this.lastMessageSenderUsername,
      this.lastMessageCreatedAt,
      required this.unreadCount,
      this.pinnedMessageId,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['chat_id'] = Variable<int>(chatId);
    map['chat_name'] = Variable<String>(chatName);
    if (!nullToAbsent || lastMessageText != null) {
      map['last_message_text'] = Variable<String>(lastMessageText);
    }
    if (!nullToAbsent || lastMessageSenderUsername != null) {
      map['last_message_sender_username'] =
          Variable<String>(lastMessageSenderUsername);
    }
    if (!nullToAbsent || lastMessageCreatedAt != null) {
      map['last_message_created_at'] = Variable<DateTime>(lastMessageCreatedAt);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    if (!nullToAbsent || pinnedMessageId != null) {
      map['pinned_message_id'] = Variable<int>(pinnedMessageId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChatsCompanion toCompanion(bool nullToAbsent) {
    return ChatsCompanion(
      id: Value(id),
      chatId: Value(chatId),
      chatName: Value(chatName),
      lastMessageText: lastMessageText == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageText),
      lastMessageSenderUsername:
          lastMessageSenderUsername == null && nullToAbsent
              ? const Value.absent()
              : Value(lastMessageSenderUsername),
      lastMessageCreatedAt: lastMessageCreatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageCreatedAt),
      unreadCount: Value(unreadCount),
      pinnedMessageId: pinnedMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(pinnedMessageId),
      updatedAt: Value(updatedAt),
    );
  }

  factory Chat.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chat(
      id: serializer.fromJson<int>(json['id']),
      chatId: serializer.fromJson<int>(json['chatId']),
      chatName: serializer.fromJson<String>(json['chatName']),
      lastMessageText: serializer.fromJson<String?>(json['lastMessageText']),
      lastMessageSenderUsername:
          serializer.fromJson<String?>(json['lastMessageSenderUsername']),
      lastMessageCreatedAt:
          serializer.fromJson<DateTime?>(json['lastMessageCreatedAt']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      pinnedMessageId: serializer.fromJson<int?>(json['pinnedMessageId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'chatId': serializer.toJson<int>(chatId),
      'chatName': serializer.toJson<String>(chatName),
      'lastMessageText': serializer.toJson<String?>(lastMessageText),
      'lastMessageSenderUsername':
          serializer.toJson<String?>(lastMessageSenderUsername),
      'lastMessageCreatedAt':
          serializer.toJson<DateTime?>(lastMessageCreatedAt),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'pinnedMessageId': serializer.toJson<int?>(pinnedMessageId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Chat copyWith(
          {int? id,
          int? chatId,
          String? chatName,
          Value<String?> lastMessageText = const Value.absent(),
          Value<String?> lastMessageSenderUsername = const Value.absent(),
          Value<DateTime?> lastMessageCreatedAt = const Value.absent(),
          int? unreadCount,
          Value<int?> pinnedMessageId = const Value.absent(),
          DateTime? updatedAt}) =>
      Chat(
        id: id ?? this.id,
        chatId: chatId ?? this.chatId,
        chatName: chatName ?? this.chatName,
        lastMessageText: lastMessageText.present
            ? lastMessageText.value
            : this.lastMessageText,
        lastMessageSenderUsername: lastMessageSenderUsername.present
            ? lastMessageSenderUsername.value
            : this.lastMessageSenderUsername,
        lastMessageCreatedAt: lastMessageCreatedAt.present
            ? lastMessageCreatedAt.value
            : this.lastMessageCreatedAt,
        unreadCount: unreadCount ?? this.unreadCount,
        pinnedMessageId: pinnedMessageId.present
            ? pinnedMessageId.value
            : this.pinnedMessageId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Chat copyWithCompanion(ChatsCompanion data) {
    return Chat(
      id: data.id.present ? data.id.value : this.id,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      chatName: data.chatName.present ? data.chatName.value : this.chatName,
      lastMessageText: data.lastMessageText.present
          ? data.lastMessageText.value
          : this.lastMessageText,
      lastMessageSenderUsername: data.lastMessageSenderUsername.present
          ? data.lastMessageSenderUsername.value
          : this.lastMessageSenderUsername,
      lastMessageCreatedAt: data.lastMessageCreatedAt.present
          ? data.lastMessageCreatedAt.value
          : this.lastMessageCreatedAt,
      unreadCount:
          data.unreadCount.present ? data.unreadCount.value : this.unreadCount,
      pinnedMessageId: data.pinnedMessageId.present
          ? data.pinnedMessageId.value
          : this.pinnedMessageId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Chat(')
          ..write('id: $id, ')
          ..write('chatId: $chatId, ')
          ..write('chatName: $chatName, ')
          ..write('lastMessageText: $lastMessageText, ')
          ..write('lastMessageSenderUsername: $lastMessageSenderUsername, ')
          ..write('lastMessageCreatedAt: $lastMessageCreatedAt, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('pinnedMessageId: $pinnedMessageId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      chatId,
      chatName,
      lastMessageText,
      lastMessageSenderUsername,
      lastMessageCreatedAt,
      unreadCount,
      pinnedMessageId,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chat &&
          other.id == this.id &&
          other.chatId == this.chatId &&
          other.chatName == this.chatName &&
          other.lastMessageText == this.lastMessageText &&
          other.lastMessageSenderUsername == this.lastMessageSenderUsername &&
          other.lastMessageCreatedAt == this.lastMessageCreatedAt &&
          other.unreadCount == this.unreadCount &&
          other.pinnedMessageId == this.pinnedMessageId &&
          other.updatedAt == this.updatedAt);
}

class ChatsCompanion extends UpdateCompanion<Chat> {
  final Value<int> id;
  final Value<int> chatId;
  final Value<String> chatName;
  final Value<String?> lastMessageText;
  final Value<String?> lastMessageSenderUsername;
  final Value<DateTime?> lastMessageCreatedAt;
  final Value<int> unreadCount;
  final Value<int?> pinnedMessageId;
  final Value<DateTime> updatedAt;
  const ChatsCompanion({
    this.id = const Value.absent(),
    this.chatId = const Value.absent(),
    this.chatName = const Value.absent(),
    this.lastMessageText = const Value.absent(),
    this.lastMessageSenderUsername = const Value.absent(),
    this.lastMessageCreatedAt = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.pinnedMessageId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ChatsCompanion.insert({
    this.id = const Value.absent(),
    required int chatId,
    required String chatName,
    this.lastMessageText = const Value.absent(),
    this.lastMessageSenderUsername = const Value.absent(),
    this.lastMessageCreatedAt = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.pinnedMessageId = const Value.absent(),
    required DateTime updatedAt,
  })  : chatId = Value(chatId),
        chatName = Value(chatName),
        updatedAt = Value(updatedAt);
  static Insertable<Chat> custom({
    Expression<int>? id,
    Expression<int>? chatId,
    Expression<String>? chatName,
    Expression<String>? lastMessageText,
    Expression<String>? lastMessageSenderUsername,
    Expression<DateTime>? lastMessageCreatedAt,
    Expression<int>? unreadCount,
    Expression<int>? pinnedMessageId,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chatId != null) 'chat_id': chatId,
      if (chatName != null) 'chat_name': chatName,
      if (lastMessageText != null) 'last_message_text': lastMessageText,
      if (lastMessageSenderUsername != null)
        'last_message_sender_username': lastMessageSenderUsername,
      if (lastMessageCreatedAt != null)
        'last_message_created_at': lastMessageCreatedAt,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (pinnedMessageId != null) 'pinned_message_id': pinnedMessageId,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ChatsCompanion copyWith(
      {Value<int>? id,
      Value<int>? chatId,
      Value<String>? chatName,
      Value<String?>? lastMessageText,
      Value<String?>? lastMessageSenderUsername,
      Value<DateTime?>? lastMessageCreatedAt,
      Value<int>? unreadCount,
      Value<int?>? pinnedMessageId,
      Value<DateTime>? updatedAt}) {
    return ChatsCompanion(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      chatName: chatName ?? this.chatName,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageSenderUsername:
          lastMessageSenderUsername ?? this.lastMessageSenderUsername,
      lastMessageCreatedAt: lastMessageCreatedAt ?? this.lastMessageCreatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      pinnedMessageId: pinnedMessageId ?? this.pinnedMessageId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<int>(chatId.value);
    }
    if (chatName.present) {
      map['chat_name'] = Variable<String>(chatName.value);
    }
    if (lastMessageText.present) {
      map['last_message_text'] = Variable<String>(lastMessageText.value);
    }
    if (lastMessageSenderUsername.present) {
      map['last_message_sender_username'] =
          Variable<String>(lastMessageSenderUsername.value);
    }
    if (lastMessageCreatedAt.present) {
      map['last_message_created_at'] =
          Variable<DateTime>(lastMessageCreatedAt.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (pinnedMessageId.present) {
      map['pinned_message_id'] = Variable<int>(pinnedMessageId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatsCompanion(')
          ..write('id: $id, ')
          ..write('chatId: $chatId, ')
          ..write('chatName: $chatName, ')
          ..write('lastMessageText: $lastMessageText, ')
          ..write('lastMessageSenderUsername: $lastMessageSenderUsername, ')
          ..write('lastMessageCreatedAt: $lastMessageCreatedAt, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('pinnedMessageId: $pinnedMessageId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<int> messageId = GeneratedColumn<int>(
      'message_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<int> chatId = GeneratedColumn<int>(
      'chat_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _messageTextMeta =
      const VerificationMeta('messageText');
  @override
  late final GeneratedColumn<String> messageText = GeneratedColumn<String>(
      'message_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderUsernameMeta =
      const VerificationMeta('senderUsername');
  @override
  late final GeneratedColumn<String> senderUsername = GeneratedColumn<String>(
      'sender_username', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderUserIdMeta =
      const VerificationMeta('senderUserId');
  @override
  late final GeneratedColumn<int> senderUserId = GeneratedColumn<int>(
      'sender_user_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _editedAtMeta =
      const VerificationMeta('editedAt');
  @override
  late final GeneratedColumn<DateTime> editedAt = GeneratedColumn<DateTime>(
      'edited_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _replyToIdMeta =
      const VerificationMeta('replyToId');
  @override
  late final GeneratedColumn<int> replyToId = GeneratedColumn<int>(
      'reply_to_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _forwardedFromIdMeta =
      const VerificationMeta('forwardedFromId');
  @override
  late final GeneratedColumn<int> forwardedFromId = GeneratedColumn<int>(
      'forwarded_from_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _attachmentsJsonMeta =
      const VerificationMeta('attachmentsJson');
  @override
  late final GeneratedColumn<String> attachmentsJson = GeneratedColumn<String>(
      'attachments_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _messageTypeMeta =
      const VerificationMeta('messageType');
  @override
  late final GeneratedColumn<String> messageType = GeneratedColumn<String>(
      'message_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('text'));
  static const VerificationMeta _isPinnedMeta =
      const VerificationMeta('isPinned');
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
      'is_pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isMeMeta = const VerificationMeta('isMe');
  @override
  late final GeneratedColumn<bool> isMe = GeneratedColumn<bool>(
      'is_me', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_me" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _commentsCountMeta =
      const VerificationMeta('commentsCount');
  @override
  late final GeneratedColumn<int> commentsCount = GeneratedColumn<int>(
      'comments_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _reactionsJsonMeta =
      const VerificationMeta('reactionsJson');
  @override
  late final GeneratedColumn<String> reactionsJson = GeneratedColumn<String>(
      'reactions_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pinOrderMeta =
      const VerificationMeta('pinOrder');
  @override
  late final GeneratedColumn<int> pinOrder = GeneratedColumn<int>(
      'pin_order', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        messageId,
        chatId,
        messageText,
        senderUsername,
        senderUserId,
        createdAt,
        editedAt,
        replyToId,
        forwardedFromId,
        attachmentsJson,
        messageType,
        isPinned,
        isRead,
        isMe,
        commentsCount,
        reactionsJson,
        pinOrder
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(Insertable<Message> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('chat_id')) {
      context.handle(_chatIdMeta,
          chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta));
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('message_text')) {
      context.handle(
          _messageTextMeta,
          messageText.isAcceptableOrUnknown(
              data['message_text']!, _messageTextMeta));
    } else if (isInserting) {
      context.missing(_messageTextMeta);
    }
    if (data.containsKey('sender_username')) {
      context.handle(
          _senderUsernameMeta,
          senderUsername.isAcceptableOrUnknown(
              data['sender_username']!, _senderUsernameMeta));
    } else if (isInserting) {
      context.missing(_senderUsernameMeta);
    }
    if (data.containsKey('sender_user_id')) {
      context.handle(
          _senderUserIdMeta,
          senderUserId.isAcceptableOrUnknown(
              data['sender_user_id']!, _senderUserIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(_editedAtMeta,
          editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta));
    }
    if (data.containsKey('reply_to_id')) {
      context.handle(
          _replyToIdMeta,
          replyToId.isAcceptableOrUnknown(
              data['reply_to_id']!, _replyToIdMeta));
    }
    if (data.containsKey('forwarded_from_id')) {
      context.handle(
          _forwardedFromIdMeta,
          forwardedFromId.isAcceptableOrUnknown(
              data['forwarded_from_id']!, _forwardedFromIdMeta));
    }
    if (data.containsKey('attachments_json')) {
      context.handle(
          _attachmentsJsonMeta,
          attachmentsJson.isAcceptableOrUnknown(
              data['attachments_json']!, _attachmentsJsonMeta));
    }
    if (data.containsKey('message_type')) {
      context.handle(
          _messageTypeMeta,
          messageType.isAcceptableOrUnknown(
              data['message_type']!, _messageTypeMeta));
    }
    if (data.containsKey('is_pinned')) {
      context.handle(_isPinnedMeta,
          isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta));
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('is_me')) {
      context.handle(
          _isMeMeta, isMe.isAcceptableOrUnknown(data['is_me']!, _isMeMeta));
    }
    if (data.containsKey('comments_count')) {
      context.handle(
          _commentsCountMeta,
          commentsCount.isAcceptableOrUnknown(
              data['comments_count']!, _commentsCountMeta));
    }
    if (data.containsKey('reactions_json')) {
      context.handle(
          _reactionsJsonMeta,
          reactionsJson.isAcceptableOrUnknown(
              data['reactions_json']!, _reactionsJsonMeta));
    }
    if (data.containsKey('pin_order')) {
      context.handle(_pinOrderMeta,
          pinOrder.isAcceptableOrUnknown(data['pin_order']!, _pinOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}message_id'])!,
      chatId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chat_id'])!,
      messageText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_text'])!,
      senderUsername: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sender_username'])!,
      senderUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sender_user_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      editedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}edited_at']),
      replyToId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reply_to_id']),
      forwardedFromId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}forwarded_from_id']),
      attachmentsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}attachments_json']),
      messageType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_type'])!,
      isPinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      isMe: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_me'])!,
      commentsCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}comments_count']),
      reactionsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reactions_json']),
      pinOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pin_order']),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final int id;
  final int messageId;
  final int chatId;
  final String messageText;
  final String senderUsername;
  final int? senderUserId;
  final DateTime createdAt;
  final DateTime? editedAt;
  final int? replyToId;
  final int? forwardedFromId;
  final String? attachmentsJson;
  final String messageType;
  final bool isPinned;
  final bool isRead;
  final bool isMe;
  final int? commentsCount;
  final String? reactionsJson;
  final int? pinOrder;
  const Message(
      {required this.id,
      required this.messageId,
      required this.chatId,
      required this.messageText,
      required this.senderUsername,
      this.senderUserId,
      required this.createdAt,
      this.editedAt,
      this.replyToId,
      this.forwardedFromId,
      this.attachmentsJson,
      required this.messageType,
      required this.isPinned,
      required this.isRead,
      required this.isMe,
      this.commentsCount,
      this.reactionsJson,
      this.pinOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['message_id'] = Variable<int>(messageId);
    map['chat_id'] = Variable<int>(chatId);
    map['message_text'] = Variable<String>(messageText);
    map['sender_username'] = Variable<String>(senderUsername);
    if (!nullToAbsent || senderUserId != null) {
      map['sender_user_id'] = Variable<int>(senderUserId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<DateTime>(editedAt);
    }
    if (!nullToAbsent || replyToId != null) {
      map['reply_to_id'] = Variable<int>(replyToId);
    }
    if (!nullToAbsent || forwardedFromId != null) {
      map['forwarded_from_id'] = Variable<int>(forwardedFromId);
    }
    if (!nullToAbsent || attachmentsJson != null) {
      map['attachments_json'] = Variable<String>(attachmentsJson);
    }
    map['message_type'] = Variable<String>(messageType);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['is_read'] = Variable<bool>(isRead);
    map['is_me'] = Variable<bool>(isMe);
    if (!nullToAbsent || commentsCount != null) {
      map['comments_count'] = Variable<int>(commentsCount);
    }
    if (!nullToAbsent || reactionsJson != null) {
      map['reactions_json'] = Variable<String>(reactionsJson);
    }
    if (!nullToAbsent || pinOrder != null) {
      map['pin_order'] = Variable<int>(pinOrder);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      messageId: Value(messageId),
      chatId: Value(chatId),
      messageText: Value(messageText),
      senderUsername: Value(senderUsername),
      senderUserId: senderUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(senderUserId),
      createdAt: Value(createdAt),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
      replyToId: replyToId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyToId),
      forwardedFromId: forwardedFromId == null && nullToAbsent
          ? const Value.absent()
          : Value(forwardedFromId),
      attachmentsJson: attachmentsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentsJson),
      messageType: Value(messageType),
      isPinned: Value(isPinned),
      isRead: Value(isRead),
      isMe: Value(isMe),
      commentsCount: commentsCount == null && nullToAbsent
          ? const Value.absent()
          : Value(commentsCount),
      reactionsJson: reactionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(reactionsJson),
      pinOrder: pinOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(pinOrder),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<int>(json['id']),
      messageId: serializer.fromJson<int>(json['messageId']),
      chatId: serializer.fromJson<int>(json['chatId']),
      messageText: serializer.fromJson<String>(json['messageText']),
      senderUsername: serializer.fromJson<String>(json['senderUsername']),
      senderUserId: serializer.fromJson<int?>(json['senderUserId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      editedAt: serializer.fromJson<DateTime?>(json['editedAt']),
      replyToId: serializer.fromJson<int?>(json['replyToId']),
      forwardedFromId: serializer.fromJson<int?>(json['forwardedFromId']),
      attachmentsJson: serializer.fromJson<String?>(json['attachmentsJson']),
      messageType: serializer.fromJson<String>(json['messageType']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      isMe: serializer.fromJson<bool>(json['isMe']),
      commentsCount: serializer.fromJson<int?>(json['commentsCount']),
      reactionsJson: serializer.fromJson<String?>(json['reactionsJson']),
      pinOrder: serializer.fromJson<int?>(json['pinOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'messageId': serializer.toJson<int>(messageId),
      'chatId': serializer.toJson<int>(chatId),
      'messageText': serializer.toJson<String>(messageText),
      'senderUsername': serializer.toJson<String>(senderUsername),
      'senderUserId': serializer.toJson<int?>(senderUserId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'editedAt': serializer.toJson<DateTime?>(editedAt),
      'replyToId': serializer.toJson<int?>(replyToId),
      'forwardedFromId': serializer.toJson<int?>(forwardedFromId),
      'attachmentsJson': serializer.toJson<String?>(attachmentsJson),
      'messageType': serializer.toJson<String>(messageType),
      'isPinned': serializer.toJson<bool>(isPinned),
      'isRead': serializer.toJson<bool>(isRead),
      'isMe': serializer.toJson<bool>(isMe),
      'commentsCount': serializer.toJson<int?>(commentsCount),
      'reactionsJson': serializer.toJson<String?>(reactionsJson),
      'pinOrder': serializer.toJson<int?>(pinOrder),
    };
  }

  Message copyWith(
          {int? id,
          int? messageId,
          int? chatId,
          String? messageText,
          String? senderUsername,
          Value<int?> senderUserId = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> editedAt = const Value.absent(),
          Value<int?> replyToId = const Value.absent(),
          Value<int?> forwardedFromId = const Value.absent(),
          Value<String?> attachmentsJson = const Value.absent(),
          String? messageType,
          bool? isPinned,
          bool? isRead,
          bool? isMe,
          Value<int?> commentsCount = const Value.absent(),
          Value<String?> reactionsJson = const Value.absent(),
          Value<int?> pinOrder = const Value.absent()}) =>
      Message(
        id: id ?? this.id,
        messageId: messageId ?? this.messageId,
        chatId: chatId ?? this.chatId,
        messageText: messageText ?? this.messageText,
        senderUsername: senderUsername ?? this.senderUsername,
        senderUserId:
            senderUserId.present ? senderUserId.value : this.senderUserId,
        createdAt: createdAt ?? this.createdAt,
        editedAt: editedAt.present ? editedAt.value : this.editedAt,
        replyToId: replyToId.present ? replyToId.value : this.replyToId,
        forwardedFromId: forwardedFromId.present
            ? forwardedFromId.value
            : this.forwardedFromId,
        attachmentsJson: attachmentsJson.present
            ? attachmentsJson.value
            : this.attachmentsJson,
        messageType: messageType ?? this.messageType,
        isPinned: isPinned ?? this.isPinned,
        isRead: isRead ?? this.isRead,
        isMe: isMe ?? this.isMe,
        commentsCount:
            commentsCount.present ? commentsCount.value : this.commentsCount,
        reactionsJson:
            reactionsJson.present ? reactionsJson.value : this.reactionsJson,
        pinOrder: pinOrder.present ? pinOrder.value : this.pinOrder,
      );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      messageText:
          data.messageText.present ? data.messageText.value : this.messageText,
      senderUsername: data.senderUsername.present
          ? data.senderUsername.value
          : this.senderUsername,
      senderUserId: data.senderUserId.present
          ? data.senderUserId.value
          : this.senderUserId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      replyToId: data.replyToId.present ? data.replyToId.value : this.replyToId,
      forwardedFromId: data.forwardedFromId.present
          ? data.forwardedFromId.value
          : this.forwardedFromId,
      attachmentsJson: data.attachmentsJson.present
          ? data.attachmentsJson.value
          : this.attachmentsJson,
      messageType:
          data.messageType.present ? data.messageType.value : this.messageType,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      isMe: data.isMe.present ? data.isMe.value : this.isMe,
      commentsCount: data.commentsCount.present
          ? data.commentsCount.value
          : this.commentsCount,
      reactionsJson: data.reactionsJson.present
          ? data.reactionsJson.value
          : this.reactionsJson,
      pinOrder: data.pinOrder.present ? data.pinOrder.value : this.pinOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('chatId: $chatId, ')
          ..write('messageText: $messageText, ')
          ..write('senderUsername: $senderUsername, ')
          ..write('senderUserId: $senderUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('replyToId: $replyToId, ')
          ..write('forwardedFromId: $forwardedFromId, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('messageType: $messageType, ')
          ..write('isPinned: $isPinned, ')
          ..write('isRead: $isRead, ')
          ..write('isMe: $isMe, ')
          ..write('commentsCount: $commentsCount, ')
          ..write('reactionsJson: $reactionsJson, ')
          ..write('pinOrder: $pinOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      messageId,
      chatId,
      messageText,
      senderUsername,
      senderUserId,
      createdAt,
      editedAt,
      replyToId,
      forwardedFromId,
      attachmentsJson,
      messageType,
      isPinned,
      isRead,
      isMe,
      commentsCount,
      reactionsJson,
      pinOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.chatId == this.chatId &&
          other.messageText == this.messageText &&
          other.senderUsername == this.senderUsername &&
          other.senderUserId == this.senderUserId &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt &&
          other.replyToId == this.replyToId &&
          other.forwardedFromId == this.forwardedFromId &&
          other.attachmentsJson == this.attachmentsJson &&
          other.messageType == this.messageType &&
          other.isPinned == this.isPinned &&
          other.isRead == this.isRead &&
          other.isMe == this.isMe &&
          other.commentsCount == this.commentsCount &&
          other.reactionsJson == this.reactionsJson &&
          other.pinOrder == this.pinOrder);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<int> id;
  final Value<int> messageId;
  final Value<int> chatId;
  final Value<String> messageText;
  final Value<String> senderUsername;
  final Value<int?> senderUserId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> editedAt;
  final Value<int?> replyToId;
  final Value<int?> forwardedFromId;
  final Value<String?> attachmentsJson;
  final Value<String> messageType;
  final Value<bool> isPinned;
  final Value<bool> isRead;
  final Value<bool> isMe;
  final Value<int?> commentsCount;
  final Value<String?> reactionsJson;
  final Value<int?> pinOrder;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.chatId = const Value.absent(),
    this.messageText = const Value.absent(),
    this.senderUsername = const Value.absent(),
    this.senderUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.replyToId = const Value.absent(),
    this.forwardedFromId = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.messageType = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isMe = const Value.absent(),
    this.commentsCount = const Value.absent(),
    this.reactionsJson = const Value.absent(),
    this.pinOrder = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    required int messageId,
    required int chatId,
    required String messageText,
    required String senderUsername,
    this.senderUserId = const Value.absent(),
    required DateTime createdAt,
    this.editedAt = const Value.absent(),
    this.replyToId = const Value.absent(),
    this.forwardedFromId = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.messageType = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isMe = const Value.absent(),
    this.commentsCount = const Value.absent(),
    this.reactionsJson = const Value.absent(),
    this.pinOrder = const Value.absent(),
  })  : messageId = Value(messageId),
        chatId = Value(chatId),
        messageText = Value(messageText),
        senderUsername = Value(senderUsername),
        createdAt = Value(createdAt);
  static Insertable<Message> custom({
    Expression<int>? id,
    Expression<int>? messageId,
    Expression<int>? chatId,
    Expression<String>? messageText,
    Expression<String>? senderUsername,
    Expression<int>? senderUserId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? editedAt,
    Expression<int>? replyToId,
    Expression<int>? forwardedFromId,
    Expression<String>? attachmentsJson,
    Expression<String>? messageType,
    Expression<bool>? isPinned,
    Expression<bool>? isRead,
    Expression<bool>? isMe,
    Expression<int>? commentsCount,
    Expression<String>? reactionsJson,
    Expression<int>? pinOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (chatId != null) 'chat_id': chatId,
      if (messageText != null) 'message_text': messageText,
      if (senderUsername != null) 'sender_username': senderUsername,
      if (senderUserId != null) 'sender_user_id': senderUserId,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (forwardedFromId != null) 'forwarded_from_id': forwardedFromId,
      if (attachmentsJson != null) 'attachments_json': attachmentsJson,
      if (messageType != null) 'message_type': messageType,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isRead != null) 'is_read': isRead,
      if (isMe != null) 'is_me': isMe,
      if (commentsCount != null) 'comments_count': commentsCount,
      if (reactionsJson != null) 'reactions_json': reactionsJson,
      if (pinOrder != null) 'pin_order': pinOrder,
    });
  }

  MessagesCompanion copyWith(
      {Value<int>? id,
      Value<int>? messageId,
      Value<int>? chatId,
      Value<String>? messageText,
      Value<String>? senderUsername,
      Value<int?>? senderUserId,
      Value<DateTime>? createdAt,
      Value<DateTime?>? editedAt,
      Value<int?>? replyToId,
      Value<int?>? forwardedFromId,
      Value<String?>? attachmentsJson,
      Value<String>? messageType,
      Value<bool>? isPinned,
      Value<bool>? isRead,
      Value<bool>? isMe,
      Value<int?>? commentsCount,
      Value<String?>? reactionsJson,
      Value<int?>? pinOrder}) {
    return MessagesCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      messageText: messageText ?? this.messageText,
      senderUsername: senderUsername ?? this.senderUsername,
      senderUserId: senderUserId ?? this.senderUserId,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      replyToId: replyToId ?? this.replyToId,
      forwardedFromId: forwardedFromId ?? this.forwardedFromId,
      attachmentsJson: attachmentsJson ?? this.attachmentsJson,
      messageType: messageType ?? this.messageType,
      isPinned: isPinned ?? this.isPinned,
      isRead: isRead ?? this.isRead,
      isMe: isMe ?? this.isMe,
      commentsCount: commentsCount ?? this.commentsCount,
      reactionsJson: reactionsJson ?? this.reactionsJson,
      pinOrder: pinOrder ?? this.pinOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<int>(messageId.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<int>(chatId.value);
    }
    if (messageText.present) {
      map['message_text'] = Variable<String>(messageText.value);
    }
    if (senderUsername.present) {
      map['sender_username'] = Variable<String>(senderUsername.value);
    }
    if (senderUserId.present) {
      map['sender_user_id'] = Variable<int>(senderUserId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<DateTime>(editedAt.value);
    }
    if (replyToId.present) {
      map['reply_to_id'] = Variable<int>(replyToId.value);
    }
    if (forwardedFromId.present) {
      map['forwarded_from_id'] = Variable<int>(forwardedFromId.value);
    }
    if (attachmentsJson.present) {
      map['attachments_json'] = Variable<String>(attachmentsJson.value);
    }
    if (messageType.present) {
      map['message_type'] = Variable<String>(messageType.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (isMe.present) {
      map['is_me'] = Variable<bool>(isMe.value);
    }
    if (commentsCount.present) {
      map['comments_count'] = Variable<int>(commentsCount.value);
    }
    if (reactionsJson.present) {
      map['reactions_json'] = Variable<String>(reactionsJson.value);
    }
    if (pinOrder.present) {
      map['pin_order'] = Variable<int>(pinOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('chatId: $chatId, ')
          ..write('messageText: $messageText, ')
          ..write('senderUsername: $senderUsername, ')
          ..write('senderUserId: $senderUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('replyToId: $replyToId, ')
          ..write('forwardedFromId: $forwardedFromId, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('messageType: $messageType, ')
          ..write('isPinned: $isPinned, ')
          ..write('isRead: $isRead, ')
          ..write('isMe: $isMe, ')
          ..write('commentsCount: $commentsCount, ')
          ..write('reactionsJson: $reactionsJson, ')
          ..write('pinOrder: $pinOrder')
          ..write(')'))
        .toString();
  }
}

class $MessageAttachmentsTable extends MessageAttachments
    with TableInfo<$MessageAttachmentsTable, MessageAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<int> messageId = GeneratedColumn<int>(
      'message_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentTypeMeta =
      const VerificationMeta('contentType');
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
      'content_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileSizeMeta =
      const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isDownloadedMeta =
      const VerificationMeta('isDownloaded');
  @override
  late final GeneratedColumn<bool> isDownloaded = GeneratedColumn<bool>(
      'is_downloaded', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_downloaded" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        messageId,
        url,
        contentType,
        localPath,
        fileSize,
        isDownloaded,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_attachments';
  @override
  VerificationContext validateIntegrity(Insertable<MessageAttachment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
          _contentTypeMeta,
          contentType.isAcceptableOrUnknown(
              data['content_type']!, _contentTypeMeta));
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta,
          fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    }
    if (data.containsKey('is_downloaded')) {
      context.handle(
          _isDownloadedMeta,
          isDownloaded.isAcceptableOrUnknown(
              data['is_downloaded']!, _isDownloadedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageAttachment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}message_id'])!,
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url'])!,
      contentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_type'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      fileSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size'])!,
      isDownloaded: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_downloaded'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MessageAttachmentsTable createAlias(String alias) {
    return $MessageAttachmentsTable(attachedDatabase, alias);
  }
}

class MessageAttachment extends DataClass
    implements Insertable<MessageAttachment> {
  final int id;
  final int messageId;
  final String url;
  final String contentType;
  final String? localPath;
  final int fileSize;
  final bool isDownloaded;
  final DateTime createdAt;
  const MessageAttachment(
      {required this.id,
      required this.messageId,
      required this.url,
      required this.contentType,
      this.localPath,
      required this.fileSize,
      required this.isDownloaded,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['message_id'] = Variable<int>(messageId);
    map['url'] = Variable<String>(url);
    map['content_type'] = Variable<String>(contentType);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    map['file_size'] = Variable<int>(fileSize);
    map['is_downloaded'] = Variable<bool>(isDownloaded);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MessageAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return MessageAttachmentsCompanion(
      id: Value(id),
      messageId: Value(messageId),
      url: Value(url),
      contentType: Value(contentType),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      fileSize: Value(fileSize),
      isDownloaded: Value(isDownloaded),
      createdAt: Value(createdAt),
    );
  }

  factory MessageAttachment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageAttachment(
      id: serializer.fromJson<int>(json['id']),
      messageId: serializer.fromJson<int>(json['messageId']),
      url: serializer.fromJson<String>(json['url']),
      contentType: serializer.fromJson<String>(json['contentType']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      isDownloaded: serializer.fromJson<bool>(json['isDownloaded']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'messageId': serializer.toJson<int>(messageId),
      'url': serializer.toJson<String>(url),
      'contentType': serializer.toJson<String>(contentType),
      'localPath': serializer.toJson<String?>(localPath),
      'fileSize': serializer.toJson<int>(fileSize),
      'isDownloaded': serializer.toJson<bool>(isDownloaded),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MessageAttachment copyWith(
          {int? id,
          int? messageId,
          String? url,
          String? contentType,
          Value<String?> localPath = const Value.absent(),
          int? fileSize,
          bool? isDownloaded,
          DateTime? createdAt}) =>
      MessageAttachment(
        id: id ?? this.id,
        messageId: messageId ?? this.messageId,
        url: url ?? this.url,
        contentType: contentType ?? this.contentType,
        localPath: localPath.present ? localPath.value : this.localPath,
        fileSize: fileSize ?? this.fileSize,
        isDownloaded: isDownloaded ?? this.isDownloaded,
        createdAt: createdAt ?? this.createdAt,
      );
  MessageAttachment copyWithCompanion(MessageAttachmentsCompanion data) {
    return MessageAttachment(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      url: data.url.present ? data.url.value : this.url,
      contentType:
          data.contentType.present ? data.contentType.value : this.contentType,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      isDownloaded: data.isDownloaded.present
          ? data.isDownloaded.value
          : this.isDownloaded,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageAttachment(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('url: $url, ')
          ..write('contentType: $contentType, ')
          ..write('localPath: $localPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, messageId, url, contentType, localPath,
      fileSize, isDownloaded, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageAttachment &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.url == this.url &&
          other.contentType == this.contentType &&
          other.localPath == this.localPath &&
          other.fileSize == this.fileSize &&
          other.isDownloaded == this.isDownloaded &&
          other.createdAt == this.createdAt);
}

class MessageAttachmentsCompanion extends UpdateCompanion<MessageAttachment> {
  final Value<int> id;
  final Value<int> messageId;
  final Value<String> url;
  final Value<String> contentType;
  final Value<String?> localPath;
  final Value<int> fileSize;
  final Value<bool> isDownloaded;
  final Value<DateTime> createdAt;
  const MessageAttachmentsCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.url = const Value.absent(),
    this.contentType = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.isDownloaded = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MessageAttachmentsCompanion.insert({
    this.id = const Value.absent(),
    required int messageId,
    required String url,
    required String contentType,
    this.localPath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.isDownloaded = const Value.absent(),
    required DateTime createdAt,
  })  : messageId = Value(messageId),
        url = Value(url),
        contentType = Value(contentType),
        createdAt = Value(createdAt);
  static Insertable<MessageAttachment> custom({
    Expression<int>? id,
    Expression<int>? messageId,
    Expression<String>? url,
    Expression<String>? contentType,
    Expression<String>? localPath,
    Expression<int>? fileSize,
    Expression<bool>? isDownloaded,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (url != null) 'url': url,
      if (contentType != null) 'content_type': contentType,
      if (localPath != null) 'local_path': localPath,
      if (fileSize != null) 'file_size': fileSize,
      if (isDownloaded != null) 'is_downloaded': isDownloaded,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MessageAttachmentsCompanion copyWith(
      {Value<int>? id,
      Value<int>? messageId,
      Value<String>? url,
      Value<String>? contentType,
      Value<String?>? localPath,
      Value<int>? fileSize,
      Value<bool>? isDownloaded,
      Value<DateTime>? createdAt}) {
    return MessageAttachmentsCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      url: url ?? this.url,
      contentType: contentType ?? this.contentType,
      localPath: localPath ?? this.localPath,
      fileSize: fileSize ?? this.fileSize,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<int>(messageId.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (isDownloaded.present) {
      map['is_downloaded'] = Variable<bool>(isDownloaded.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('url: $url, ')
          ..write('contentType: $contentType, ')
          ..write('localPath: $localPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$ChatDatabase extends GeneratedDatabase {
  _$ChatDatabase(QueryExecutor e) : super(e);
  $ChatDatabaseManager get managers => $ChatDatabaseManager(this);
  late final $ChatsTable chats = $ChatsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $MessageAttachmentsTable messageAttachments =
      $MessageAttachmentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [chats, messages, messageAttachments];
}

typedef $$ChatsTableCreateCompanionBuilder = ChatsCompanion Function({
  Value<int> id,
  required int chatId,
  required String chatName,
  Value<String?> lastMessageText,
  Value<String?> lastMessageSenderUsername,
  Value<DateTime?> lastMessageCreatedAt,
  Value<int> unreadCount,
  Value<int?> pinnedMessageId,
  required DateTime updatedAt,
});
typedef $$ChatsTableUpdateCompanionBuilder = ChatsCompanion Function({
  Value<int> id,
  Value<int> chatId,
  Value<String> chatName,
  Value<String?> lastMessageText,
  Value<String?> lastMessageSenderUsername,
  Value<DateTime?> lastMessageCreatedAt,
  Value<int> unreadCount,
  Value<int?> pinnedMessageId,
  Value<DateTime> updatedAt,
});

class $$ChatsTableFilterComposer extends Composer<_$ChatDatabase, $ChatsTable> {
  $$ChatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chatName => $composableBuilder(
      column: $table.chatName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastMessageText => $composableBuilder(
      column: $table.lastMessageText,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastMessageSenderUsername => $composableBuilder(
      column: $table.lastMessageSenderUsername,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastMessageCreatedAt => $composableBuilder(
      column: $table.lastMessageCreatedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unreadCount => $composableBuilder(
      column: $table.unreadCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pinnedMessageId => $composableBuilder(
      column: $table.pinnedMessageId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ChatsTableOrderingComposer
    extends Composer<_$ChatDatabase, $ChatsTable> {
  $$ChatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chatName => $composableBuilder(
      column: $table.chatName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastMessageText => $composableBuilder(
      column: $table.lastMessageText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastMessageSenderUsername => $composableBuilder(
      column: $table.lastMessageSenderUsername,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastMessageCreatedAt => $composableBuilder(
      column: $table.lastMessageCreatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unreadCount => $composableBuilder(
      column: $table.unreadCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pinnedMessageId => $composableBuilder(
      column: $table.pinnedMessageId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ChatsTableAnnotationComposer
    extends Composer<_$ChatDatabase, $ChatsTable> {
  $$ChatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get chatName =>
      $composableBuilder(column: $table.chatName, builder: (column) => column);

  GeneratedColumn<String> get lastMessageText => $composableBuilder(
      column: $table.lastMessageText, builder: (column) => column);

  GeneratedColumn<String> get lastMessageSenderUsername => $composableBuilder(
      column: $table.lastMessageSenderUsername, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMessageCreatedAt => $composableBuilder(
      column: $table.lastMessageCreatedAt, builder: (column) => column);

  GeneratedColumn<int> get unreadCount => $composableBuilder(
      column: $table.unreadCount, builder: (column) => column);

  GeneratedColumn<int> get pinnedMessageId => $composableBuilder(
      column: $table.pinnedMessageId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChatsTableTableManager extends RootTableManager<
    _$ChatDatabase,
    $ChatsTable,
    Chat,
    $$ChatsTableFilterComposer,
    $$ChatsTableOrderingComposer,
    $$ChatsTableAnnotationComposer,
    $$ChatsTableCreateCompanionBuilder,
    $$ChatsTableUpdateCompanionBuilder,
    (Chat, BaseReferences<_$ChatDatabase, $ChatsTable, Chat>),
    Chat,
    PrefetchHooks Function()> {
  $$ChatsTableTableManager(_$ChatDatabase db, $ChatsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> chatId = const Value.absent(),
            Value<String> chatName = const Value.absent(),
            Value<String?> lastMessageText = const Value.absent(),
            Value<String?> lastMessageSenderUsername = const Value.absent(),
            Value<DateTime?> lastMessageCreatedAt = const Value.absent(),
            Value<int> unreadCount = const Value.absent(),
            Value<int?> pinnedMessageId = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ChatsCompanion(
            id: id,
            chatId: chatId,
            chatName: chatName,
            lastMessageText: lastMessageText,
            lastMessageSenderUsername: lastMessageSenderUsername,
            lastMessageCreatedAt: lastMessageCreatedAt,
            unreadCount: unreadCount,
            pinnedMessageId: pinnedMessageId,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int chatId,
            required String chatName,
            Value<String?> lastMessageText = const Value.absent(),
            Value<String?> lastMessageSenderUsername = const Value.absent(),
            Value<DateTime?> lastMessageCreatedAt = const Value.absent(),
            Value<int> unreadCount = const Value.absent(),
            Value<int?> pinnedMessageId = const Value.absent(),
            required DateTime updatedAt,
          }) =>
              ChatsCompanion.insert(
            id: id,
            chatId: chatId,
            chatName: chatName,
            lastMessageText: lastMessageText,
            lastMessageSenderUsername: lastMessageSenderUsername,
            lastMessageCreatedAt: lastMessageCreatedAt,
            unreadCount: unreadCount,
            pinnedMessageId: pinnedMessageId,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChatsTableProcessedTableManager = ProcessedTableManager<
    _$ChatDatabase,
    $ChatsTable,
    Chat,
    $$ChatsTableFilterComposer,
    $$ChatsTableOrderingComposer,
    $$ChatsTableAnnotationComposer,
    $$ChatsTableCreateCompanionBuilder,
    $$ChatsTableUpdateCompanionBuilder,
    (Chat, BaseReferences<_$ChatDatabase, $ChatsTable, Chat>),
    Chat,
    PrefetchHooks Function()>;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  Value<int> id,
  required int messageId,
  required int chatId,
  required String messageText,
  required String senderUsername,
  Value<int?> senderUserId,
  required DateTime createdAt,
  Value<DateTime?> editedAt,
  Value<int?> replyToId,
  Value<int?> forwardedFromId,
  Value<String?> attachmentsJson,
  Value<String> messageType,
  Value<bool> isPinned,
  Value<bool> isRead,
  Value<bool> isMe,
  Value<int?> commentsCount,
  Value<String?> reactionsJson,
  Value<int?> pinOrder,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<int> id,
  Value<int> messageId,
  Value<int> chatId,
  Value<String> messageText,
  Value<String> senderUsername,
  Value<int?> senderUserId,
  Value<DateTime> createdAt,
  Value<DateTime?> editedAt,
  Value<int?> replyToId,
  Value<int?> forwardedFromId,
  Value<String?> attachmentsJson,
  Value<String> messageType,
  Value<bool> isPinned,
  Value<bool> isRead,
  Value<bool> isMe,
  Value<int?> commentsCount,
  Value<String?> reactionsJson,
  Value<int?> pinOrder,
});

class $$MessagesTableFilterComposer
    extends Composer<_$ChatDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get messageText => $composableBuilder(
      column: $table.messageText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get senderUsername => $composableBuilder(
      column: $table.senderUsername,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get senderUserId => $composableBuilder(
      column: $table.senderUserId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get editedAt => $composableBuilder(
      column: $table.editedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get replyToId => $composableBuilder(
      column: $table.replyToId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get forwardedFromId => $composableBuilder(
      column: $table.forwardedFromId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attachmentsJson => $composableBuilder(
      column: $table.attachmentsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get messageType => $composableBuilder(
      column: $table.messageType, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isMe => $composableBuilder(
      column: $table.isMe, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get commentsCount => $composableBuilder(
      column: $table.commentsCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reactionsJson => $composableBuilder(
      column: $table.reactionsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pinOrder => $composableBuilder(
      column: $table.pinOrder, builder: (column) => ColumnFilters(column));
}

class $$MessagesTableOrderingComposer
    extends Composer<_$ChatDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageText => $composableBuilder(
      column: $table.messageText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get senderUsername => $composableBuilder(
      column: $table.senderUsername,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get senderUserId => $composableBuilder(
      column: $table.senderUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get editedAt => $composableBuilder(
      column: $table.editedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get replyToId => $composableBuilder(
      column: $table.replyToId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get forwardedFromId => $composableBuilder(
      column: $table.forwardedFromId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attachmentsJson => $composableBuilder(
      column: $table.attachmentsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageType => $composableBuilder(
      column: $table.messageType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isMe => $composableBuilder(
      column: $table.isMe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get commentsCount => $composableBuilder(
      column: $table.commentsCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reactionsJson => $composableBuilder(
      column: $table.reactionsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pinOrder => $composableBuilder(
      column: $table.pinOrder, builder: (column) => ColumnOrderings(column));
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$ChatDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<int> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get messageText => $composableBuilder(
      column: $table.messageText, builder: (column) => column);

  GeneratedColumn<String> get senderUsername => $composableBuilder(
      column: $table.senderUsername, builder: (column) => column);

  GeneratedColumn<int> get senderUserId => $composableBuilder(
      column: $table.senderUserId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<int> get replyToId =>
      $composableBuilder(column: $table.replyToId, builder: (column) => column);

  GeneratedColumn<int> get forwardedFromId => $composableBuilder(
      column: $table.forwardedFromId, builder: (column) => column);

  GeneratedColumn<String> get attachmentsJson => $composableBuilder(
      column: $table.attachmentsJson, builder: (column) => column);

  GeneratedColumn<String> get messageType => $composableBuilder(
      column: $table.messageType, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<bool> get isMe =>
      $composableBuilder(column: $table.isMe, builder: (column) => column);

  GeneratedColumn<int> get commentsCount => $composableBuilder(
      column: $table.commentsCount, builder: (column) => column);

  GeneratedColumn<String> get reactionsJson => $composableBuilder(
      column: $table.reactionsJson, builder: (column) => column);

  GeneratedColumn<int> get pinOrder =>
      $composableBuilder(column: $table.pinOrder, builder: (column) => column);
}

class $$MessagesTableTableManager extends RootTableManager<
    _$ChatDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, BaseReferences<_$ChatDatabase, $MessagesTable, Message>),
    Message,
    PrefetchHooks Function()> {
  $$MessagesTableTableManager(_$ChatDatabase db, $MessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> messageId = const Value.absent(),
            Value<int> chatId = const Value.absent(),
            Value<String> messageText = const Value.absent(),
            Value<String> senderUsername = const Value.absent(),
            Value<int?> senderUserId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> editedAt = const Value.absent(),
            Value<int?> replyToId = const Value.absent(),
            Value<int?> forwardedFromId = const Value.absent(),
            Value<String?> attachmentsJson = const Value.absent(),
            Value<String> messageType = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<bool> isMe = const Value.absent(),
            Value<int?> commentsCount = const Value.absent(),
            Value<String?> reactionsJson = const Value.absent(),
            Value<int?> pinOrder = const Value.absent(),
          }) =>
              MessagesCompanion(
            id: id,
            messageId: messageId,
            chatId: chatId,
            messageText: messageText,
            senderUsername: senderUsername,
            senderUserId: senderUserId,
            createdAt: createdAt,
            editedAt: editedAt,
            replyToId: replyToId,
            forwardedFromId: forwardedFromId,
            attachmentsJson: attachmentsJson,
            messageType: messageType,
            isPinned: isPinned,
            isRead: isRead,
            isMe: isMe,
            commentsCount: commentsCount,
            reactionsJson: reactionsJson,
            pinOrder: pinOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int messageId,
            required int chatId,
            required String messageText,
            required String senderUsername,
            Value<int?> senderUserId = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> editedAt = const Value.absent(),
            Value<int?> replyToId = const Value.absent(),
            Value<int?> forwardedFromId = const Value.absent(),
            Value<String?> attachmentsJson = const Value.absent(),
            Value<String> messageType = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<bool> isMe = const Value.absent(),
            Value<int?> commentsCount = const Value.absent(),
            Value<String?> reactionsJson = const Value.absent(),
            Value<int?> pinOrder = const Value.absent(),
          }) =>
              MessagesCompanion.insert(
            id: id,
            messageId: messageId,
            chatId: chatId,
            messageText: messageText,
            senderUsername: senderUsername,
            senderUserId: senderUserId,
            createdAt: createdAt,
            editedAt: editedAt,
            replyToId: replyToId,
            forwardedFromId: forwardedFromId,
            attachmentsJson: attachmentsJson,
            messageType: messageType,
            isPinned: isPinned,
            isRead: isRead,
            isMe: isMe,
            commentsCount: commentsCount,
            reactionsJson: reactionsJson,
            pinOrder: pinOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MessagesTableProcessedTableManager = ProcessedTableManager<
    _$ChatDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, BaseReferences<_$ChatDatabase, $MessagesTable, Message>),
    Message,
    PrefetchHooks Function()>;
typedef $$MessageAttachmentsTableCreateCompanionBuilder
    = MessageAttachmentsCompanion Function({
  Value<int> id,
  required int messageId,
  required String url,
  required String contentType,
  Value<String?> localPath,
  Value<int> fileSize,
  Value<bool> isDownloaded,
  required DateTime createdAt,
});
typedef $$MessageAttachmentsTableUpdateCompanionBuilder
    = MessageAttachmentsCompanion Function({
  Value<int> id,
  Value<int> messageId,
  Value<String> url,
  Value<String> contentType,
  Value<String?> localPath,
  Value<int> fileSize,
  Value<bool> isDownloaded,
  Value<DateTime> createdAt,
});

class $$MessageAttachmentsTableFilterComposer
    extends Composer<_$ChatDatabase, $MessageAttachmentsTable> {
  $$MessageAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDownloaded => $composableBuilder(
      column: $table.isDownloaded, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$MessageAttachmentsTableOrderingComposer
    extends Composer<_$ChatDatabase, $MessageAttachmentsTable> {
  $$MessageAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDownloaded => $composableBuilder(
      column: $table.isDownloaded,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$MessageAttachmentsTableAnnotationComposer
    extends Composer<_$ChatDatabase, $MessageAttachmentsTable> {
  $$MessageAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<bool> get isDownloaded => $composableBuilder(
      column: $table.isDownloaded, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MessageAttachmentsTableTableManager extends RootTableManager<
    _$ChatDatabase,
    $MessageAttachmentsTable,
    MessageAttachment,
    $$MessageAttachmentsTableFilterComposer,
    $$MessageAttachmentsTableOrderingComposer,
    $$MessageAttachmentsTableAnnotationComposer,
    $$MessageAttachmentsTableCreateCompanionBuilder,
    $$MessageAttachmentsTableUpdateCompanionBuilder,
    (
      MessageAttachment,
      BaseReferences<_$ChatDatabase, $MessageAttachmentsTable,
          MessageAttachment>
    ),
    MessageAttachment,
    PrefetchHooks Function()> {
  $$MessageAttachmentsTableTableManager(
      _$ChatDatabase db, $MessageAttachmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageAttachmentsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> messageId = const Value.absent(),
            Value<String> url = const Value.absent(),
            Value<String> contentType = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<int> fileSize = const Value.absent(),
            Value<bool> isDownloaded = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              MessageAttachmentsCompanion(
            id: id,
            messageId: messageId,
            url: url,
            contentType: contentType,
            localPath: localPath,
            fileSize: fileSize,
            isDownloaded: isDownloaded,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int messageId,
            required String url,
            required String contentType,
            Value<String?> localPath = const Value.absent(),
            Value<int> fileSize = const Value.absent(),
            Value<bool> isDownloaded = const Value.absent(),
            required DateTime createdAt,
          }) =>
              MessageAttachmentsCompanion.insert(
            id: id,
            messageId: messageId,
            url: url,
            contentType: contentType,
            localPath: localPath,
            fileSize: fileSize,
            isDownloaded: isDownloaded,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MessageAttachmentsTableProcessedTableManager = ProcessedTableManager<
    _$ChatDatabase,
    $MessageAttachmentsTable,
    MessageAttachment,
    $$MessageAttachmentsTableFilterComposer,
    $$MessageAttachmentsTableOrderingComposer,
    $$MessageAttachmentsTableAnnotationComposer,
    $$MessageAttachmentsTableCreateCompanionBuilder,
    $$MessageAttachmentsTableUpdateCompanionBuilder,
    (
      MessageAttachment,
      BaseReferences<_$ChatDatabase, $MessageAttachmentsTable,
          MessageAttachment>
    ),
    MessageAttachment,
    PrefetchHooks Function()>;

class $ChatDatabaseManager {
  final _$ChatDatabase _db;
  $ChatDatabaseManager(this._db);
  $$ChatsTableTableManager get chats =>
      $$ChatsTableTableManager(_db, _db.chats);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$MessageAttachmentsTableTableManager get messageAttachments =>
      $$MessageAttachmentsTableTableManager(_db, _db.messageAttachments);
}
