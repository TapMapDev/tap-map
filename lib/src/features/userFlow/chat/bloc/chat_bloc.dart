import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/core/websocket/websocket_service.dart';
import 'package:tap_map/src/features/userFlow/user_profile/data/user_repository.dart';

import '../data/chat_repository.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'chat_event.dart' as events;
import 'chat_state.dart' as states;

class ChatBloc extends Bloc<events.ChatEvent, states.ChatState> {
  final ChatRepository _chatRepository;
  final SharedPrefsRepository _prefsRepository;
  final UserRepository _userRepository;
  WebSocketService? _webSocketService;
  StreamSubscription? _wsSubscription;
  int? _currentUserId;
  String? _currentUsername;

  ChatBloc({
    required ChatRepository chatRepository,
    required SharedPrefsRepository prefsRepository,
  })  : _chatRepository = chatRepository,
        _prefsRepository = prefsRepository,
        _userRepository = GetIt.instance<UserRepository>(),
        super(states.ChatInitial()) {
    on<events.FetchChats>(_onFetchChats);
    on<events.FetchChatById>(_onFetchChatById);
    on<events.SendMessage>(_onSendMessage);
    on<events.SendTyping>(_onSendTyping);
    on<events.MarkMessageAsRead>(_onMarkMessageAsRead);
    on<events.TogglePinChat>(_onTogglePinChat);
    on<events.NewMessageEvent>(_onNewMessage);
    on<events.UserTypingEvent>(_onUserTyping);
    on<events.ChatErrorEvent>(_onChatError);
    on<events.ConnectToChat>(_onConnectToChat);
    on<events.DisconnectFromChat>(_onDisconnectFromChat);
  }

  Future<void> _onFetchChats(
      events.FetchChats event, Emitter<states.ChatState> emit) async {
    try {
      emit(states.ChatLoading());
      final chats = await _chatRepository.fetchChats();
      emit(states.ChatsLoaded(chats));
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  Future<void> _onFetchChatById(
    events.FetchChatById event,
    Emitter<states.ChatState> emit,
  ) async {
    try {
      emit(states.ChatLoading());
      final data = await _chatRepository.fetchChatWithMessages(event.chatId);
      emit(states.ChatLoaded(
        chat: data['chat'] as ChatModel,
        messages: data['messages'] as List<MessageModel>,
      ));
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  Future<void> _onConnectToChat(
    events.ConnectToChat event,
    Emitter<states.ChatState> emit,
  ) async {
    try {
      final token = await _prefsRepository.getAccessToken();
      if (token == null) {
        emit(const states.ChatError('No access token available'));
        return;
      }

      final user = await _userRepository.getCurrentUser();
      _currentUserId = user.id;
      _currentUsername = user.username;

      _webSocketService = WebSocketService(jwtToken: token);
      _webSocketService!.connect();

      await _wsSubscription?.cancel();
      _wsSubscription = _webSocketService!.stream.listen(
        (data) {
          add(events.NewMessageEvent(data));
        },
        onError: (error) {
          add(events.ChatErrorEvent(error.toString()));
        },
      );

      emit(states.ChatConnected());
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  void _onDisconnectFromChat(
    events.DisconnectFromChat event,
    Emitter<states.ChatState> emit,
  ) {
    _wsSubscription?.cancel();
    _webSocketService?.disconnect();
    _webSocketService = null;
    emit(states.ChatDisconnected());
  }

  Future<void> _onSendMessage(
    events.SendMessage event,
    Emitter<states.ChatState> emit,
  ) async {
    try {
      if (_webSocketService == null) {
        emit(const states.ChatError('Not connected to chat'));
        return;
      }

      _webSocketService!.sendMessage(
        chatId: event.chatId,
        text: event.text,
        replyToId: event.replyToId,
        forwardedFromId: event.forwardedFromId,
      );

      emit(states.MessageSent(MessageModel(
        id: DateTime.now().millisecondsSinceEpoch,
        chatId: event.chatId,
        text: event.text,
        senderUsername: _currentUsername ?? 'Unknown',
        createdAt: DateTime.now(),
        replyToId: event.replyToId,
        forwardedFromId: event.forwardedFromId,
        status: MessageStatus.sent,
        type: MessageType.text,
      )));
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  void _onSendTyping(
    events.SendTyping event,
    Emitter<states.ChatState> emit,
  ) {
    try {
      if (_webSocketService == null) {
        emit(const states.ChatError('Not connected to chat'));
        return;
      }

      _webSocketService!.sendTyping(
        chatId: event.chatId,
        isTyping: event.isTyping,
      );
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  Future<void> _onMarkMessageAsRead(
    events.MarkMessageAsRead event,
    Emitter<states.ChatState> emit,
  ) async {
    try {
      await _chatRepository.markChatAsRead(event.chatId);
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  Future<void> _onTogglePinChat(
    events.TogglePinChat event,
    Emitter<states.ChatState> emit,
  ) async {
    try {
      // TODO: Implement pin/unpin functionality
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  void _onNewMessage(
      events.NewMessageEvent event, Emitter<states.ChatState> emit) {
    try {
      final message = MessageModel.fromJson(event.message);
      emit(states.NewMessageReceived(message));
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  void _onUserTyping(
      events.UserTypingEvent event, Emitter<states.ChatState> emit) {
    try {
      emit(states.UserTyping(
        userId: event.userId,
        isTyping: event.isTyping,
      ));
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  void _onChatError(
      events.ChatErrorEvent event, Emitter<states.ChatState> emit) {
    emit(states.ChatError(event.message));
  }

  Future<void> _initializeWebSocket(int chatId) async {
    try {
      final accessToken = await _prefsRepository.getAccessToken();
      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      final wsUrl = Uri.parse('wss://api.tap-map.net/ws/notifications/')
          .replace(queryParameters: {'token': accessToken});

      _webSocketService = WebSocketService(jwtToken: accessToken);
      _webSocketService!.connect();

      await _wsSubscription?.cancel();
      _wsSubscription = _webSocketService!.stream.listen(
        (data) {
          if (data is Map<String, dynamic>) {
            if (data['type'] == 'message') {
              add(events.NewMessageEvent(data));
            } else if (data['type'] == 'typing') {
              add(events.UserTypingEvent(
                userId: data['user_id'],
                isTyping: data['is_typing'],
              ));
            }
          }
        },
        onError: (error) {
          add(events.ChatErrorEvent(error.toString()));
          // Attempt to reconnect after a delay
          Future.delayed(const Duration(seconds: 5), () {
            if (_currentUserId != null) {
              _initializeWebSocket(_currentUserId!);
            }
          });
        },
        onDone: () {
          // Attempt to reconnect if the chat is still active
          if (_currentUserId != null) {
            Future.delayed(const Duration(seconds: 5), () {
              _initializeWebSocket(_currentUserId!);
            });
          }
        },
      );
    } catch (e) {
      add(events.ChatErrorEvent(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    _webSocketService?.disconnect();
    return super.close();
  }
}
