import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tap_map/src/features/userFlow/auth/data/preferences_repository.dart';
import 'package:tap_map/src/features/userFlow/auth/data/user_repository.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_messages_bloc/chat_messages_event.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_messages_bloc/chat_messages_state.dart';
import 'package:tap_map/src/features/userFlow/chat/data/chat_repository.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';
import 'package:tap_map/src/features/userFlow/chat/models/chat_model.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_websocket_service.dart';

class ChatMessagesBloc extends Bloc<ChatMessagesEvent, ChatMessagesState> {
  final ChatRepository _chatRepository;
  final UserRepository _userRepository;
  
  // Подписка на события WebSocket
  StreamSubscription<WebSocketEventData>? _wsSubscription;

  ChatMessagesBloc({
    required ChatRepository chatRepository,
    required UserRepository userRepository,
  })  : _chatRepository = chatRepository,
        _userRepository = userRepository,
        super(ChatMessagesInitial()) {
    on<FetchChatMessagesEvent>(_onFetchChatMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<NewWebSocketMessageEvent>(_onNewWebSocketMessage);
    on<ChatMessagesErrorEvent>(_onChatMessagesError);
    on<ConnectToChatMessagesEvent>(_onConnectToChatMessages);
    on<DisconnectFromChatMessagesEvent>(_onDisconnectFromChatMessages);
    on<SendTypingEvent>(_onSendTyping);
  }

  Future<void> _onFetchChatMessages(
    FetchChatMessagesEvent event,
    Emitter<ChatMessagesState> emit,
  ) async {
    try {
      emit(ChatMessagesLoading());

      final result = await _chatRepository.fetchChatWithMessages(event.chatId);
      final chat = result['chat'] as ChatModel?;
      final messages = result['messages'] as List<MessageModel>;
      final pinnedMessageId = result['pinnedMessageId'] as int?;

      if (chat == null) {
        emit(const ChatMessagesError('Чат не найден'));
        return;
      }

      emit(ChatMessagesLoaded(
        chatId: event.chatId,
        chat: chat,
        messages: messages,
        pinnedMessageId: pinnedMessageId,
      ));
    } catch (e) {
      emit(ChatMessagesError(e.toString()));
    }
  }

  Future<void> _onConnectToChatMessages(
    ConnectToChatMessagesEvent event,
    Emitter<ChatMessagesState> emit,
  ) async {
    try {
      // Подключаемся к WebSocket через репозиторий
      final success = await _chatRepository.connectToChat();
      
      if (!success) {
        emit(const ChatMessagesError('Не удалось подключиться к чату'));
        return;
      }
      
      // Подписываемся на события WebSocket
      _wsSubscription = _chatRepository.webSocketEvents.listen(_handleWebSocketEvent);

      emit(ChatMessagesConnected());
    } catch (e) {
      emit(ChatMessagesError(e.toString()));
    }
  }

  void _onDisconnectFromChatMessages(
    DisconnectFromChatMessagesEvent event,
    Emitter<ChatMessagesState> emit,
  ) {
    _wsSubscription?.cancel();
    _chatRepository.disconnectFromChat();
    emit(ChatMessagesDisconnected());
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatMessagesState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is ChatMessagesLoaded) {
        // Отправляем сообщение через репозиторий
        final newMessage = await _chatRepository.sendMessage(
          chatId: event.chatId,
          text: event.text,
          replyToId: event.replyToId,
          forwardedFromId: event.forwardedFromId,
          attachments: event.attachments,
        );
        
        // Обновляем список сообщений в UI
        final updatedMessages = List<MessageModel>.from(currentState.messages)
          ..add(newMessage);
        
        emit(ChatMessagesLoaded(
          chatId: currentState.chatId,
          chat: currentState.chat,
          messages: updatedMessages,
          pinnedMessageId: currentState.pinnedMessageId,
        ));
      }
    } catch (e) {
      emit(ChatMessagesError(e.toString()));
    }
  }

  // Обработчик событий WebSocket
  void _handleWebSocketEvent(WebSocketEventData event) {
    if (event.type == WebSocketEventType.message) {
      add(NewWebSocketMessageEvent(event.data));
    } else if (event.type == WebSocketEventType.error) {
      add(ChatMessagesErrorEvent(event.error ?? 'Ошибка WebSocket'));
    }
    // Другие типы событий можно обрабатывать по мере необходимости
  }

  Future<void> _onNewWebSocketMessage(
      NewWebSocketMessageEvent event, Emitter<ChatMessagesState> emit) async {
    try {
      final currentState = state;
      if (currentState is! ChatMessagesLoaded) {
        print('❌ ChatMessagesBloc: Current state is not ChatMessagesLoaded');
        return;
      }

      final eventType = event.message['event'] as String?;
      final type = event.message['type'] as String?;
      
      if (type == 'message' || type == 'new_message' || eventType == 'message') {
        // Обрабатываем сообщение через репозиторий
        final newMessage = await _chatRepository.processWebSocketMessage(event.message);
        
        if (newMessage == null) {
          print('❌ ChatMessagesBloc: Failed to process WebSocket message');
          return;
        }
        
        // Проверяем, существует ли уже сообщение с таким ID
        final messageExists = currentState.messages.any((msg) => msg.id == newMessage.id);
        if (messageExists) {
          print('📝 Socket: Сообщение уже существует, пропускаем');
          return;
        }
        
        // Если это новое сообщение от другого пользователя, отправляем статус прочтения
        final currentUser = await _userRepository.getCurrentUser();
        if (newMessage.senderUsername != currentUser.username) {
          _chatRepository.markMessageAsRead(
            chatId: newMessage.chatId,
            messageId: newMessage.id,
          );
        }
        
        // Обновляем UI
        final updatedMessages = List<MessageModel>.from(currentState.messages)
          ..insert(0, newMessage);
        
        emit(currentState.copyWith(
          messages: updatedMessages,
          isRead: true,
        ));
      }
    } catch (e, stack) {
      print('❌ Socket: Ошибка обработки события: $e\n$stack');
      emit(ChatMessagesError(e.toString()));
    }
  }

  void _onChatMessagesError(ChatMessagesErrorEvent event, Emitter<ChatMessagesState> emit) {
    emit(ChatMessagesError(event.message));
  }

  void _onSendTyping(
    SendTypingEvent event,
    Emitter<ChatMessagesState> emit,
  ) {
    try {
      _chatRepository.sendTyping(
        chatId: event.chatId,
        isTyping: event.isTyping,
      );
    } catch (e) {
      emit(ChatMessagesError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
