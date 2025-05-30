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
  ping,
  unknown,
}

/// Состояние подключения WebSocket
enum ConnectionState {
  connecting,
  connected,
  disconnected,
  reconnecting,
  waitingForNetwork,
  error,
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
      case 'ping':
      case 'pong':
        type = WebSocketEventType.ping;
        break;
      default:
        type = WebSocketEventType.unknown;
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
  
  factory WebSocketEventData.unknown(dynamic rawData) {
    return WebSocketEventData(
      type: WebSocketEventType.unknown,
      data: {'raw': rawData.toString()},
    );
  }
  
  @override
  String toString() {
    return 'WebSocketEventData{type: $type, data: $data${error != null ? ', error: $error' : ''}}';
  }
}

/// Интерфейс для WebSocketService для возможности мокинга в тестах
abstract class BaseWebSocketService {
  void connect();
  void disconnect();
  void setCurrentUsername(String username);
  void sendMessage({
    required int chatId,
    required String text,
    int? replyToId,
    int? forwardedFromId,
    List<Map<String, String>>? attachments,
  });
  void sendTyping({required int chatId, required bool isTyping});
  void readMessage({required int chatId, required int messageId});
  void editMessage({
    required int chatId,
    required int messageId,
    required String text,
  });
  Stream get stream;
  dynamic get channel;
}

/// Адаптер для существующего WebSocketService
class WebSocketServiceAdapter implements BaseWebSocketService {
  final WebSocketService _service;
  
  WebSocketServiceAdapter(this._service);
  
  @override
  void connect() => _service.connect();
  
  @override
  void disconnect() => _service.disconnect();
  
  @override
  void setCurrentUsername(String username) => _service.setCurrentUsername(username);
  
  @override
  void sendMessage({
    required int chatId,
    required String text,
    int? replyToId,
    int? forwardedFromId,
    List<Map<String, String>>? attachments,
  }) => _service.sendMessage(
    chatId: chatId,
    text: text,
    replyToId: replyToId,
    forwardedFromId: forwardedFromId,
    attachments: attachments,
  );
  
  @override
  void sendTyping({required int chatId, required bool isTyping}) =>
    _service.sendTyping(chatId: chatId, isTyping: isTyping);
  
  @override
  void readMessage({required int chatId, required int messageId}) =>
    _service.readMessage(chatId: chatId, messageId: messageId);
  
  @override
  void editMessage({
    required int chatId,
    required int messageId,
    required String text,
  }) => _service.editMessage(
    chatId: chatId,
    messageId: messageId,
    text: text,
  );
  
  @override
  Stream get stream => _service.stream;
  
  @override
  dynamic get channel => _service.channel;
}

/// Фабрика для создания экземпляров WebSocketService
class WebSocketServiceFactory {
  final SharedPrefsRepository _prefsRepository;
  
  WebSocketServiceFactory(this._prefsRepository);
  
  Future<BaseWebSocketService?> create() async {
    final token = await _prefsRepository.getAccessToken();
    if (token == null) return null;
    
    return WebSocketServiceAdapter(WebSocketService(jwtToken: token));
  }
}

/// Сервис для работы с WebSocket в чате с поддержкой автоматического переподключения
class ChatWebSocketService {
  final SharedPrefsRepository _prefsRepository;
  final WebSocketServiceFactory _serviceFactory;
  BaseWebSocketService? _webSocketService;
  
  // Параметры для переподключения
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _pingInterval = Duration(seconds: 30);
  static const Duration _pingTimeout = Duration(seconds: 10);
  
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  Timer? _pingTimeoutTimer;
  bool _isConnected = false;
  bool _isManuallyDisconnected = false;
  String? _currentUsername;
  bool _waitingForPingResponse = false;
  
  // Контроллер для транслирования событий
  final StreamController<WebSocketEventData> _eventsController = 
      StreamController<WebSocketEventData>.broadcast();

  /// Получение потока событий
  Stream<WebSocketEventData> get events => _eventsController.stream;

  /// Текущее состояние подключения
  ConnectionState _connectionState = ConnectionState.disconnected;
  ConnectionState get connectionState => _connectionState;

  /// Текущая попытка переподключения
  int get reconnectAttempt => _reconnectAttempts;
  
  /// Максимальное количество попыток переподключения
  int get maxReconnectAttempts => _maxReconnectAttempts;

  /// Конструктор
  ChatWebSocketService({
    required SharedPrefsRepository prefsRepository,
    WebSocketServiceFactory? serviceFactory,
  }) : _prefsRepository = prefsRepository,
       _serviceFactory = serviceFactory ?? WebSocketServiceFactory(prefsRepository);

  /// Установка имени текущего пользователя
  void setCurrentUsername(String username) {
    _currentUsername = username;
    _webSocketService?.setCurrentUsername(username);
  }

  /// Подключение к WebSocket серверу
  Future<bool> connect() async {
    if (_isConnected) return true;
    _isManuallyDisconnected = false;
    
    try {
      _updateConnectionState(ConnectionState.connecting);
      
      _webSocketService = await _serviceFactory.create();
      
      if (_webSocketService == null) {
        throw Exception('Не удалось создать WebSocketService');
      }
      
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
      
      return true;
    } catch (e) {
      _handleConnectionError('Ошибка подключения: ${e.toString()}');
      return false;
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
    _stopPingTimeoutTimer();
    _isConnected = false;
  }

  /// Обновление состояния подключения
  void _updateConnectionState(ConnectionState state) {
    if (_connectionState == state) return;
    
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
      _updateConnectionState(ConnectionState.waitingForNetwork);
      
      // После макс. количества попыток ждем дольше
      _stopReconnectTimer();
      _reconnectTimer = Timer(Duration(seconds: 60), () {
        _reconnectAttempts = 0;
        connect();
      });
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
  
  /// Запуск таймера ожидания ответа на пинг
  void _startPingTimeoutTimer() {
    _stopPingTimeoutTimer();
    _waitingForPingResponse = true;
    _pingTimeoutTimer = Timer(_pingTimeout, () {
      if (_waitingForPingResponse) {
        // Не получили ответ на пинг вовремя, соединение вероятно потеряно
        _handleConnectionError('Таймаут пинга: сервер не отвечает');
      }
    });
  }
  
  /// Остановка таймера ожидания ответа на пинг
  void _stopPingTimeoutTimer() {
    _pingTimeoutTimer?.cancel();
    _pingTimeoutTimer = null;
    _waitingForPingResponse = false;
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
        _startPingTimeoutTimer();
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
            try {
              final jsonData = jsonDecode(data) as Map<String, dynamic>;
              final event = WebSocketEventData.fromJson(jsonData);
              
              // Обработка пинга - сбрасываем таймер ожидания
              if (event.type == WebSocketEventType.ping) {
                _stopPingTimeoutTimer();
              }
              
              _eventsController.add(event);
            } catch (e) {
              _eventsController.add(
                WebSocketEventData.error('Ошибка разбора JSON: $e')
              );
              // Добавляем неразобранные данные как неизвестный тип
              _eventsController.add(WebSocketEventData.unknown(data));
            }
          } else if (data != null) {
            // Данные не в формате строки
            _eventsController.add(WebSocketEventData.unknown(data));
          }
        } catch (e) {
          _eventsController.add(
            WebSocketEventData.error('Ошибка обработки события: $e')
          );
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
    
    try {
      _webSocketService?.sendMessage(
        chatId: chatId,
        text: text,
        replyToId: replyToId,
        forwardedFromId: forwardedFromId,
        attachments: attachments,
      );
    } catch (e) {
      _handleConnectionError('Ошибка отправки сообщения: $e');
    }
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
    
    try {
      _webSocketService?.sendTyping(
        chatId: chatId,
        isTyping: isTyping,
      );
    } catch (e) {
      // При ошибке отправки статуса печати не обрываем соединение,
      // это некритичная ошибка
      _eventsController.add(
        WebSocketEventData.error('Ошибка отправки статуса печати: $e')
      );
    }
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
    
    try {
      _webSocketService?.readMessage(
        chatId: chatId,
        messageId: messageId,
      );
    } catch (e) {
      // При ошибке отметки прочтения не обрываем соединение,
      // это некритичная ошибка
      _eventsController.add(
        WebSocketEventData.error('Ошибка отметки сообщения как прочитанное: $e')
      );
    }
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
    
    try {
      _webSocketService?.editMessage(
        chatId: chatId,
        messageId: messageId,
        text: text,
      );
    } catch (e) {
      _handleConnectionError('Ошибка редактирования сообщения: $e');
    }
  }

  /// Переподключение и выполнение функции
  void _reconnectAndExecute(Function action) {
    if (_isManuallyDisconnected) {
      _eventsController.add(
        WebSocketEventData.error('Невозможно выполнить действие: соединение отключено')
      );
      return;
    }
    
    connect().then((success) {
      if (success && _isConnected) {
        action();
      } else {
        _eventsController.add(
          WebSocketEventData.error('Не удалось выполнить действие: соединение не установлено')
        );
      }
    });
  }

  /// Проверка состояния соединения
  bool isConnected() => _isConnected;

  /// Освобождение ресурсов
  void dispose() {
    _cleanupConnection();
    _eventsController.close();
  }
}
