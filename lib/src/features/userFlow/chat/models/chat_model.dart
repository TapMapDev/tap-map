import 'package:equatable/equatable.dart';

class ChatModel extends Equatable {
  final int chatId;
  final String chatName;
  final String? lastMessageText;
  final String? lastMessageSenderUsername;
  final DateTime? lastMessageCreatedAt;
  final int unreadCount;
  final int? pinnedMessageId;

  const ChatModel({
    required this.chatId,
    required this.chatName,
    this.lastMessageText,
    this.lastMessageSenderUsername,
    this.lastMessageCreatedAt,
    this.unreadCount = 0,
    this.pinnedMessageId,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      chatId: json['id'] as int? ?? json['chat_id'] as int? ?? 0,
      chatName: json['chat_name'] as String? ?? 'Unknown Chat',
      lastMessageText: json['last_message_text'] as String?,
      lastMessageSenderUsername:
          json['last_message_sender_username'] as String?,
      lastMessageCreatedAt: json['last_message_created_at'] != null
          ? DateTime.parse(json['last_message_created_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      pinnedMessageId: json['pinned_message_id'] as int?,
    );
  }

  ChatModel copyWith({
    int? chatId,
    String? chatName,
    String? lastMessageText,
    String? lastMessageSenderUsername,
    DateTime? lastMessageCreatedAt,
    int? unreadCount,
    int? pinnedMessageId,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      chatName: chatName ?? this.chatName,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageSenderUsername:
          lastMessageSenderUsername ?? this.lastMessageSenderUsername,
      lastMessageCreatedAt: lastMessageCreatedAt ?? this.lastMessageCreatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      pinnedMessageId: pinnedMessageId ?? this.pinnedMessageId,
    );
  }

  @override
  List<Object?> get props => [
        chatId,
        chatName,
        lastMessageText,
        lastMessageSenderUsername,
        lastMessageCreatedAt,
        unreadCount,
        pinnedMessageId,
      ];
}
