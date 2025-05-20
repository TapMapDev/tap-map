import 'dart:convert';

import 'websocket_service.dart';

class WebSocketEvent {
  final WebSocketService _webSocketService;

  WebSocketEvent(this._webSocketService);

  void handleEvent(dynamic rawData) {
    try {
      if (rawData is! String) {
        return;
      }

      final data = jsonDecode(rawData) as Map<String, dynamic>;
      final eventType = data['event'] as String?;

      if (eventType == null) {
        return;
      }
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
      }
    } catch (_) {}
  }

  void _handleMessage(Map<String, dynamic> data) {
    final message = data['message'] as String?;
    final chatId = data['chat_id'] as String?;
    final senderId = data['sender_id'] as int?;

    if (message == null || chatId == null || senderId == null) {
      return;
    }
  }

  void _handleTyping(Map<String, dynamic> data) {
    print('⌨️ WebSocketEvent: Обработка события typing');
    print('📦 WebSocketEvent: Данные события: $data');

    final chatId = data['chat_id'] as String?;
    final userId = data['user_id'] as int?;
    final username = data['username'] as String?;
    final isTyping = data['is_typing'] as bool?;

    print(
        '🔍 WebSocketEvent: chatId: $chatId, userId: $userId, username: $username, isTyping: $isTyping');

    if (chatId == null || userId == null) {
      print(
          '❌ WebSocketEvent: Отсутствуют обязательные поля chatId или userId');
      return;
    }

    print('✅ WebSocketEvent: Событие typing успешно обработано');
  }

  void _handleReadMessage(Map<String, dynamic> data) {
    final messageId = data['message_id'];
    final chatId = data['chat_id'];
    final readerId = data['reader_id'];

    if (messageId == null || chatId == null || readerId == null) {
      return;
    }

    _webSocketService.readMessage(
      chatId: chatId,
      messageId: messageId,
    );
  }
}
