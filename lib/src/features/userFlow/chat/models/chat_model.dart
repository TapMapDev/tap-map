import 'package:equatable/equatable.dart';

class ChatModel extends Equatable {
  final int chatId;
  final String chatName;
  final String? chatPhoto;
  final String? lastMessageText;
  final String? lastMessageSenderUsername;
  final DateTime? lastMessageCreatedAt;
  final int unreadCount;
  final bool isPinned;
  final int? pinOrder;
  final int? pinnedMessageId;

  const ChatModel({
    required this.chatId,
    required this.chatName,
    this.chatPhoto,
    this.lastMessageText,
    this.lastMessageSenderUsername,
    this.lastMessageCreatedAt,
    this.unreadCount = 0,
    this.isPinned = false,
    this.pinOrder,
    this.pinnedMessageId,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      chatId: json['id'] as int? ?? json['chat_id'] as int? ?? 0,
      chatName: json['chat_name'] as String? ?? 'Unknown Chat',
      chatPhoto: json['chat_photo'] as String?,
      lastMessageText: json['last_message_text'] as String?,
      lastMessageSenderUsername:
          json['last_message_sender_username'] as String?,
      lastMessageCreatedAt: json['last_message_created_at'] != null
          ? DateTime.parse(json['last_message_created_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      pinOrder: json['pin_order'] as int?,
      pinnedMessageId: json['pinned_message_id'] as int?,
    );
  }

  ChatModel copyWith({
    int? chatId,
    String? chatName,
    String? chatPhoto,
    String? lastMessageText,
    String? lastMessageSenderUsername,
    DateTime? lastMessageCreatedAt,
    int? unreadCount,
    bool? isPinned,
    int? pinOrder,
    int? pinnedMessageId,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      chatName: chatName ?? this.chatName,
      chatPhoto: chatPhoto ?? this.chatPhoto,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageSenderUsername:
          lastMessageSenderUsername ?? this.lastMessageSenderUsername,
      lastMessageCreatedAt: lastMessageCreatedAt ?? this.lastMessageCreatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      pinOrder: pinOrder ?? this.pinOrder,
      pinnedMessageId: pinnedMessageId ?? this.pinnedMessageId,
    );
  }

  @override
  List<Object?> get props => [
        chatId,
        chatName,
        chatPhoto,
        lastMessageText,
        lastMessageSenderUsername,
        lastMessageCreatedAt,
        unreadCount,
        isPinned,
        pinOrder,
        pinnedMessageId,
      ];
}
