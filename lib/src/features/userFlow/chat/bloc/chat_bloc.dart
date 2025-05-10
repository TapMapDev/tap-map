import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/core/websocket/websocket_service.dart';
import 'package:tap_map/src/features/userFlow/user_profile/data/user_repository.dart';

import '../data/chat_repository.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/send_message_use_case.dart';
import 'chat_event.dart';
import 'chat_state.dart' as states;

class ChatBloc extends Bloc<ChatEvent, states.ChatState> {
  final ChatRepository _chatRepository;
  final SharedPrefsRepository _prefsRepository;
  final UserRepository _userRepository;
  WebSocketService? _webSocketService;
  StreamSubscription? _wsSubscription;

  String? _currentUsername;
  SendMessageUseCase? _sendMessageUseCase;

  ChatBloc({
    required ChatRepository chatRepository,
    required SharedPrefsRepository prefsRepository,
  })  : _chatRepository = chatRepository,
        _prefsRepository = prefsRepository,
        _userRepository = GetIt.instance<UserRepository>(),
        super(states.ChatInitial()) {
    on<FetchChats>(_onFetchChats);
    on<FetchChatById>(_onFetchChatById);
    on<SendMessage>(_onSendMessage);
    on<SendTyping>(_onSendTyping);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<TogglePinChat>(_onTogglePinChat);
    on<NewMessageEvent>(_onNewMessage);
    on<UserTypingEvent>(_onUserTyping);
    on<ChatErrorEvent>(_onChatError);
    on<ConnectToChat>(_onConnectToChat);
    on<DisconnectFromChat>(_onDisconnectFromChat);
    on<DeleteMessage>(_onDeleteMessage);
  }

  Future<void> _onFetchChats(
      FetchChats event, Emitter<states.ChatState> emit) async {
    try {
      emit(states.ChatLoading());
      final chats = await _chatRepository.fetchChats();
      print('ChatBloc: Fetched ${chats.length} chats');
      emit(states.ChatsLoaded(chats));
    } catch (e) {
      print('ChatBloc: Error fetching chats: $e');
      emit(states.ChatError(e.toString()));
    }
  }

  Future<void> _onFetchChatById(
    FetchChatById event,
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
    ConnectToChat event,
    Emitter<states.ChatState> emit,
  ) async {
    try {
      final token = await _prefsRepository.getAccessToken();
      if (token == null) {
        emit(const states.ChatError('No access token available'));
        return;
      }

      final user = await _userRepository.getCurrentUser();
      // _currentUserId = user.id;
      _currentUsername = user.username;

      _webSocketService = WebSocketService(jwtToken: token);
      _webSocketService!.connect();

      _sendMessageUseCase = SendMessageUseCase(
        webSocketService: _webSocketService!,
        currentUsername: _currentUsername!,
      );

      _wsSubscription = _webSocketService!.stream.listen(
        (data) {
          add(NewMessageEvent(data));
        },
        onError: (error) {
          add(ChatErrorEvent(error.toString()));
        },
      );

      emit(states.ChatConnected());
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  void _onDisconnectFromChat(
    DisconnectFromChat event,
    Emitter<states.ChatState> emit,
  ) {
    _wsSubscription?.cancel();
    _webSocketService?.disconnect();
    _webSocketService = null;
    emit(states.ChatDisconnected());
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<states.ChatState> emit,
  ) async {
    try {
      if (_sendMessageUseCase == null) {
        emit(const states.ChatError('Not connected to chat'));
        return;
      }

      final message = _sendMessageUseCase!.execute(
        chatId: event.chatId,
        text: event.text,
        replyToId: event.replyToId,
        forwardedFromId: event.forwardedFromId,
      );

      emit(states.MessageSent(message));
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  void _onSendTyping(
    SendTyping event,
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
    MarkMessageAsRead event,
    Emitter<states.ChatState> emit,
  ) async {
    try {
      await _chatRepository.markChatAsRead(event.chatId);
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  Future<void> _onTogglePinChat(
    TogglePinChat event,
    Emitter<states.ChatState> emit,
  ) async {
    try {
      // TODO: Implement pin/unpin functionality
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  void _onNewMessage(NewMessageEvent event, Emitter<states.ChatState> emit) {
    try {
      print('ChatBloc: Processing new message: ${event.message}');
      dynamic messageData;

      if (event.message is String) {
        messageData = jsonDecode(event.message as String);
      } else {
        messageData = event.message;
      }

      if (messageData is Map<String, dynamic>) {
        if (messageData['type'] == 'message') {
          final message = MessageModel.fromJson(messageData);
          emit(states.NewMessageReceived(message));
        } else if (messageData['type'] == 'typing') {
          emit(states.UserTyping(
            userId: messageData['user_id'] as int,
            isTyping: messageData['is_typing'] as bool,
          ));
        }
      }
    } catch (e) {
      print('ChatBloc: Error processing new message: $e');
      emit(states.ChatError(e.toString()));
    }
  }

  void _onUserTyping(UserTypingEvent event, Emitter<states.ChatState> emit) {
    try {
      emit(states.UserTyping(
        userId: event.userId,
        isTyping: event.isTyping,
      ));
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  void _onChatError(ChatErrorEvent event, Emitter<states.ChatState> emit) {
    emit(states.ChatError(event.message));
  }

  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<states.ChatState> emit,
  ) async {
    try {
      await _chatRepository.deleteMessage(
        event.chatId,
        event.messageId,
        event.action,
      );
      emit(states.MessageDeleted(event.messageId));
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    _webSocketService?.disconnect();
    return super.close();
  }
}
