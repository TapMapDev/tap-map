import 'dart:convert';

import 'websocket_service.dart';

class WebSocketEvent {
  final WebSocketService _webSocketService;

  WebSocketEvent(this._webSocketService);

  void handleEvent(dynamic rawData) {
    try {
      print('Received WebSocket event: $rawData');

      if (rawData is! String) {
        print(
            'Invalid event format: expected String, got ${rawData.runtimeType}');
        return;
      }

      final data = jsonDecode(rawData) as Map<String, dynamic>;
      final eventType = data['event'] as String?;

      if (eventType == null) {
        print('Event type is missing in the data');
        return;
      }

      print('Processing event type: $eventType');

      switch (eventType) {
        case 'message':
          _handleMessage(data);
          break;
        case 'typing':
          _handleTyping(data);
          break;
        case 'read_message':
          _handleReadMessage(data);
          break;
        default:
          print('Unknown event type: $eventType');
      }
    } catch (e, stackTrace) {
      print('Error handling WebSocket event: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _handleMessage(Map<String, dynamic> data) {
    final message = data['message'] as String?;
    final chatId = data['chat_id'] as String?;
    final senderId = data['sender_id'] as int?;

    if (message == null || chatId == null || senderId == null) {
      print('Invalid message data: missing required fields');
      return;
    }

    print('New message in chat $chatId from user $senderId: $message');
    // TODO: Add message handling logic
  }

  void _handleTyping(Map<String, dynamic> data) {
    final chatId = data['chat_id'] as String?;
    final userId = data['user_id'] as int?;

    if (chatId == null || userId == null) {
      print('Invalid typing data: missing required fields');
      return;
    }

    print('User $userId is typing in chat $chatId');
    // TODO: Add typing status handling logic
  }

  void _handleReadMessage(Map<String, dynamic> data) {
    final messageId = data['message_id'];
    final chatId = data['chat_id'];
    final readerId = data['reader_id'];

    if (messageId == null || chatId == null || readerId == null) {
      print('⚠️ Invalid read receipt data: missing required fields');
      print('📝 Data received: $data');
      return;
    }

    print('📖 Message $messageId in chat $chatId was read by user $readerId');

    // Используем существующий метод readMessage
    _webSocketService.readMessage(
      chatId: chatId,
      messageId: messageId,
    );
  }
}
