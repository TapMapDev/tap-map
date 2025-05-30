import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/connection_bloc/connection_event.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/connection_bloc/connection_state.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_websocket_service.dart';

/// Блок для управления WebSocket-соединением и его состоянием
class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionBlocState> {
  final ChatWebSocketService _webSocketService;
  
  // Подписка на события WebSocket
  StreamSubscription<WebSocketEventData>? _subscription;

  /// Конструктор блока
  ConnectionBloc({
    required ChatWebSocketService webSocketService,
  }) : _webSocketService = webSocketService,
       super(ConnectionBlocState.initial()) {
    on<ConnectEvent>(_onConnect);
    on<DisconnectEvent>(_onDisconnect);
    on<ConnectionStatusEvent>(_onConnectionStatus);
    on<ConnectionErrorEvent>(_onConnectionError);
    
    // Подписываемся на события WebSocket
    _subscription = _webSocketService.events.listen(_handleWebSocketEvent);
    
    // Если уже подключено - обновляем состояние
    if (_webSocketService.connectionState == ConnectionState.connected) {
      add(ConnectionStatusEvent(connectionState: ConnectionState.connected));
    }
  }

  /// Обработка события подключения
  Future<void> _onConnect(
    ConnectEvent event,
    Emitter<ConnectionBlocState> emit,
  ) async {
    if (_webSocketService.connectionState == ConnectionState.connected) {
      emit(ConnectionBlocState.connected());
      return;
    }
    
    emit(ConnectionBlocState.connecting());
    
    final result = await _webSocketService.connect();
    if (!result) {
      emit(ConnectionBlocState.error('Не удалось установить соединение'));
    }
  }

  /// Обработка события отключения
  void _onDisconnect(
    DisconnectEvent event,
    Emitter<ConnectionBlocState> emit,
  ) {
    _webSocketService.disconnect();
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
        emit(ConnectionBlocState.reconnecting(
          attempt: _webSocketService.reconnectAttempt,
          maxAttempts: _webSocketService.maxReconnectAttempts,
        ));
        break;
      case ConnectionState.waitingForNetwork:
        emit(ConnectionBlocState.waitingForNetwork());
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
    // так как ChatWebSocketService делает это автоматически
  }

  /// Обработка событий от WebSocketService
  void _handleWebSocketEvent(WebSocketEventData event) {
    if (event.type == WebSocketEventType.connection) {
      final connectionStateStr = event.data['state'] as String;
      final connectionState = _parseConnectionState(connectionStateStr);
      
      add(ConnectionStatusEvent(connectionState: connectionState));
    } else if (event.type == WebSocketEventType.error && event.error != null) {
      add(ConnectionErrorEvent(event.error!));
    }
  }

  /// Преобразование строки состояния в enum
  ConnectionState _parseConnectionState(String stateStr) {
    final parts = stateStr.split('.');
    if (parts.length == 2 && parts[0] == 'ConnectionState') {
      switch (parts[1]) {
        case 'connected':
          return ConnectionState.connected;
        case 'connecting':
          return ConnectionState.connecting;
        case 'disconnected':
          return ConnectionState.disconnected;
        case 'reconnecting':
          return ConnectionState.reconnecting;
        case 'waitingForNetwork':
          return ConnectionState.waitingForNetwork;
      }
    }
    return ConnectionState.disconnected;
  }

  /// Освобождение ресурсов
  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
