import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final String url;
  final String jwtToken;
  WebSocketChannel? _channel;
  final StreamController<dynamic> _controller = StreamController.broadcast();

  bool _isConnected = false;

  WebSocketService({
    required this.url,
    required this.jwtToken,
  });

  Stream<dynamic> get stream => _controller.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) {
      print('WebSocket already connected.');
      return;
    }

    final uri = Uri.parse(url);
    print('Connecting to WebSocket: $uri');

    try {
      _channel = IOWebSocketChannel.connect(
        uri,
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );

      _isConnected = true;
      print('WebSocket connected.');

      _channel!.stream.listen(
        (message) {
          print('Received: $message');
          try {
            final data = jsonDecode(message);
            _controller.add(data);
          } catch (_) {
            _controller.add(message);
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          reconnect();
        },
        onDone: () {
          print('WebSocket connection closed.');
          _isConnected = false;
          reconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _isConnected = false;
      reconnect();
    }
  }

  void send(dynamic data) {
    if (_isConnected && _channel != null) {
      final message = jsonEncode(data);
      print('Sending: $message');
      _channel!.sink.add(message);
    } else {
      print('Cannot send: WebSocket not connected.');
    }
  }

  void disconnect() {
    print('Disconnecting WebSocket...');
    _isConnected = false;
    _channel?.sink.close();
    _controller.close();
  }

  void reconnect() async {
    print('Reconnecting in 5 seconds...');
    await Future.delayed(const Duration(seconds: 5));
    await connect();
  }
}
