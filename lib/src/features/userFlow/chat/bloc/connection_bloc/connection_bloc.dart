import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/connection_bloc/connection_event.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/connection_bloc/connection_state.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_websocket_service.dart' as ws;

/// Блок для управления WebSocket-соединением и его состоянием
class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionBlocState> {
  final ws.ChatWebSocketService _webSocketService;
  
  // Подписка на события WebSocket
  StreamSubscription<ws.WebSocketEventData>? _subscription;

  /// Конструктор блока
  ConnectionBloc({
    required ws.ChatWebSocketService webSocketService,
  }) : _webSocketService = webSocketService,
       super(const ConnectionInitial()) {
    on<ConnectEvent>(_onConnect);
    on<DisconnectEvent>(_onDisconnect);
    on<ConnectionStatusEvent>(_onConnectionStatus);
    on<ConnectionErrorEvent>(_onConnectionError);
    
    // Подписываемся на события WebSocket
    _subscription = _webSocketService.events.listen(_handleWebSocketEvent);
    
    // Если уже подключено - обновляем состояние
    if (_webSocketService.connectionState == ws.ConnectionState.connected) {
      add(ConnectionStatusEvent(connectionState: ws.ConnectionState.connected));
    }
  }

  /// Обработка события подключения
  Future<void> _onConnect(
    ConnectEvent event,
    Emitter<ConnectionBlocState> emit,
  ) async {
    if (_webSocketService.connectionState == ws.ConnectionState.connected) {
      emit(const ConnectionEstablished());
      return;
    }
    
    emit(const ConnectionConnecting());
    
    final result = await _webSocketService.connect();
    if (!result) {
      emit(const ConnectionError('Не удалось установить соединение'));
    }
  }

  /// Обработка события отключения
  void _onDisconnect(
    DisconnectEvent event,
    Emitter<ConnectionBlocState> emit,
  ) {
    _webSocketService.disconnect();
    emit(const ConnectionInitial());
  }

  /// Обработка события изменения статуса соединения
  void _onConnectionStatus(
    ConnectionStatusEvent event,
    Emitter<ConnectionBlocState> emit,
  ) {
    switch (event.connectionState) {
      case ws.ConnectionState.connected:
        emit(const ConnectionEstablished());
        break;
      case ws.ConnectionState.connecting:
        emit(const ConnectionConnecting());
        break;
      case ws.ConnectionState.disconnected:
        emit(const ConnectionLost(message: event.errorMessage));
        break;
      case ws.ConnectionState.reconnecting:
        // Получаем информацию о попытках из сервиса
        emit(ConnectionReconnecting(
          attempt: _webSocketService.reconnectAttempt,
          maxAttempts: _webSocketService.maxReconnectAttempts,
        ));
        break;
      case ws.ConnectionState.waitingForNetwork:
        emit(const ConnectionWaitingForNetwork());
        break;
    }
  }

  /// Обработка события ошибки соединения
  void _onConnectionError(
    ConnectionErrorEvent event,
    Emitter<ConnectionBlocState> emit,
  ) {
    emit(ConnectionError(event.message));
    
    // Не инициируем переподключение самостоятельно,
    // так как ChatWebSocketService делает это автоматически
  }

  /// Обработка событий от WebSocketService
  void _handleWebSocketEvent(ws.WebSocketEventData event) {
    if (event.type == ws.WebSocketEventType.connection) {
      final connectionStateStr = event.data['state'] as String;
      final connectionState = _parseConnectionState(connectionStateStr);
      
      add(ConnectionStatusEvent(connectionState: connectionState));
    } else if (event.type == ws.WebSocketEventType.error && event.error != null) {
      add(ConnectionErrorEvent(event.error!));
    }
  }

  /// Преобразование строки состояния в enum
  ws.ConnectionState _parseConnectionState(String stateStr) {
    final parts = stateStr.split('.');
    if (parts.length == 2 && parts[0] == 'ConnectionState') {
      switch (parts[1]) {
        case 'connected':
          return ws.ConnectionState.connected;
        case 'connecting':
          return ws.ConnectionState.connecting;
        case 'disconnected':
          return ws.ConnectionState.disconnected;
        case 'reconnecting':
          return ws.ConnectionState.reconnecting;
        case 'waitingForNetwork':
          return ws.ConnectionState.waitingForNetwork;
      }
    }
    return ws.ConnectionState.disconnected;
  }

  /// Освобождение ресурсов
  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
