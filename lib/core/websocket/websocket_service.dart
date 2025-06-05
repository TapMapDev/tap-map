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
      print('❌ Socket: Channel is closed, attempting to reconnect...');
      try {
        connect(); // Попытка переподключиться
        print('✅ Socket: Reconnected successfully');
      } catch (e) {
        print('❌ Socket: Failed to reconnect: $e');
        return;
      }
    }

    final jsonMessage = jsonEncode({
      'type': 'edit_message',
      'chat_id': chatId,
      'message_id': messageId,
      'text': text,
      'edited_at': DateTime.now().toIso8601String(),
    });

    print('📤 Socket: Sending edit message: $jsonMessage');
    try {
      _channel.sink.add(jsonMessage);
      print('✅ Socket: Edit message sent successfully');
    } catch (e) {
      print('❌ Socket: Failed to send edit message: $e');
      throw e; // Пробрасываем ошибку для обработки в EditBloc
    }
  }

  void deleteMessage({
    required int chatId,
    required int messageId,
    required String action,
  }) {
    if (_channel.closeCode != null) {
      print('❌ Socket: Channel is closed, attempting to reconnect...');
      try {
        connect(); // Попытка переподключиться
        print('✅ Socket: Reconnected successfully');
      } catch (e) {
        print('❌ Socket: Failed to reconnect for delete message: $e');
        return;
      }
    }

    final jsonMessage = jsonEncode({
      'type': 'delete_message',
      'chat_id': chatId,
      'message_id': messageId,
      'action': action,
    });
    
    print('📤 Socket: Sending delete message: $jsonMessage');
    try {
      _channel.sink.add(jsonMessage);
      print('✅ Socket: Delete message sent successfully');
    } catch (e) {
      print('❌ Socket: Failed to send delete message: $e');
      // Не пробрасываем ошибку, чтобы UI не падал
    }
  }

  void readMessage({required int chatId, required int messageId}) {
    if (_channel.closeCode != null) {
      print('❌ Socket: Channel is closed when sending read_message, skipping');
      return;
    }
    
    final jsonMessage = jsonEncode({
      'type': 'read_message',
      'chat_id': chatId,
      'message_id': messageId,
    });
    
    try {
      _channel.sink.add(jsonMessage);
    } catch (e) {
      print('❌ Socket: Failed to send read message: $e');
    }
  }

  void sendTyping({required int chatId, required bool isTyping}) {
    if (_channel.closeCode != null) {
      print('❌ Socket: Channel is closed when sending typing status, skipping');
      return;
    }
    
    final jsonMessage = jsonEncode({
      'type': 'typing',
      'chat_id': chatId,
      'is_typing': isTyping,
    });
    
    try {
      _channel.sink.add(jsonMessage);
    } catch (e) {
      print('❌ Socket: Failed to send typing status: $e');
    }
  }

  Stream get stream => _broadcastStream;

  WebSocketChannel get channel => _channel;
}
