import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../data/chat_repository.dart';
import '../models/message_model.dart';
import 'chat_event.dart' as events;
import 'chat_state.dart' as states;

class ChatBloc extends Bloc<events.ChatEvent, states.ChatState> {
  final ChatRepository _chatRepository;
  final SharedPrefsRepository _prefsRepository;
  WebSocketChannel? _channel;
  int? _currentChatId;

  ChatBloc({
    required ChatRepository chatRepository,
    required SharedPrefsRepository prefsRepository,
  })  : _chatRepository = chatRepository,
        _prefsRepository = prefsRepository,
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
      final chat = await _chatRepository.fetchChatById(event.chatId);
      _currentChatId = event.chatId;
      await _initializeWebSocket(event.chatId);
      emit(states.ChatLoaded(chat: chat, messages: const []));
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  Future<void> _onSendMessage(
    events.SendMessage event,
    Emitter<states.ChatState> emit,
  ) async {
    try {
      if (_channel == null) {
        throw Exception('WebSocket connection not initialized');
      }

      final message = {
        'type': 'message',
        'chat_id': event.chatId,
        'text': event.text,
        'message_type': 'text',
      };

      _channel!.sink.add(message);
      emit(states.MessageSent(MessageModel(
        id: DateTime.now().millisecondsSinceEpoch,
        text: event.text,
        userId: 1, // TODO: Get current user ID
        createdAt: DateTime.now(),
        status: MessageStatus.sent,
        type: MessageType.text,
      )));
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  void _onSendTyping(events.SendTyping event, Emitter<states.ChatState> emit) {
    try {
      if (_channel == null) {
        throw Exception('WebSocket connection not initialized');
      }

      final typingMessage = {
        'type': 'typing',
        'chat_id': event.chatId,
        'is_typing': true,
      };

      _channel!.sink.add(typingMessage);
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
      _channel?.sink.close();

      final accessToken = await _prefsRepository.getAccessToken();
      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      final wsUrl = Uri.parse('wss://api.tap-map.net/api/ws/chat/$chatId/')
          .replace(queryParameters: {'token': accessToken});

      _channel = WebSocketChannel.connect(wsUrl);

      _channel!.stream.listen(
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
            if (_currentChatId != null) {
              _initializeWebSocket(_currentChatId!);
            }
          });
        },
        onDone: () {
          // Attempt to reconnect if the chat is still active
          if (_currentChatId != null) {
            Future.delayed(const Duration(seconds: 5), () {
              _initializeWebSocket(_currentChatId!);
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
    _channel?.sink.close();
    return super.close();
  }
}
