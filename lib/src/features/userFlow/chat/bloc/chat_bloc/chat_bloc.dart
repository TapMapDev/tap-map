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

import '../../data/chat_repository.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../services/send_message_use_case.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final SharedPrefsRepository _prefsRepository;
  final UserRepository _userRepository;
  WebSocketService? _webSocketService;
  StreamSubscription? _wsSubscription;

  // Добавляем геттер для доступа к WebSocketService
  WebSocketService? get webSocketService => _webSocketService;

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
    on<NewMessageEvent>(_onNewMessage);
    on<ChatErrorEvent>(_onChatError);
    on<ConnectToChat>(_onConnectToChat);
    on<DisconnectFromChat>(_onDisconnectFromChat);
    on<UploadFile>(_onUploadFile);
    on<SendTyping>(_onSendTyping);
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
          final updated = message.copyWith(isRead: true);

          _webSocketService?.readMessage(
            chatId: message.chatId,
            messageId: message.id,
          );

          return updated;
        }
        return message;
      }).toList();

      final currentState = state;
      if (currentState is ChatLoaded) {
        emit(currentState.copyWith(
          chat: chat,
          messages: updatedMessages,
          isRead: true,
          replyTo: currentState.replyTo,
          forwardFrom: currentState.forwardFrom,
        ));
      } else {
        emit(ChatLoaded(
          chat: chat,
          messages: updatedMessages,
          isRead: true,
        ));
      }
    } catch (e) {
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
      _webSocketService!.setCurrentUsername(_currentUsername!);

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
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onNewMessage(
      NewMessageEvent event, Emitter<ChatState> emit) async {
    try {
      print('📥 ChatBloc: Received new message: $event.message');

      final currentState = state;
      if (currentState is! ChatLoaded) {
        print('❌ ChatBloc: Current state is not ChatLoaded');
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
          print('❌ ChatBloc: No sender_id in message data');
          return;
        }

        try {
          final user = await _userRepository.getUserById(senderId);
          if (user.username == null) {
            print('❌ ChatBloc: No username for sender_id: $senderId');
            return;
          }

          final newMessage = MessageModel.fromJson({
            ...messageData,
            'sender_username': user.username,
          });

          print(
              '📨 ChatBloc: Processing new message - id: ${newMessage.id}, sender: ${newMessage.senderUsername}, text: ${newMessage.text}');

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
                '📨 ChatBloc: Sending read receipt for message ${newMessage.id}');
            _webSocketService?.readMessage(
              chatId: newMessage.chatId,
              messageId: newMessage.id,
            );
          }

          final updatedMessages = List<MessageModel>.from(currentState.messages)
            ..insert(0, newMessage);

          print(
              '📨 ChatBloc: Emitting new state with ${updatedMessages.length} messages');
          emit(currentState.copyWith(
            messages: updatedMessages,
            isRead: true,
            replyTo: currentState.replyTo,
            forwardFrom: currentState.forwardFrom,
          ));
        } catch (e) {
          print('❌ ChatBloc: Error getting user info: $e');
        }
        return;
      }
    } catch (e, stack) {
      print('❌ Socket: Ошибка обработки события: $e\n$stack');
      emit(ChatError(e.toString()));
    }
  }

  void _onChatError(ChatErrorEvent event, Emitter<ChatState> emit) {
    emit(ChatError(event.message));
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    _webSocketService?.disconnect();
    return super.close();
  }

  void _onUploadFile(UploadFile event, Emitter<ChatState> emit) async {
    try {
      final currentState = state;
      if (currentState is! ChatLoaded) {
        throw Exception('Chat is not loaded');
      }

      final fileUrl = await _chatRepository.uploadFile(event.file.path);

      // Отправляем сообщение с файлом
      if (_webSocketService != null) {
        _webSocketService!.sendMessage(
          chatId: currentState.chat.chatId,
          text: event.caption ?? '',
          attachments: [
            {
              'url': fileUrl,
              'content_type': event.file.path.toLowerCase().endsWith('.mp4') ||
                      event.file.path.toLowerCase().endsWith('.mov') ||
                      event.file.path.toLowerCase().endsWith('.avi') ||
                      event.file.path.toLowerCase().endsWith('.webm')
                  ? 'video/mp4'
                  : 'image/jpeg',
            }
          ],
        );
      } else {
        throw Exception('Not connected to chat');
      }
    } catch (e) {
      print('❌ Error uploading file: $e');
      emit(ChatError(e.toString()));
    }
  }

  void _onSendTyping(SendTyping event, Emitter<ChatState> emit) {
    try {
      print(
          '⌨️ Socket: Отправка события typing - chatId: ${event.chatId}, isTyping: ${event.isTyping}');
      _webSocketService?.sendTyping(
        chatId: event.chatId,
        isTyping: event.isTyping,
      );
    } catch (_) {}
  }
}
