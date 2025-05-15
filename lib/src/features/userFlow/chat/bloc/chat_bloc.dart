import 'dart:async';

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
    on<NewMessageEvent>(_onNewMessage);
    on<ChatErrorEvent>(_onChatError);
    on<ConnectToChat>(_onConnectToChat);
    on<DisconnectFromChat>(_onDisconnectFromChat);
    on<DeleteMessage>(_onDeleteMessage);
    on<EditMessage>(_onEditMessage);
    on<PinMessage>(_onPinMessage);
    on<UnpinMessage>(_onUnpinMessage);
    on<UploadFile>(_onUploadFile);
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

      // Отправляем статус прочтения для непрочитанных сообщений
      _markMessagesAsRead(messages);

      emit(states.ChatLoaded(
        chat: chat,
        messages: messages,
        pinnedMessage: pinnedMessage,
      ));
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  void _markMessagesAsRead(List<MessageModel> messages) {
    if (_webSocketService == null || _currentUsername == null) return;

    for (final message in messages) {
      if (!message.isRead && message.senderUsername != _currentUsername) {
        print('🔵 Marking message as read: ${message.id}');
        _webSocketService!.readMessage(
          chatId: message.chatId,
          messageId: message.id,
        );
        print(
            '✅ readMessage(chatId: ${message.chatId}, messageId: ${message.id})');
      }
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
      emit(currentState.copyWith(
        replyTo: event.message,
        pinnedMessage: currentState.pinnedMessage,
      ));
    }
  }

  void _onClearReplyTo(ClearReplyTo event, Emitter<states.ChatState> emit) {
    final currentState = state;
    if (currentState is states.ChatLoaded) {
      emit(currentState.copyWith(
        replyTo: null,
        pinnedMessage: currentState.pinnedMessage,
      ));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<states.ChatState> emit,
  ) async {
    try {
      if (_webSocketService == null) {
        emit(const states.ChatError('Not connected to chat'));
        return;
      }

      final currentState = state;
      if (currentState is states.ChatLoaded) {
        _webSocketService!.sendMessage(
          chatId: event.chatId,
          text: event.text,
          replyToId: event.replyToId,
          forwardedFromId: event.forwardedFromId,
        );

        // Создаем новое сообщение
        final newMessage = MessageModel(
          id: DateTime.now().millisecondsSinceEpoch,
          chatId: event.chatId,
          text: event.text,
          senderUsername: _currentUsername ?? 'Unknown',
          createdAt: DateTime.now(),
          replyToId: event.replyToId,
          forwardedFromId: event.forwardedFromId,
        );

        // Обновляем состояние, сохраняя закрепленное сообщение
        emit(currentState.copyWith(
          messages: [newMessage, ...currentState.messages],
          pinnedMessage: currentState.pinnedMessage,
        ));
      }
    } catch (e) {
      emit(states.ChatError(e.toString()));
    }
  }

  void _onNewMessage(
      NewMessageEvent event, Emitter<states.ChatState> emit) async {
    try {
      final currentState = state;
      if (currentState is! states.ChatLoaded) return;

      final messageData = event.message;

      if (messageData['type'] == 'message_read') {
        final messageId = messageData['message_id'];
        final chatId = messageData['chat_id'];

        final updatedMessages = currentState.messages.map((msg) {
          if (msg.id == messageId && msg.chatId == chatId) {
            return msg.copyWith(isRead: true);
          }
          return msg;
        }).toList();

        emit(states.ChatLoaded(
          chat: currentState.chat,
          messages: updatedMessages,
          replyTo: currentState.replyTo,
          forwardFrom: currentState.forwardFrom,
          pinnedMessage: currentState.pinnedMessage,
        ));
        return;
      }

      if (messageData is Map<String, dynamic> &&
          messageData['type'] == 'message') {
        final newMessage = MessageModel.fromJson(messageData);

        // Если это новое сообщение от другого пользователя, отправляем статус прочтения
        if (newMessage.senderUsername != _currentUsername) {
          _webSocketService?.readMessage(
            chatId: newMessage.chatId,
            messageId: newMessage.id,
          );
        }

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

        // Проверяем, не было ли удалено закрепленное сообщение
        MessageModel? pinnedMessage = currentState.pinnedMessage;
        if (pinnedMessage?.id == event.messageId) {
          pinnedMessage = null;
        }

        emit(currentState.copyWith(
          chat: currentState.chat,
          messages: updatedMessages,
          pinnedMessage: pinnedMessage,
          replyTo: currentState.replyTo,
          forwardFrom: currentState.forwardFrom,
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

        final updatedMessages = currentState.messages.map((message) {
          if (message.id == event.messageId) {
            return message.copyWith(
              text: event.text,
              editedAt: DateTime.now(),
            );
          }
          return message;
        }).toList();

        // Обновляем закрепленное сообщение, если оно было отредактировано
        MessageModel? pinnedMessage = currentState.pinnedMessage;
        if (pinnedMessage != null && pinnedMessage.id == event.messageId) {
          pinnedMessage = pinnedMessage.copyWith(
            text: event.text,
            editedAt: DateTime.now(),
          );
        }

        emit(currentState.copyWith(
          chat: currentState.chat,
          messages: updatedMessages,
          pinnedMessage: pinnedMessage,
          replyTo: currentState.replyTo,
          forwardFrom: currentState.forwardFrom,
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

  void _onUploadFile(UploadFile event, Emitter<states.ChatState> emit) async {
    try {
      print('📤 Starting file upload in ChatBloc');
      print('📤 File path: ${event.file.path}');

      final currentState = state;
      if (currentState is! states.ChatLoaded) {
        throw Exception('Chat is not loaded');
      }

      final fileUrl = await _chatRepository.uploadFile(event.file.path);
      print('📤 File uploaded successfully. URL: $fileUrl');

      // Отправляем сообщение с файлом
      if (_sendMessageUseCase != null) {
        print('📤 Sending message with file URL');
        _sendMessageUseCase!.execute(
          chatId: currentState.chat.chatId,
          text: fileUrl,
        );

        // Создаем новое сообщение
        final newMessage = MessageModel(
          id: DateTime.now().millisecondsSinceEpoch,
          chatId: currentState.chat.chatId,
          text: fileUrl,
          senderUsername: _currentUsername ?? 'Unknown',
          createdAt: DateTime.now(),
        );

        // Обновляем состояние, сохраняя все важные данные
        emit(currentState.copyWith(
          messages: [newMessage, ...currentState.messages],
          pinnedMessage: currentState.pinnedMessage,
          replyTo: currentState.replyTo,
          forwardFrom: currentState.forwardFrom,
        ));
        print('✅ Message with file sent successfully');
      } else {
        print('❌ SendMessageUseCase is null');
        throw Exception('Not connected to chat');
      }
    } catch (e) {
      print('❌ Error in _onUploadFile: $e');
      emit(states.ChatError('Ошибка при отправке файла: $e'));
    }
  }
}
