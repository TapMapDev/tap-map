import 'package:equatable/equatable.dart';

enum MessageType {
  text,
  image,
  video,
  file,
}

class MessageModel extends Equatable {
  final int id;
  final int chatId;
  final String text;
  final String senderUsername;
  final DateTime createdAt;
  final DateTime? editedAt;
  final int? replyToId;
  final int? forwardedFromId;
  final List<Map<String, String>> attachments;
  final MessageType type;
  final bool isPinned;
  final bool isRead;
  final bool isTyping;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.text,
    required this.senderUsername,
    required this.createdAt,
    this.editedAt,
    this.replyToId,
    this.forwardedFromId,
    this.attachments = const [],
    this.type = MessageType.text,
    this.isPinned = false,
    this.isRead = false,
    this.isTyping = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final editedAt = json['edited_at'] as String?;
    return MessageModel(
      id: json['id'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      chatId: json['chat'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      senderUsername: json['sender_username'] as String? ?? 'Unknown',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      editedAt: editedAt != null ? DateTime.parse(editedAt) : null,
      replyToId: json['reply_to_id'] as int?,
      forwardedFromId: json['forwarded_from_id'] as int?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => {
                    'url': e['url'] as String? ?? '',
                    'content_type': e['content_type'] as String? ?? '',
                  })
              .toList() ??
          [],
      type: _parseMessageType(json['type'] as String?),
      isPinned: json['is_pinned'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? false,
      isTyping: json['is_typing'] as bool? ?? false,
    );
  }

  static MessageType _parseMessageType(String? type) {
    if (type == null || type == 'create_message') return MessageType.text;
    try {
      return MessageType.values.firstWhere(
        (t) => t.toString().split('.').last == type.toLowerCase(),
        orElse: () => MessageType.text,
      );
    } catch (e) {
      return MessageType.text;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'text': text,
      'sender_username': senderUsername,
      'created_at': createdAt.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
      'reply_to_id': replyToId,
      'forwarded_from_id': forwardedFromId,
      'attachments': attachments,
      'type': type.toString().split('.').last,
      'is_pinned': isPinned,
      'is_read': isRead,
      'is_typing': isTyping,
    };
  }

  MessageModel copyWith({
    int? id,
    int? chatId,
    String? text,
    String? senderUsername,
    DateTime? createdAt,
    DateTime? editedAt,
    int? replyToId,
    int? forwardedFromId,
    List<Map<String, String>>? attachments,
    MessageType? type,
    bool? isPinned,
    bool? isRead,
    bool? isTyping,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      text: text ?? this.text,
      senderUsername: senderUsername ?? this.senderUsername,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      replyToId: replyToId ?? this.replyToId,
      forwardedFromId: forwardedFromId ?? this.forwardedFromId,
      attachments: attachments ?? this.attachments,
      type: type ?? this.type,
      isPinned: isPinned ?? this.isPinned,
      isRead: isRead ?? this.isRead,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        text,
        senderUsername,
        createdAt,
        editedAt,
        replyToId,
        forwardedFromId,
        attachments,
        type,
        isPinned,
        isRead,
        isTyping,
      ];

  static MessageModel empty() {
    return MessageModel(
      id: 0,
      chatId: 0,
      text: '',
      senderUsername: '',
      createdAt: DateTime.now(),
      isPinned: false,
      isRead: false,
      isTyping: false,
    );
  }
}
