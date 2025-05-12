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
    on<SetReplyTo>(_onSetReplyTo);
    on<ClearReplyTo>(_onClearReplyTo);
    on<SendTyping>(_onSendTyping);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<NewMessageEvent>(_onNewMessage);
    on<UserTypingEvent>(_onUserTyping);
    on<ChatErrorEvent>(_onChatError);
    on<ConnectToChat>(_onConnectToChat);
    on<DisconnectFromChat>(_onDisconnectFromChat);
    on<DeleteMessage>(_onDeleteMessage);
    on<EditMessage>(_onEditMessage);
    on<PinMessage>(_onPinMessage);
    on<UnpinMessage>(_onUnpinMessage);
  }

  Future<void> _onFetchChats(
      FetchChats event, Emitter<states.ChatState> emit) async {
    try {
      emit(states.ChatLoading());
      final chats = await _chatRepository.fetchChats();
      emit(states.ChatsLoaded(chats));
    } catch (e) {
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
      final chat = data['chat'] as ChatModel;
      final messages = data['messages'] as List<MessageModel>;

      print(
          '📱 Loading chat: ${chat.chatId}, pinnedMessageId: ${chat.pinnedMessageId}');
      print('📱 Total messages: ${messages.length}');

      // Получаем ID закрепленного сообщения из локального хранилища
      final pinnedMessageId =
          await _chatRepository.getPinnedMessageId(event.chatId);
      print('📌 Local pinned message ID: $pinnedMessageId');

      // Если есть закрепленное сообщение, находим его в списке
      MessageModel? pinnedMessage;
      if (pinnedMessageId != null) {
        print('🔍 Looking for pinned message with ID: $pinnedMessageId');
        try {
          pinnedMessage = messages.firstWhere(
            (m) => m.id == pinnedMessageId,
            orElse: () {
              print('⚠️ Pinned message not found in messages list');
              return MessageModel.empty();
            },
          );
          print('✅ Found pinned message: ${pinnedMessage.text}');
        } catch (e) {
          print('❌ Error finding pinned message: $e');
        }
      }

      emit(states.ChatLoaded(
        chat: chat,
        messages: messages,
        pinnedMessage: pinnedMessage,
      ));
    } catch (e) {
      print('❌ Error loading chat: $e');
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

  void _onSetReplyTo(SetReplyTo event, Emitter<states.ChatState> emit) {
    final currentState = state;
    if (currentState is states.ChatLoaded) {
      emit(currentState.copyWith(replyTo: event.message));
    }
  }

  void _onClearReplyTo(ClearReplyTo event, Emitter<states.ChatState> emit) {
    final currentState = state;
    if (currentState is states.ChatLoaded) {
      emit(currentState.copyWith(replyTo: null));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<states.ChatState> emit,
  ) async {
    final currentState = state;
    if (_sendMessageUseCase == null) {
      emit(const states.ChatError('Not connected to chat'));
      return;
    }

    if (currentState is states.ChatLoaded) {
      try {
        // Если это пересылка сообщения, проверяем, что оно не отправляется в тот же чат
        if (event.forwardedFromId != null) {
          final originalMessage = currentState.messages.firstWhere(
            (m) => m.id == event.forwardedFromId,
            orElse: () => MessageModel.empty(),
          );

          // Если сообщение уже есть в текущем чате, не отправляем его повторно
          if (originalMessage.id != 0) {
            return;
          }
        }

        final message = _sendMessageUseCase!.execute(
          chatId: event.chatId,
          text: event.text,
          replyToId: event.replyToId,
          forwardedFromId: event.forwardedFromId,
        );

        final updatedMessages = List<MessageModel>.from(currentState.messages)
          ..insert(0, message);

        emit(states.ChatLoaded(
          chat: currentState.chat,
          messages: updatedMessages,
          replyTo: null, // Clear reply after sending
          forwardFrom: null, // Clear forward after sending
        ));
      } catch (e) {
        emit(states.ChatError(e.toString()));
      }
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

  void _onNewMessage(NewMessageEvent event, Emitter<states.ChatState> emit) {
    final currentState = state;
    if (currentState is states.ChatLoaded) {
      try {
        dynamic messageData;
        if (event.message is String) {
          messageData = jsonDecode(event.message as String);
        } else {
          messageData = event.message;
        }

        if (messageData is Map<String, dynamic> &&
            messageData['type'] == 'message') {
          final newMessage = MessageModel.fromJson(messageData);

          final updatedMessages = List<MessageModel>.from(currentState.messages)
            ..insert(0, newMessage);

          emit(states.ChatLoaded(
            chat: currentState.chat,
            messages: updatedMessages,
          ));
        }
      } catch (e) {
        emit(states.ChatError(e.toString()));
      }
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
    final currentState = state;
    if (currentState is states.ChatLoaded) {
      try {
        await _chatRepository.deleteMessage(
          event.chatId,
          event.messageId,
          event.action,
        );
        final updatedMessages = currentState.messages
            .where((msg) => msg.id != event.messageId)
            .toList();

        emit(states.ChatLoaded(
          chat: currentState.chat,
          messages: updatedMessages,
        ));
      } catch (e) {
        emit(states.ChatError(e.toString()));
      }
    }
  }

  Future<void> _onEditMessage(
    EditMessage event,
    Emitter<states.ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is states.ChatLoaded) {
      try {
        if (_webSocketService == null) {
          emit(const states.ChatError('Not connected to chat'));
          return;
        }

        _webSocketService!.editMessage(
          chatId: event.chatId,
          messageId: event.messageId,
          text: event.text,
        );

        final updatedMessage = currentState.messages.map((message) {
          if (message.id == event.messageId) {
            return message.copyWith(
              text: event.text,
              editedAt: DateTime.now(),
            );
          }
          return message;
        }).toList();
        emit(states.ChatLoaded(
          chat: currentState.chat,
          messages: updatedMessage,
        ));
      } catch (e) {
        emit(states.ChatError(e.toString()));
      }
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    _webSocketService?.disconnect();
    return super.close();
  }

  Future<void> _onPinMessage(
    PinMessage event,
    Emitter<states.ChatState> emit,
  ) async {
    print(
        '🔵 PinMessage event received: chatId=${event.chatId}, messageId=${event.messageId}');
    try {
      await _chatRepository.pinMessage(
        chatId: event.chatId,
        messageId: event.messageId,
      );
      print('✅ PinMessage API call successful');

      final currentState = state;
      if (currentState is states.ChatLoaded) {
        final pinnedMessage =
            currentState.messages.firstWhere((m) => m.id == event.messageId);
        print('📌 Found message to pin: ${pinnedMessage.text}');

        final updatedMessages = currentState.messages
            .map((message) => message.id == event.messageId
                ? message.copyWith(isPinned: true)
                : message)
            .toList();

        // Обновляем чат с новым pinnedMessageId
        final updatedChat = currentState.chat.copyWith(
          pinnedMessageId: event.messageId,
        );
        print(
            '📝 Updated chat pinnedMessageId: ${updatedChat.pinnedMessageId}');

        emit(currentState.copyWith(
          chat: updatedChat,
          messages: updatedMessages,
          pinnedMessage: pinnedMessage,
        ));
        print('🔄 State updated with pinned message');
      }
    } catch (e) {
      print('❌ Error in _onPinMessage: $e');
      emit(states.ChatError('Ошибка при закреплении: $e'));
    }
  }

  Future<void> _onUnpinMessage(
      UnpinMessage event, Emitter<states.ChatState> emit) async {
    try {
      await _chatRepository.unpinMessage(
        chatId: event.chatId,
        messageId: event.messageId,
      );

      final currentState = state;
      if (currentState is states.ChatLoaded) {
        final updatedMessages = currentState.messages
            .map((message) => message.id == event.messageId
                ? message.copyWith(isPinned: false)
                : message)
            .toList();

        // Обновляем чат, очищая pinnedMessageId
        final updatedChat = currentState.chat.copyWith(
          pinnedMessageId: null,
        );

        emit(currentState.copyWith(
          chat: updatedChat,
          messages: updatedMessages,
          pinnedMessage: null,
        ));
      }
    } catch (e) {
      emit(states.ChatError('Ошибка при откреплении сообщения: $e'));
    }
  }
}
