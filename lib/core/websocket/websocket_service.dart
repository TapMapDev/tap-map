import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  late WebSocketChannel _channel;
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

    _channel.stream.listen(
      (message) {
        print('Socket: Получено сообщение: $message');
      },
      onDone: () {
        print('Socket: Соединение закрыто');
      },
      onError: (error) {
        print('Socket: Ошибка соединения: $error');
      },
    );

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
}
