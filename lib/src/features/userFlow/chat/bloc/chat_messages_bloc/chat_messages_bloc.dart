import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/core/websocket/websocket_event.dart';
import 'package:tap_map/core/websocket/websocket_service.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_messages_bloc/chat_messages_event.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_messages_bloc/chat_messages_state.dart';
import 'package:tap_map/src/features/userFlow/chat/data/chat_repository.dart';
import 'package:tap_map/src/features/userFlow/chat/models/chat_model.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';
import 'package:tap_map/src/features/userFlow/chat/services/send_message_use_case.dart';
import 'package:tap_map/src/features/userFlow/user_profile/data/user_repository.dart';

class ChatMessagesBloc extends Bloc<ChatMessagesEvent, ChatMessagesState> {
  final ChatRepository _chatRepository;
  final SharedPrefsRepository _prefsRepository;
  final UserRepository _userRepository;
  WebSocketService? _webSocketService;
  StreamSubscription? _wsSubscription;

  WebSocketService? get webSocketService => _webSocketService;

  String? _currentUsername;
  SendMessageUseCase? _sendMessageUseCase;

  ChatMessagesBloc({
    required ChatRepository chatRepository,
    required SharedPrefsRepository prefsRepository,
    required UserRepository userRepository,
  })  : _chatRepository = chatRepository,
        _prefsRepository = prefsRepository,
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
      final data = await _chatRepository.fetchChatWithMessages(event.chatId);
      final chat = data['chat'] as ChatModel;
      final messages = data['messages'] as List<MessageModel>;

      // Получаем ID закрепленного сообщения из локального хранилища
      final pinnedMessageId =
          await _chatRepository.getPinnedMessageId(event.chatId);

      // Если есть закрепленное сообщение, находим его в списке
      MessageModel? pinnedMessage;
      if (pinnedMessageId != null) {
        pinnedMessage = messages.firstWhere(
          (m) => m.id == pinnedMessageId,
          orElse: () {
            return MessageModel.empty();
          },
        );
      }

      // Обновляем статус прочтения для непрочитанных сообщений
      final updatedMessages = messages.map((message) {
        if (!message.isRead && message.senderUsername != _currentUsername) {
          final updated = message.copyWith(isRead: true);

          _webSocketService?.readMessage(
            chatId: message.chatId,
            messageId: message.id,
          );

          return updated;
        }
        return message;
      }).toList();

      emit(ChatMessagesLoaded(
        chat: chat,
        messages: updatedMessages,
        isRead: true,
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
      final token = await _prefsRepository.getAccessToken();
      if (token == null) {
        emit(const ChatMessagesError('No access token available'));
        return;
      }

      final user = await _userRepository.getCurrentUser();
      _currentUsername = user.username;

      _webSocketService = WebSocketService(jwtToken: token);
      _webSocketService!.connect();
      _webSocketService!.setCurrentUsername(_currentUsername!);

      _sendMessageUseCase = SendMessageUseCase(
        webSocketService: _webSocketService!,
        currentUsername: _currentUsername!,
      );

      final webSocketEvent = WebSocketEvent(_webSocketService!);
      _wsSubscription = _webSocketService!.stream.listen(
        (data) {
          webSocketEvent.handleEvent(data);
          add(NewWebSocketMessageEvent(data));
        },
        onError: (error) {
          add(ChatMessagesErrorEvent(error.toString()));
        },
      );

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
    _webSocketService?.disconnect();
    _webSocketService = null;
    emit(ChatMessagesDisconnected());
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatMessagesState> emit,
  ) async {
    try {
      if (_webSocketService == null) {
        emit(const ChatMessagesError('Not connected to chat'));
        return;
      }

      final currentState = state;
      if (currentState is ChatMessagesLoaded) {
        _webSocketService!.sendMessage(
          chatId: event.chatId,
          text: event.text,
          replyToId: event.replyToId,
          forwardedFromId: event.forwardedFromId,
        );
      }
    } catch (e) {
      emit(ChatMessagesError(e.toString()));
    }
  }

  Future<void> _onNewWebSocketMessage(
      NewWebSocketMessageEvent event, Emitter<ChatMessagesState> emit) async {
    try {
      final currentState = state;
      if (currentState is! ChatMessagesLoaded) {
        print('❌ ChatMessagesBloc: Current state is not ChatMessagesLoaded');
        return;
      }

      // Если сообщение пришло как строка, пробуем распарсить JSON
      dynamic messageData = event.message;
      if (messageData is String) {
        try {
          messageData = jsonDecode(messageData);
          print('📝 Socket: Decoded message: $messageData');
        } catch (e) {
          print('❌ Socket: Failed to decode message: $e');
          return;
        }
      }

      // Проверяем тип сообщения
      if (messageData is! Map<String, dynamic> ||
          !messageData.containsKey('type')) {
        print('❌ Socket: Invalid message format: $messageData');
        return;
      }

      final type = messageData['type'];
      print('📝 Socket: Тип события: $type');

      if (type == 'message' || type == 'new_message') {
        final senderId = messageData['sender_id'] as int?;
        if (senderId == null) {
          print('❌ ChatMessagesBloc: No sender_id in message data');
          return;
        }

        try {
          final user = await _userRepository.getUserById(senderId);
          if (user.username == null) {
            print('❌ ChatMessagesBloc: No username for sender_id: $senderId');
            return;
          }

          final newMessage = MessageModel.fromJson({
            ...messageData,
            'sender_username': user.username,
          });

          print(
              '📨 ChatMessagesBloc: Processing new message - id: ${newMessage.id}, sender: ${newMessage.senderUsername}, text: ${newMessage.text}');

          // Проверяем, существует ли уже сообщение с таким ID
          final messageExists =
              currentState.messages.any((msg) => msg.id == newMessage.id);
          if (messageExists) {
            print('📝 Socket: Сообщение уже существует, пропускаем');
            return;
          }

          // Если это новое сообщение от другого пользователя, отправляем статус прочтения
          if (newMessage.senderUsername != _currentUsername) {
            print(
                '📨 ChatMessagesBloc: Sending read receipt for message ${newMessage.id}');
            _webSocketService?.readMessage(
              chatId: newMessage.chatId,
              messageId: newMessage.id,
            );
          }

          final updatedMessages = List<MessageModel>.from(currentState.messages)
            ..insert(0, newMessage);

          print(
              '📨 ChatMessagesBloc: Emitting new state with ${updatedMessages.length} messages');
          emit(currentState.copyWith(
            messages: updatedMessages,
            isRead: true,
          ));
        } catch (e) {
          print('❌ ChatMessagesBloc: Error getting user info: $e');
        }
        return;
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
      if (_webSocketService == null) {
        emit(const ChatMessagesError('Not connected to chat'));
        return;
      }

      _webSocketService!.sendTyping(
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
    _webSocketService?.disconnect();
    return super.close();
  }
}
