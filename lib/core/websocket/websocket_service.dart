import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  late WebSocketChannel _channel;
  late Stream _broadcastStream;
  final String _jwtToken;
  String? _currentUsername;

  WebSocketService({
    required String jwtToken,
  }) : _jwtToken = jwtToken;

  void setCurrentUsername(String username) {
    _currentUsername = username;
  }

  void connect() {
    _channel = IOWebSocketChannel.connect(
      Uri.parse('wss://api.tap-map.net/ws/notifications/'),
      headers: {
        'Authorization': 'Bearer $_jwtToken',
      },
    );
    _broadcastStream = _channel.stream.asBroadcastStream();
    print('Socket: Соединение установлено успешно');
  }

  void disconnect() {
    _channel.sink.close();
    print('Socket: Отключено');
  }

  void sendMessage({
    required int chatId,
    required String text,
    int? replyToId,
    int? forwardedFromId,
    List<Map<String, String>>? attachments,
  }) {
    final message = {
      'type': 'create_message',
      'chat_id': chatId,
      'text': text,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (forwardedFromId != null) 'forwarded_from_id': forwardedFromId,
      if (attachments != null && attachments.isNotEmpty)
        'attachments': attachments,
    };

    print('📤 Socket: Sending message: $message');
    _channel.sink.add(jsonEncode(message));
  }

  void editMessage({
    required int chatId,
    required int messageId,
    required String text,
  }) {
    if (_channel.closeCode != null) {
      return;
    }
    final jsonMessage = jsonEncode({
      'type': 'edit_message',
      'chat_id': chatId,
      'message_id': messageId,
      'text': text,
      'edited_at': DateTime.now().toIso8601String(),
    });

    _channel.sink.add(jsonMessage);
  }

  void readMessage({required int chatId, required int messageId}) {
    if (_channel.closeCode != null) {
      return;
    }
    final jsonMessage = jsonEncode({
      'type': 'read_message',
      'chat_id': chatId,
      'message_id': messageId,
    });
    _channel.sink.add(jsonMessage);
  }

  void sendTyping({required int chatId, required bool isTyping}) {
    if (_channel.closeCode != null) {
      return;
    }
    final jsonMessage = jsonEncode({
      'type': 'typing',
      'chat_id': chatId,
      'is_typing': isTyping,
    });
  }

  Stream get stream => _broadcastStream;

  WebSocketChannel get channel => _channel;
}
