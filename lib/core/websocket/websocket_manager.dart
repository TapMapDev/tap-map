import 'package:get_it/get_it.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';

import 'websocket_service.dart';

class WebSocketManager {
  static Future<void> initialize() async {
    print('Initializing WebSocket...');

    // Get access token for WebSocket
    final wsToken =
        await GetIt.instance<SharedPrefsRepository>().getAccessToken();
    print('WebSocket token: ${wsToken != null ? 'present' : 'missing'}');

    final wsService = WebSocketService(
      url: 'wss://api.tap-map.net/ws/notifications/',
      jwtToken: wsToken ?? '',
    );

    GetIt.instance.registerSingleton<WebSocketService>(wsService);
    print('WebSocket service registered');

    // Connect to WebSocket
    wsService.connect();
    print('WebSocket connection initiated');
  }

  static void sendTyping({required String chatId}) {
    final message = {
      "event": "typing",
      "chat_id": chatId,
    };
    _sendMessage(message);
  }

  static void sendMessage({required String chatId, required String text}) {
    final message = {
      "event": "message",
      "chat_id": chatId,
      "text": text,
    };
    _sendMessage(message);
  }

  static void sendReadReceipt({required String messageId}) {
    final message = {
      "event": "read_message",
      "message_id": messageId,
    };
    _sendMessage(message);
  }

  static void _sendMessage(Map<String, dynamic> message) {
    try {
      final wsService = GetIt.instance<WebSocketService>();
      if (wsService.isConnected) {
        wsService.send(message);
      } else {
        print('Cannot send message: WebSocket is not connected');
      }
    } catch (e) {
      print('Error sending WebSocket message: $e');
    }
  }
}
