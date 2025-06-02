import 'dart:async';
import 'dart:convert';
import 'dart:math'; // Добавляем импорт для функции min

import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  final Map<String, dynamic>? data;
  final String? error;

  WebSocketEventData({
    required this.type,
    this.data,
    this.error,
  });

  factory WebSocketEventData.fromJson(Map<String, dynamic> json) {
    final eventType = json['type'] as String?;
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
      data: {
        'state': state.toString(),
      },
    );
  }

  factory WebSocketEventData.error(String errorMessage) {
    return WebSocketEventData(
      type: WebSocketEventType.error,
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

/// Сервис для работы с WebSocket в чате с поддержкой автоматического переподключения
class ChatWebSocketService {
  final SharedPrefsRepository _prefsRepository;
  WebSocketChannel? _channel;
  Stream? _broadcastStream;
  
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
  }) : _prefsRepository = prefsRepository;

  /// Установка имени текущего пользователя
  void setCurrentUsername(String username) {
    _currentUsername = username;
  }

  /// Подключение к WebSocket серверу
  Future<bool> connect() async {
    if (_isConnected) return true;
    _isManuallyDisconnected = false;
    
    try {
      print('🌐 WebSocket: Начинаем подключение...');
      _updateConnectionState(ConnectionState.connecting);
      
      final jwtToken = await _prefsRepository.getAccessToken();
      
      // Выводим первые и последние 10 символов токена для отладки
      if (jwtToken != null && jwtToken.isNotEmpty) {
        final visibleToken = jwtToken.length > 20 
            ? '${jwtToken.substring(0, 10)}...${jwtToken.substring(jwtToken.length - 10)}'
            : jwtToken;
        print('🌐 WebSocket: JWT токен получен: $visibleToken');
      } else {
        print('🌐 WebSocket: ОШИБКА - JWT токен пустой или null');
      }
      
      if (jwtToken == null || jwtToken.isEmpty) {
        print('🌐 WebSocket: Ошибка - JWT токен пустой или null');
        _handleConnectionError('JWT token is empty or null');
        return false;
      }
      
      final wsUrl = 'wss://api.tap-map.net/ws/notifications/';
      print('🌐 WebSocket: Пытаемся подключиться к $wsUrl');
      
      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );
      
      print('🌐 WebSocket: Канал создан, получаем broadcast stream...');
      _broadcastStream = _channel!.stream.asBroadcastStream();
      
      // Подписываемся на события
      _subscribeToEvents();
      
      _isConnected = true;
      print('🌐 WebSocket: Соединение установлено успешно!');
      _updateConnectionState(ConnectionState.connected);
      
      // Запускаем таймер пинга для поддержания соединения
      _startPingTimer();
      
      return true;
    } catch (e) {
      print('🌐 WebSocket: КРИТИЧЕСКАЯ ОШИБКА подключения: $e');
      _handleConnectionError(e.toString());
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
    _isConnected = false;
    _stopPingTimer();
    _stopPingTimeoutTimer();
    _stopReconnectTimer();
    
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
  }

  /// Обновление состояния подключения
  void _updateConnectionState(ConnectionState state) {
    _connectionState = state;
    _eventsController.add(WebSocketEventData.connectionEvent(state));
  }

  /// Попытка переподключения
  void _attemptReconnect() {
    if (_isManuallyDisconnected) return;
    
    _reconnectAttempts++;
    _updateConnectionState(ConnectionState.reconnecting);
    
    if (_reconnectAttempts > _maxReconnectAttempts) {
      _updateConnectionState(ConnectionState.error);
      _eventsController.add(
        WebSocketEventData.error('Превышено максимальное количество попыток переподключения')
      );
      return;
    }
    
    connect().then((success) {
      if (!success && !_isManuallyDisconnected) {
        _reconnectTimer = Timer(_reconnectDelay, _attemptReconnect);
      } else {
        _reconnectAttempts = 0;
      }
    });
  }

  /// Остановка таймера переподключения
  void _stopReconnectTimer() {
    if (_reconnectTimer != null) {
      _reconnectTimer!.cancel();
      _reconnectTimer = null;
    }
  }

  /// Запуск таймера пинга
  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(_pingInterval, (_) => _sendPing());
  }

  /// Остановка таймера пинга
  void _stopPingTimer() {
    if (_pingTimer != null) {
      _pingTimer!.cancel();
      _pingTimer = null;
    }
  }

  /// Запуск таймера ожидания ответа на пинг
  void _startPingTimeoutTimer() {
    _stopPingTimeoutTimer();
    _pingTimeoutTimer = Timer(_pingTimeout, () {
      if (_waitingForPingResponse) {
        print('🌐 WebSocket: ТАЙМ-АУТ ПИНГА! Не получили ответ за $_pingTimeout сек');
        _waitingForPingResponse = false;
        _cleanupConnection();
        _attemptReconnect();
      }
    });
  }

  /// Остановка таймера ожидания ответа на пинг
  void _stopPingTimeoutTimer() {
    if (_pingTimeoutTimer != null) {
      _pingTimeoutTimer!.cancel();
      _pingTimeoutTimer = null;
    }
  }

  /// Отправка пинга для поддержания соединения
  void _sendPing() {
    if (!_isConnected || _channel == null) {
      print('🌐 WebSocket: Не отправляем пинг, т.к. соединение неактивно');
      return;
    }
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final jsonMessage = jsonEncode({
        'type': 'ping',
        'timestamp': timestamp,
      });
      
      print('🌐 WebSocket: Отправляем пинг с timestamp=$timestamp');
      _channel!.sink.add(jsonMessage);
      _waitingForPingResponse = true;
      print('🌐 WebSocket: Запускаем таймер ожидания ответа на пинг ($_pingTimeout сек)');
      _startPingTimeoutTimer();
    } catch (e) {
      print('🌐 WebSocket: Ошибка отправки пинга: $e');
      _handleConnectionError('Ошибка отправки пинга: $e');
    }
  }

  /// Подписка на события WebSocket
  void _subscribeToEvents() {
    if (_broadcastStream == null) {
      print('🌐 WebSocket: _broadcastStream is null, невозможно подписаться на события');
      return;
    }
    
    print('🌐 WebSocket: Подписываемся на события...');
    _broadcastStream!.listen(
      (data) {
        try {
          final shortData = data.toString().length > 100 
              ? '${data.toString().substring(0, min(100, data.toString().length))}...' 
              : data.toString();
          print('🌐 WebSocket: Получено событие: $shortData');
          
          if (data is String) {
            try {
              final jsonData = jsonDecode(data) as Map<String, dynamic>;
              final event = WebSocketEventData.fromJson(jsonData);
              
              print('🌐 WebSocket: Событие обработано как ${event.type}');
              
              // Сбрасываем ожидание ответа на пинг, если пришел pong
              if (event.type == WebSocketEventType.ping) {
                print('🌐 WebSocket: Получен ответ на пинг (pong)');
                _waitingForPingResponse = false;
                _stopPingTimeoutTimer();
              }
              
              _eventsController.add(event);
            } catch (e) {
              print('🌐 WebSocket: Ошибка разбора JSON: $e, данные: ${data.toString()}');
              _eventsController.add(
                WebSocketEventData.error('Ошибка разбора JSON: $e')
              );
            }
          } else {
            print('🌐 WebSocket: Получены не-строковые данные: ${data.runtimeType}');
            _eventsController.add(WebSocketEventData.unknown(data));
          }
        } catch (e) {
          print('🌐 WebSocket: Ошибка обработки события: $e');
          _eventsController.add(
            WebSocketEventData.error('Ошибка обработки события: $e')
          );
        }
      },
      onError: (error) {
        print('🌐 WebSocket: КРИТИЧЕСКАЯ ОШИБКА соединения: $error');
        _eventsController.add(WebSocketEventData.error(error.toString()));
        _cleanupConnection();
        _attemptReconnect();
      },
      onDone: () {
        print('🌐 WebSocket: Соединение закрыто');
        if (!_isManuallyDisconnected) {
          print('🌐 WebSocket: Пытаемся переподключиться после закрытия...');
          _cleanupConnection();
          _attemptReconnect();
        }
      },
    );
  }

  /// Обработка ошибки соединения
  void _handleConnectionError(String error) {
    print('🌐 WebSocket: Обрабатываем ошибку соединения: $error');
    _cleanupConnection();
    _updateConnectionState(ConnectionState.error);
    _eventsController.add(WebSocketEventData.error(error));
    
    if (!_isManuallyDisconnected) {
      print('🌐 WebSocket: Запланировано переподключение через $_reconnectDelay');
      _reconnectTimer = Timer(_reconnectDelay, _attemptReconnect);
    }
  }

  /// Отправка сообщения
  void sendMessage({
    required int chatId,
    required String text,
    int? replyToId,
    int? forwardedFromId,
    List<Map<String, String>>? attachments,
  }) {
    _reconnectAndExecute(() {
      final message = {
        'type': 'create_message',
        'chat_id': chatId,
        'text': text,
        if (replyToId != null) 'reply_to_id': replyToId,
        if (forwardedFromId != null) 'forwarded_from_id': forwardedFromId,
        if (attachments != null && attachments.isNotEmpty)
          'attachments': attachments,
      };
      
      _channel!.sink.add(jsonEncode(message));
    });
  }

  /// Отправка статуса печати
  void sendTyping({
    required int chatId,
    required bool isTyping,
  }) {
    _reconnectAndExecute(() {
      final jsonMessage = jsonEncode({
        'type': 'typing',
        'chat_id': chatId,
        'is_typing': isTyping,
      });
      
      _channel!.sink.add(jsonMessage);
    });
  }

  /// Отметка сообщения как прочитанное
  void readMessage({
    required int chatId,
    required int messageId,
  }) {
    _reconnectAndExecute(() {
      final jsonMessage = jsonEncode({
        'type': 'read_message',
        'chat_id': chatId,
        'message_id': messageId,
      });
      
      _channel!.sink.add(jsonMessage);
    });
  }

  /// Редактирование сообщения
  void editMessage({
    required int chatId,
    required int messageId,
    required String text,
  }) {
    _reconnectAndExecute(() {
      final jsonMessage = jsonEncode({
        'type': 'edit_message',
        'chat_id': chatId,
        'message_id': messageId,
        'text': text,
        'edited_at': DateTime.now().toIso8601String(),
      });
      
      _channel!.sink.add(jsonMessage);
    });
  }

  /// Переподключение и выполнение функции
  void _reconnectAndExecute(Function action) {
    if (!_isConnected || _channel == null) {
      connect().then((success) {
        if (success) {
          action();
        }
      });
      return;
    }
    
    try {
      action();
    } catch (e) {
      _handleConnectionError('Ошибка при выполнении действия: $e');
      connect().then((success) {
        if (success) {
          action();
        }
      });
    }
  }

  /// Проверка состояния соединения
  bool isConnected() {
    return _isConnected && _channel != null;
  }

  /// Освобождение ресурсов
  void dispose() {
    _cleanupConnection();
    _eventsController.close();
  }
}
