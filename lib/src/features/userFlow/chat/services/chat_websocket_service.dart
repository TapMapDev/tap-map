import 'dart:async';
import 'dart:convert';

import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/core/websocket/websocket_service.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

/// Типы событий WebSocket
enum WebSocketEventType {
  message,
  typing,
  readMessage,
  userStatus,
  error,
  connection,
}

/// Состояние подключения WebSocket
enum ConnectionState {
  connecting,
  connected,
  disconnected,
  reconnecting,
}

/// Данные события WebSocket
class WebSocketEventData {
  final WebSocketEventType type;
  final Map<String, dynamic> data;
  final String? error;

  WebSocketEventData({
    required this.type,
    required this.data,
    this.error,
  });

  factory WebSocketEventData.fromJson(Map<String, dynamic> json) {
    final String? eventType = json['event'];
    WebSocketEventType type;
    
    switch (eventType) {
      case 'message':
        type = WebSocketEventType.message;
        break;
      case 'typing':
        type = WebSocketEventType.typing;
        break;
      case 'read_message':
        type = WebSocketEventType.readMessage;
        break;
      case 'user_status':
        type = WebSocketEventType.userStatus;
        break;
      default:
        type = WebSocketEventType.error;
    }
    
    return WebSocketEventData(
      type: type,
      data: json,
    );
  }

  factory WebSocketEventData.connectionEvent(ConnectionState state) {
    return WebSocketEventData(
      type: WebSocketEventType.connection,
      data: {'state': state.toString()},
    );
  }

  factory WebSocketEventData.error(String errorMessage) {
    return WebSocketEventData(
      type: WebSocketEventType.error,
      data: {},
      error: errorMessage,
    );
  }
}

/// Сервис для работы с WebSocket в чате с поддержкой автоматического переподключения
class ChatWebSocketService {
  final SharedPrefsRepository _prefsRepository;
  WebSocketService? _webSocketService;
  
  // Параметры для переподключения
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _pingInterval = Duration(seconds: 30);
  
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnected = false;
  bool _isManuallyDisconnected = false;
  String? _currentUsername;
  
  // Контроллер для транслирования событий
  final StreamController<WebSocketEventData> _eventsController = 
      StreamController<WebSocketEventData>.broadcast();

  /// Получение потока событий
  Stream<WebSocketEventData> get events => _eventsController.stream;

  /// Текущее состояние подключения
  ConnectionState _connectionState = ConnectionState.disconnected;
  ConnectionState get connectionState => _connectionState;

  /// Конструктор
  ChatWebSocketService({
    required SharedPrefsRepository prefsRepository,
  }) : _prefsRepository = prefsRepository;

  /// Установка имени текущего пользователя
  void setCurrentUsername(String username) {
    _currentUsername = username;
    _webSocketService?.setCurrentUsername(username);
  }

  /// Подключение к WebSocket серверу
  Future<void> connect() async {
    if (_isConnected) return;
    _isManuallyDisconnected = false;
    
    try {
      _updateConnectionState(ConnectionState.connecting);
      
      final token = await _prefsRepository.getAccessToken();
      if (token == null) {
        throw Exception('Нет доступного токена доступа');
      }
      
      _webSocketService = WebSocketService(jwtToken: token);
      _webSocketService!.connect();
      
      if (_currentUsername != null) {
        _webSocketService!.setCurrentUsername(_currentUsername!);
      }
      
      // Подписываемся на события базового WebSocketService
      _subscribeToEvents();
      
      // Запускаем пинг для поддержания соединения
      _startPingTimer();
      
      _isConnected = true;
      _reconnectAttempts = 0;
      _updateConnectionState(ConnectionState.connected);
      
    } catch (e) {
      _handleConnectionError(e.toString());
    }
  }

  /// Отключение от WebSocket сервера
  void disconnect() {
    _isManuallyDisconnected = true;
    _cleanupConnection();
    _updateConnectionState(ConnectionState.disconnected);
  }

  /// Очистка ресурсов соединения
  void _cleanupConnection() {
    _webSocketService?.disconnect();
    _webSocketService = null;
    _stopReconnectTimer();
    _stopPingTimer();
    _isConnected = false;
  }

  /// Обновление состояния подключения
  void _updateConnectionState(ConnectionState state) {
    _connectionState = state;
    _eventsController.add(WebSocketEventData.connectionEvent(state));
  }

  /// Попытка переподключения
  void _attemptReconnect() {
    if (_isManuallyDisconnected) return;
    
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _eventsController.add(
        WebSocketEventData.error('Превышено максимальное количество попыток переподключения')
      );
      _updateConnectionState(ConnectionState.disconnected);
      return;
    }
    
    _reconnectAttempts++;
    _updateConnectionState(ConnectionState.reconnecting);
    
    _stopReconnectTimer();
    _reconnectTimer = Timer(_reconnectDelay, () {
      connect();
    });
  }

  /// Остановка таймера переподключения
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Запуск таймера пинга
  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      _sendPing();
    });
  }

  /// Остановка таймера пинга
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// Отправка пинга для поддержания соединения
  void _sendPing() {
    try {
      if (_webSocketService != null && _isConnected) {
        // В текущей реализации нет явного метода для пинга,
        // поэтому можно использовать простой тип сообщения
        final ping = jsonEncode({
          'type': 'ping',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        
        _webSocketService!.channel.sink.add(ping);
      }
    } catch (e) {
      _handleConnectionError('Ошибка отправки пинга: $e');
    }
  }

  /// Подписка на события базового WebSocketService
  void _subscribeToEvents() {
    _webSocketService?.stream.listen(
      (data) {
        try {
          if (data is String) {
            final jsonData = jsonDecode(data) as Map<String, dynamic>;
            final event = WebSocketEventData.fromJson(jsonData);
            _eventsController.add(event);
          }
        } catch (e) {
          _eventsController.add(WebSocketEventData.error('Ошибка обработки события: $e'));
        }
      },
      onError: (error) {
        _handleConnectionError('Ошибка соединения: $error');
      },
      onDone: () {
        if (!_isManuallyDisconnected) {
          _isConnected = false;
          _attemptReconnect();
        }
      },
    );
  }

  /// Обработка ошибки соединения
  void _handleConnectionError(String error) {
    _isConnected = false;
    _eventsController.add(WebSocketEventData.error(error));
    _attemptReconnect();
  }

  /// Отправка сообщения
  void sendMessage({
    required int chatId,
    required String text,
    int? replyToId,
    int? forwardedFromId,
    List<Map<String, String>>? attachments,
  }) {
    if (!_isConnected) {
      _reconnectAndExecute(() => sendMessage(
        chatId: chatId,
        text: text,
        replyToId: replyToId,
        forwardedFromId: forwardedFromId,
        attachments: attachments,
      ));
      return;
    }
    
    _webSocketService?.sendMessage(
      chatId: chatId,
      text: text,
      replyToId: replyToId,
      forwardedFromId: forwardedFromId,
      attachments: attachments,
    );
  }

  /// Отправка статуса печати
  void sendTyping({
    required int chatId,
    required bool isTyping,
  }) {
    if (!_isConnected) {
      _reconnectAndExecute(() => sendTyping(
        chatId: chatId, 
        isTyping: isTyping,
      ));
      return;
    }
    
    _webSocketService?.sendTyping(
      chatId: chatId,
      isTyping: isTyping,
    );
  }

  /// Отметка сообщения как прочитанное
  void readMessage({
    required int chatId,
    required int messageId,
  }) {
    if (!_isConnected) {
      _reconnectAndExecute(() => readMessage(
        chatId: chatId, 
        messageId: messageId,
      ));
      return;
    }
    
    _webSocketService?.readMessage(
      chatId: chatId,
      messageId: messageId,
    );
  }

  /// Редактирование сообщения
  void editMessage({
    required int chatId,
    required int messageId,
    required String text,
  }) {
    if (!_isConnected) {
      _reconnectAndExecute(() => editMessage(
        chatId: chatId, 
        messageId: messageId, 
        text: text,
      ));
      return;
    }
    
    _webSocketService?.editMessage(
      chatId: chatId,
      messageId: messageId,
      text: text,
    );
  }

  /// Переподключение и выполнение функции
  void _reconnectAndExecute(Function action) {
    if (_isManuallyDisconnected) {
      _eventsController.add(
        WebSocketEventData.error('Невозможно выполнить действие: соединение отключено')
      );
      return;
    }
    
    connect().then((_) {
      if (_isConnected) {
        action();
      }
    });
  }

  /// Освобождение ресурсов
  void dispose() {
    _cleanupConnection();
    _eventsController.close();
  }
}
