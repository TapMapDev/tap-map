import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/core/websocket/websocket_service.dart';

class WebSocketTestScreen extends StatefulWidget {
  const WebSocketTestScreen({super.key});

  @override
  State<WebSocketTestScreen> createState() => _WebSocketTestScreenState();
}

class _WebSocketTestScreenState extends State<WebSocketTestScreen> {
  late WebSocketService _webSocketService;
  final TextEditingController _messageController = TextEditingController();
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  Future<void> _initializeWebSocket() async {
    final token =
        await GetIt.instance<SharedPrefsRepository>().getAccessToken();
    if (token == null) {
      print('❌ No access token available');
      return;
    }

    _webSocketService = WebSocketService(jwtToken: token);
    _webSocketService.connect();
    setState(() {
      _isConnected = true;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _webSocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Status: ${_isConnected ? 'Connected' : 'Disconnected'}',
              style: TextStyle(
                color: _isConnected ? Colors.green : Colors.red,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message to send',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_messageController.text.isNotEmpty) {
                  _webSocketService.sendMessage(_messageController.text);
                  _messageController.clear();
                }
              },
              child: const Text('Send Message'),
            ),
          ],
        ),
      ),
    );
  }
}
