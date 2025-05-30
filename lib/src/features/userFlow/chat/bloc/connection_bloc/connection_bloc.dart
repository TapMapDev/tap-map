import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/connection_bloc/connection_event.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/connection_bloc/connection_state.dart';
import 'package:tap_map/src/features/userFlow/chat/data/chat_repository.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_websocket_service.dart';

/// Блок для управления WebSocket-соединением и его состоянием
class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionBlocState> {
  final ChatRepository _chatRepository;
  
  // Подписка на события WebSocket
  StreamSubscription<WebSocketEventData>? _subscription;

  /// Конструктор блока
  ConnectionBloc({
    required ChatRepository chatRepository,
  }) : _chatRepository = chatRepository,
       super(ConnectionBlocState.initial()) {
    on<ConnectEvent>(_onConnect);
    on<DisconnectEvent>(_onDisconnect);
    on<ConnectionStatusEvent>(_onConnectionStatus);
    on<ConnectionErrorEvent>(_onConnectionError);
    
    // Подписываемся на события WebSocket через репозиторий
    _subscription = _chatRepository.webSocketEvents.listen(_handleWebSocketEvent);
    
    // Если уже подключено - обновляем состояние
    final currentState = _chatRepository.currentConnectionState;
    if (currentState == ConnectionState.connected) {
      add(ConnectionStatusEvent(connectionState: ConnectionState.connected));
    }
  }

  /// Обработка события подключения
  Future<void> _onConnect(
    ConnectEvent event,
    Emitter<ConnectionBlocState> emit,
  ) async {
    if (_chatRepository.currentConnectionState == ConnectionState.connected) {
      emit(ConnectionBlocState.connected());
      return;
    }
    
    emit(ConnectionBlocState.connecting());
    
    final result = await _chatRepository.connectToChat();
    if (!result) {
      emit(ConnectionBlocState.error('Не удалось установить соединение'));
    }
  }

  /// Обработка события отключения
  void _onDisconnect(
    DisconnectEvent event,
    Emitter<ConnectionBlocState> emit,
  ) {
    _chatRepository.disconnectFromChat();
    emit(ConnectionBlocState.initial());
  }

  /// Обработка события изменения статуса соединения
  void _onConnectionStatus(
    ConnectionStatusEvent event,
    Emitter<ConnectionBlocState> emit,
  ) {
    switch (event.connectionState) {
      case ConnectionState.connected:
        emit(ConnectionBlocState.connected());
        break;
      case ConnectionState.connecting:
        emit(ConnectionBlocState.connecting());
        break;
      case ConnectionState.disconnected:
        emit(ConnectionBlocState.disconnected(message: event.errorMessage));
        break;
      case ConnectionState.reconnecting:
        final webSocketService = _chatRepository.webSocketService;
        emit(ConnectionBlocState.reconnecting(
          attempt: webSocketService.reconnectAttempt,
          maxAttempts: webSocketService.maxReconnectAttempts,
        ));
        break;
      case ConnectionState.waitingForNetwork:
        emit(ConnectionBlocState.waitingForNetwork());
        break;
      case ConnectionState.error:
        emit(ConnectionBlocState.error(event.errorMessage ?? 'Неизвестная ошибка'));
        break;
    }
  }

  /// Обработка события ошибки соединения
  void _onConnectionError(
    ConnectionErrorEvent event,
    Emitter<ConnectionBlocState> emit,
  ) {
    emit(ConnectionBlocState.error(event.message));
    
    // Не инициируем переподключение самостоятельно,
    // так как ChatRepository и ChatWebSocketService делают это автоматически
  }

  /// Обработка событий от WebSocketService
  void _handleWebSocketEvent(WebSocketEventData event) {
    if (event.type == WebSocketEventType.connection) {
      // Получаем состояние напрямую из данных события
      final connectionState = event.data['connectionState'] as ConnectionState? ?? 
                              ConnectionState.disconnected;
      
      add(ConnectionStatusEvent(connectionState: connectionState));
    } else if (event.type == WebSocketEventType.error && event.error != null) {
      add(ConnectionErrorEvent(event.error!));
    }
  }

  /// Освобождение ресурсов
  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
