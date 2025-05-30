import 'package:equatable/equatable.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_websocket_service.dart';

/// Состояние блока соединения
class ConnectionBlocState extends Equatable {
  /// Текущее состояние соединения
  final ConnectionState state;
  
  /// Сообщение об ошибке или дополнительная информация
  final String? message;
  
  /// Текущая попытка переподключения (если применимо)
  final int? reconnectAttempt;
  
  /// Максимальное количество попыток переподключения (если применимо)
  final int? maxReconnectAttempts;

  const ConnectionBlocState({
    required this.state,
    this.message,
    this.reconnectAttempt,
    this.maxReconnectAttempts,
  });

  /// Начальное состояние
  factory ConnectionBlocState.initial() => const ConnectionBlocState(
    state: ConnectionState.disconnected,
  );

  /// Состояние подключения
  factory ConnectionBlocState.connecting() => const ConnectionBlocState(
    state: ConnectionState.connecting,
  );

  /// Состояние успешного подключения
  factory ConnectionBlocState.connected() => const ConnectionBlocState(
    state: ConnectionState.connected,
  );

  /// Состояние отключения с опциональным сообщением
  factory ConnectionBlocState.disconnected({String? message}) => ConnectionBlocState(
    state: ConnectionState.disconnected,
    message: message,
  );

  /// Состояние переподключения с информацией о попытках
  factory ConnectionBlocState.reconnecting({
    required int attempt,
    required int maxAttempts,
  }) => ConnectionBlocState(
    state: ConnectionState.reconnecting,
    reconnectAttempt: attempt,
    maxReconnectAttempts: maxAttempts,
  );

  /// Состояние ожидания восстановления сети
  factory ConnectionBlocState.waitingForNetwork() => const ConnectionBlocState(
    state: ConnectionState.waitingForNetwork,
  );

  /// Состояние ошибки с сообщением
  factory ConnectionBlocState.error(String message) => ConnectionBlocState(
    state: ConnectionState.disconnected,
    message: message,
  );

  /// Создание нового состояния с обновленными параметрами
  ConnectionBlocState copyWith({
    ConnectionState? state,
    String? message,
    int? reconnectAttempt,
    int? maxReconnectAttempts,
  }) {
    return ConnectionBlocState(
      state: state ?? this.state,
      message: message ?? this.message,
      reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
      maxReconnectAttempts: maxReconnectAttempts ?? this.maxReconnectAttempts,
    );
  }

  @override
  List<Object?> get props => [state, message, reconnectAttempt, maxReconnectAttempts];
}
