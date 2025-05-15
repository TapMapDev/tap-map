import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/core/websocket/websocket_event.dart';
import 'package:tap_map/core/websocket/websocket_service.dart';
import 'package:tap_map/src/features/userFlow/user_profile/data/user_repository.dart';

import '../data/chat_repository.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/send_message_use_case.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
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
        super(ChatInitial()) {
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

  Future<void> _onFetchChats(FetchChats event, Emitter<ChatState> emit) async {
    try {
      emit(ChatLoading());
      final chats = await _chatRepository.fetchChats();
      emit(ChatsLoaded(chats));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onFetchChatById(
    FetchChatById event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(ChatLoading());
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
          print('📖 Marking message ${message.id} as read');
          print('   Before: isRead = ${message.isRead}');
          final updated = message.copyWith(isRead: true);
          print('   After: isRead = ${updated.isRead}');

          // Отправляем статус прочтения через WebSocket
          _webSocketService?.readMessage(
            chatId: message.chatId,
            messageId: message.id,
          );

          return updated;
        }
        return message;
      }).toList();

      print('✅ Emitting new state with updated messages');
      final currentState = state;
      if (currentState is ChatLoaded) {
        emit(currentState.copyWith(
          chat: chat,
          messages: updatedMessages,
          pinnedMessage: pinnedMessage,
          isRead: true,
          replyTo: currentState.replyTo,
          forwardFrom: currentState.forwardFrom,
        ));
      } else {
        emit(ChatLoaded(
          chat: chat,
          messages: updatedMessages,
          pinnedMessage: pinnedMessage,
          isRead: true,
        ));
      }
    } catch (e) {
      print('❌ Error fetching chat: $e');
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onConnectToChat(
    ConnectToChat event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final token = await _prefsRepository.getAccessToken();
      if (token == null) {
        emit(const ChatError('No access token available'));
        return;
      }

      final user = await _userRepository.getCurrentUser();
      _currentUsername = user.username;

      _webSocketService = WebSocketService(jwtToken: token);
      _webSocketService!.connect();

      _sendMessageUseCase = SendMessageUseCase(
        webSocketService: _webSocketService!,
        currentUsername: _currentUsername!,
      );

      final webSocketEvent = WebSocketEvent(_webSocketService!);
      _wsSubscription = _webSocketService!.stream.listen(
        (data) {
          webSocketEvent.handleEvent(data);
          add(NewMessageEvent(data));
        },
        onError: (error) {
          add(ChatErrorEvent(error.toString()));
        },
      );

      emit(ChatConnected());
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _onDisconnectFromChat(
    DisconnectFromChat event,
    Emitter<ChatState> emit,
  ) {
    _wsSubscription?.cancel();
    _webSocketService?.disconnect();
    _webSocketService = null;
    emit(ChatDisconnected());
  }

  void _onSetReplyTo(SetReplyTo event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(
        replyTo: event.message,
        pinnedMessage: currentState.pinnedMessage,
      ));
    }
  }

  void _onClearReplyTo(ClearReplyTo event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(
        replyTo: null,
        pinnedMessage: currentState.pinnedMessage,
      ));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      if (_webSocketService == null) {
        emit(const ChatError('Not connected to chat'));
        return;
      }

      final currentState = state;
      if (currentState is ChatLoaded) {
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
      emit(ChatError(e.toString()));
    }
  }

  void _onNewMessage(NewMessageEvent event, Emitter<ChatState> emit) async {
    try {
      final currentState = state;
      if (currentState is! ChatLoaded) return;

      dynamic rawData = event.message;

      // Надёжно декодим строку JSON, если нужно
      if (rawData is String) {
        try {
          rawData = jsonDecode(rawData);
        } catch (e) {
          print('❌ Failed to decode WebSocket string message: $e');
          return;
        }
      }

      // Проверяем, что это Map и содержит поле type
      if (rawData is! Map<String, dynamic> || !rawData.containsKey('type')) {
        print('⚠️ Ignored non-map or invalid message: $rawData');
        return;
      }

      final messageData = rawData;
      final type = messageData['type'];
      print('📨 Received message of type: $type');

      if (type == 'read_message') {
        final chatId = messageData['chat_id'];
        final messageId = messageData['message_id'];
        final readerId = messageData['reader_id'];
        print(
            '📖 Read message event: messageId=$messageId, chatId=$chatId, readerId=$readerId');
        print('👤 Current username: $_currentUsername');

        // Обновляем только сообщения, которые мы отправили
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.id == messageId && msg.senderUsername == _currentUsername) {
            print('✅ Marking our message as read: ${msg.id}');
            print('   Before: isRead = ${msg.isRead}');
            final updated = msg.copyWith(isRead: true);
            print('   After: isRead = ${updated.isRead}');
            return updated;
          }
          return msg;
        }).toList();

        print('📊 Messages count: ${updatedMessages.length}');
        print('📊 Updated messages with read status:');
        for (var msg in updatedMessages) {
          print('   Message ${msg.id}: isRead = ${msg.isRead}');
        }

        final newState = currentState.copyWith(
          messages: updatedMessages,
          isRead: true,
          replyTo: currentState.replyTo,
          forwardFrom: currentState.forwardFrom,
          pinnedMessage: currentState.pinnedMessage,
        );

        print('🔄 Emitting new state with updated messages');
        emit(newState);
        return;
      }

      if (type == 'message') {
        final newMessage = MessageModel.fromJson(messageData);
        print('📝 New message received: ${newMessage.text}');

        // Если это новое сообщение от другого пользователя, отправляем статус прочтения
        if (newMessage.senderUsername != _currentUsername) {
          print('🔵 Sending read status for message: ${newMessage.id}');
          _webSocketService?.readMessage(
            chatId: newMessage.chatId,
            messageId: newMessage.id,
          );
        }

        final updatedMessages = List<MessageModel>.from(currentState.messages)
          ..insert(0, newMessage);

        emit(currentState.copyWith(
          messages: updatedMessages,
          isRead: true,
          replyTo: currentState.replyTo,
          forwardFrom: currentState.forwardFrom,
          pinnedMessage: currentState.pinnedMessage,
        ));
        return;
      }

      // Обработка других типов сообщений (не обязательно, но полезно для отладки)
      print('ℹ️ Unhandled message type: $type → $messageData');
    } catch (e, stack) {
      print('❌ Error in _onNewMessage: $e\n$stack');
      emit(ChatError(e.toString()));
    }
  }

  void _onChatError(ChatErrorEvent event, Emitter<ChatState> emit) {
    emit(ChatError(event.message));
  }

  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
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
          isRead: true,
        ));
      } catch (e) {
        emit(ChatError(e.toString()));
      }
    }
  }

  Future<void> _onEditMessage(
    EditMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      try {
        if (_webSocketService == null) {
          emit(const ChatError('Not connected to chat'));
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
          isRead: true,
        ));
      } catch (e) {
        emit(ChatError(e.toString()));
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
    Emitter<ChatState> emit,
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
      if (currentState is ChatLoaded) {
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
      emit(ChatError('Ошибка при закреплении: $e'));
    }
  }

  Future<void> _onUnpinMessage(
      UnpinMessage event, Emitter<ChatState> emit) async {
    try {
      await _chatRepository.unpinMessage(
        chatId: event.chatId,
        messageId: event.messageId,
      );

      final currentState = state;
      if (currentState is ChatLoaded) {
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
    } catch (e) {}
  }

  void _onUploadFile(UploadFile event, Emitter<ChatState> emit) async {
    try {
      final currentState = state;
      if (currentState is! ChatLoaded) {
        throw Exception('Chat is not loaded');
      }

      final fileUrl = await _chatRepository.uploadFile(event.file.path);

      // Отправляем сообщение с файлом
      if (_sendMessageUseCase != null) {
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
      } else {
        throw Exception('Not connected to chat');
      }
    } catch (e) {}
  }
}
