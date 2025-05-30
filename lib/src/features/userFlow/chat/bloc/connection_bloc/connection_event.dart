import 'package:equatable/equatable.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_websocket_service.dart' as ws;

/// События для ConnectionBloc
abstract class ConnectionEvent extends Equatable {
  const ConnectionEvent();

  @override
  List<Object?> get props => [];
}

/// Событие для установления соединения
class ConnectEvent extends ConnectionEvent {
  const ConnectEvent();
}

/// Событие для разрыва соединения
class DisconnectEvent extends ConnectionEvent {
  const DisconnectEvent();
}

/// Событие для обновления статуса соединения
class ConnectionStatusEvent extends ConnectionEvent {
  /// Текущее состояние соединения
  final ws.ConnectionState connectionState;

  /// Сообщение об ошибке, если есть
  final String? errorMessage;

  const ConnectionStatusEvent({
    required this.connectionState,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [connectionState, errorMessage];
}

/// Событие для обработки ошибки соединения
class ConnectionErrorEvent extends ConnectionEvent {
  final String message;

  const ConnectionErrorEvent(this.message);

  @override
  List<Object?> get props => [message];
}
