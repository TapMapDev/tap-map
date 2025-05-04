import 'package:equatable/equatable.dart';

enum MessageStatus {
  sent,
  delivered,
  read,
}

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
  final int? replyToId;
  final int? forwardedFromId;
  final List<Map<String, String>> attachments;
  final MessageStatus status;
  final MessageType type;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.text,
    required this.senderUsername,
    required this.createdAt,
    this.replyToId,
    this.forwardedFromId,
    this.attachments = const [],
    this.status = MessageStatus.sent,
    this.type = MessageType.text,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      chatId: json['chat_id'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      senderUsername: json['sender_username'] as String? ?? 'Unknown',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      replyToId: json['reply_to_id'] as int?,
      forwardedFromId: json['forwarded_from_id'] as int?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => {
                    'url': e['url'] as String? ?? '',
                    'content_type': e['content_type'] as String? ?? '',
                  })
              .toList() ??
          [],
      status: _parseMessageStatus(json['status'] as String?),
      type: _parseMessageType(json['type'] as String?),
    );
  }

  static MessageStatus _parseMessageStatus(String? status) {
    if (status == null) return MessageStatus.sent;
    try {
      return MessageStatus.values.firstWhere(
        (s) => s.toString().split('.').last == status.toLowerCase(),
        orElse: () => MessageStatus.sent,
      );
    } catch (e) {
      return MessageStatus.sent;
    }
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
      'reply_to_id': replyToId,
      'forwarded_from_id': forwardedFromId,
      'attachments': attachments,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
    };
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        text,
        senderUsername,
        createdAt,
        replyToId,
        forwardedFromId,
        attachments,
        status,
        type,
      ];
}
