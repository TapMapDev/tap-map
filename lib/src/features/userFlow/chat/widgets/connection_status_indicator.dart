import 'package:flutter/material.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_websocket_service.dart' as chat;

/// Виджет для отображения статуса соединения в UI
class ConnectionStatusIndicator extends StatelessWidget {
  final chat.ConnectionState connectionState;
  final int? reconnectAttempt;
  final int? maxReconnectAttempts;

  const ConnectionStatusIndicator({
    super.key,
    required this.connectionState,
    this.reconnectAttempt,
    this.maxReconnectAttempts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusText(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (connectionState) {
      case chat.ConnectionState.connected:
        return Colors.green;
      case chat.ConnectionState.connecting:
      case chat.ConnectionState.reconnecting:
        return Colors.orange;
      case chat.ConnectionState.disconnected:
      case chat.ConnectionState.waitingForNetwork:
        return Colors.grey;
      case chat.ConnectionState.error:
        return Colors.red;
    }
  }

  IconData _getIcon() {
    switch (connectionState) {
      case chat.ConnectionState.connected:
        return Icons.wifi;
      case chat.ConnectionState.connecting:
      case chat.ConnectionState.reconnecting:
        return Icons.sync;
      case chat.ConnectionState.disconnected:
      case chat.ConnectionState.waitingForNetwork:
        return Icons.wifi_off;
      case chat.ConnectionState.error:
        return Icons.error_outline;
    }
  }

  String _getStatusText() {
    switch (connectionState) {
      case chat.ConnectionState.connected:
        return 'Подключено';
      case chat.ConnectionState.connecting:
        return 'Подключение...';
      case chat.ConnectionState.disconnected:
        return 'Отключено';
      case chat.ConnectionState.reconnecting:
        if (reconnectAttempt != null && maxReconnectAttempts != null) {
          return 'Переподключение ($reconnectAttempt/$maxReconnectAttempts)';
        }
        return 'Переподключение...';
      case chat.ConnectionState.waitingForNetwork:
        return 'Ожидание сети';
      case chat.ConnectionState.error:
        return 'Ошибка соединения';
    }
  }
}
