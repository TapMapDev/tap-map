import 'package:tap_map/core/websocket/websocket_service.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

// TODO(tapmap): Переписать логику отправки сообщений без отдельного use case.
// Использовать основной подход проекта с репозиториями и BLoC.

class SendMessageUseCase {
  final WebSocketService _webSocketService;
  final String _currentUsername;

  SendMessageUseCase({
    required WebSocketService webSocketService,
    required String currentUsername,
  })  : _webSocketService = webSocketService,
        _currentUsername = currentUsername;

  MessageModel execute({
    required int chatId,
    required String text,
    int? replyToId,
    int? forwardedFromId,
    List<Map<String, String>>? attachments,
  }) {
    if (text.trim().isEmpty && (attachments == null || attachments.isEmpty)) {
      throw Exception('Message must have either text or attachments');
    }

    _webSocketService.sendMessage(
      chatId: chatId,
      text: text,
      replyToId: replyToId,
      forwardedFromId: forwardedFromId,
      attachments: attachments,
    );

    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      text: text,
      chatId: chatId,
      replyToId: replyToId,
      forwardedFromId: forwardedFromId,
      createdAt: DateTime.now(),
      senderUsername: _currentUsername,
      isRead: false,
      type: _getMessageType(attachments),
      attachments: attachments ?? [],
    );
    return message;
  }

  MessageType _getMessageType(List<Map<String, String>>? attachments) {
    if (attachments == null || attachments.isEmpty) {
      return MessageType.text;
    }

    final contentType = attachments.first['content_type']?.toLowerCase() ?? '';
    if (contentType.startsWith('video/')) {
      return MessageType.video;
    } else if (contentType.startsWith('image/')) {
      return MessageType.image;
    } else {
      return MessageType.file;
    }
  }
}
