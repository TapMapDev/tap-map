import 'package:tap_map/core/websocket/websocket_service.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

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
  }) {
    if (text.trim().isEmpty) {
      throw Exception('Message text cannot be empty');
    }
    _webSocketService.sendMessage(
      chatId: chatId,
      text: text,
      replyToId: replyToId,
      forwardedFromId: forwardedFromId,
    );

    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      text: text,
      chatId: chatId,
      replyToId: replyToId,
      forwardedFromId: forwardedFromId,
      createdAt: DateTime.now(),
      senderUsername: _currentUsername,
      status: MessageStatus.sent,
      type: MessageType.text,
    );
    return message;
  }
}
