import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  late WebSocketChannel _channel;
  late Stream _broadcastStream;
  final String _jwtToken;

  WebSocketService({
    required String jwtToken,
  }) : _jwtToken = jwtToken;

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
    List<Map<String, String>>? attachments,
    int? replyToId,
    int? forwardedFromId,
  }) {
    if (_channel.closeCode != null) {
      print('WebSocket уже закрыт, сообщение не отправлено');
      return;
    }
    final jsonMessage = jsonEncode({
      'type': 'create_message',
      'chat_id': chatId,
      'text': text,
      'attachments': attachments ?? [],
      'reply_to_id': replyToId,
      'forwarded_from_id': forwardedFromId,
    });

    _channel.sink.add(jsonMessage);
    print('Socket: Отправлено сообщение: $jsonMessage');
  }

  void editMessage({
    required int chatId,
    required int messageId,
    required String text,
  }) {
    if (_channel.closeCode != null) {
      print('WebSocket уже закрыт, сообщение не отредактировано');
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
    print('Socket: Отправлено редактирование сообщения: $jsonMessage');
  }

  void readMessage({required int chatId, required int messageId}) {
    if (_channel.closeCode != null) {
      print('WebSocket уже закрыт, событие read_message не отправлено');
      return;
    }
    final jsonMessage = jsonEncode({
      'type': 'read_message',
      'chat_id': chatId,
      'message_id': messageId,
    });
    _channel.sink.add(jsonMessage);
    print('Socket: Отправлено событие read_message: $jsonMessage');
  }

  void sendTyping({required int chatId, required bool isTyping}) {
    if (_channel.closeCode != null) {
      print('WebSocket уже закрыт, событие typing не отправлено');
      return;
    }
    final jsonMessage = jsonEncode({
      'type': 'typing',
      'chat_id': chatId,
      'is_typing': isTyping,
    });
    _channel.sink.add(jsonMessage);
    print('Socket: Отправлено событие typing: $jsonMessage');
  }

  Stream get stream => _broadcastStream;

  WebSocketChannel get channel => _channel;
}
