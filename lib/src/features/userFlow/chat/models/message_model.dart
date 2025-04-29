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
  final String text;
  final int userId;
  final DateTime createdAt;
  final MessageStatus status;
  final MessageType type;

  const MessageModel({
    required this.id,
    required this.text,
    required this.userId,
    required this.createdAt,
    required this.status,
    required this.type,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      text: json['text'] as String,
      userId: json['user_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${json['status']}',
        orElse: () => MessageStatus.sent,
      ),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
    };
  }

  @override
  List<Object?> get props => [
        id,
        text,
        userId,
        createdAt,
        status,
        type,
      ];
}
