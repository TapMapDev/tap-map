import 'package:flutter/material.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_websocket_service.dart';

/// Виджет для отображения статуса соединения в UI
class ConnectionStatusIndicator extends StatelessWidget {
  final ConnectionState connectionState;
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
      case ConnectionState.connected:
        return Colors.green;
      case ConnectionState.connecting:
      case ConnectionState.reconnecting:
        return Colors.orange;
      case ConnectionState.disconnected:
      case ConnectionState.waitingForNetwork:
        return Colors.grey;
      case ConnectionState.error:
        return Colors.red;
    }
  }

  IconData _getIcon() {
    switch (connectionState) {
      case ConnectionState.connected:
        return Icons.wifi;
      case ConnectionState.connecting:
      case ConnectionState.reconnecting:
        return Icons.sync;
      case ConnectionState.disconnected:
      case ConnectionState.waitingForNetwork:
        return Icons.wifi_off;
      case ConnectionState.error:
        return Icons.error_outline;
    }
  }

  String _getStatusText() {
    switch (connectionState) {
      case ConnectionState.connected:
        return 'Подключено';
      case ConnectionState.connecting:
        return 'Подключение...';
      case ConnectionState.disconnected:
        return 'Отключено';
      case ConnectionState.reconnecting:
        if (reconnectAttempt != null && maxReconnectAttempts != null) {
          return 'Переподключение ($reconnectAttempt/$maxReconnectAttempts)';
        }
        return 'Переподключение...';
      case ConnectionState.waitingForNetwork:
        return 'Ожидание сети';
      case ConnectionState.error:
        return 'Ошибка соединения';
    }
  }
}
