import 'package:equatable/equatable.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_websocket_service.dart' as ws;

/// Состояния для ConnectionBloc
abstract class ConnectionBlocState extends Equatable {
  const ConnectionBlocState();

  @override
  List<Object?> get props => [];
}

/// Начальное состояние
class ConnectionInitial extends ConnectionBlocState {
  const ConnectionInitial();
}

/// Соединение устанавливается
class ConnectionConnecting extends ConnectionBlocState {
  const ConnectionConnecting();
}

/// Соединение установлено
class ConnectionEstablished extends ConnectionBlocState {
  const ConnectionEstablished();
}

/// Соединение потеряно
class ConnectionLost extends ConnectionBlocState {
  final String? message;

  const ConnectionLost({this.message});

  @override
  List<Object?> get props => [message];
}

/// Происходит переподключение
class ConnectionReconnecting extends ConnectionBlocState {
  final int attempt;
  final int maxAttempts;

  const ConnectionReconnecting({
    required this.attempt,
    required this.maxAttempts,
  });

  @override
  List<Object?> get props => [attempt, maxAttempts];
}

/// Ожидание восстановления сети
class ConnectionWaitingForNetwork extends ConnectionBlocState {
  const ConnectionWaitingForNetwork();
}

/// Ошибка соединения
class ConnectionError extends ConnectionBlocState {
  final String message;

  const ConnectionError(this.message);

  @override
  List<Object?> get props => [message];
}
