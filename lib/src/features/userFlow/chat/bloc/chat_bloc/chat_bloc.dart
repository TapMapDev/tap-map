import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/core/websocket/websocket_event.dart';
import 'package:tap_map/core/websocket/websocket_service.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_bloc/chat_event.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_bloc/chat_state.dart';
import 'package:tap_map/src/features/userFlow/chat/data/chat_repository.dart';
import 'package:tap_map/src/features/userFlow/chat/models/chat_model.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';
import 'package:tap_map/src/features/userFlow/user_profile/data/user_repository.dart';

import '../../services/send_message_use_case.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final SharedPrefsRepository _prefsRepository;
  final UserRepository _userRepository;

  String? _currentUsername;

  ChatBloc({
    required ChatRepository chatRepository,
    required SharedPrefsRepository prefsRepository,
  })  : _chatRepository = chatRepository,
        _prefsRepository = prefsRepository,
        _userRepository = GetIt.instance<UserRepository>(),
        super(ChatInitial()) {
    on<FetchChatsEvent>(_onFetchChats);
    on<FetchChatEvent>(_onFetchChat);
    on<SendMessage>(_onSendMessage);
    on<NewMessageEvent>(_onNewMessage);
    on<ChatErrorEvent>(_onChatError);
    on<ConnectToChat>(_onConnectToChat);
    on<DisconnectFromChat>(_onDisconnectFromChat);
    on<UploadFile>(_onUploadFile);
    on<SendTyping>(_onSendTyping);
    on<MarkChatAsReadEvent>(_onMarkChatAsRead);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<EditMessageEvent>(_onEditMessage);
    on<PinMessageEvent>(_onPinMessage);
    on<UnpinMessageEvent>(_onUnpinMessage);
    on<GetPinnedMessageEvent>(_onGetPinnedMessage);
  }

  Future<void> _onFetchChats(
    FetchChatsEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(ChatLoading());
      
      final chats = await _chatRepository.fetchChats();
      
      emit(ChatsLoaded(chats: chats));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onFetchChat(
    FetchChatEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(ChatLoading());
      
      final result = await _chatRepository.fetchChatWithMessages(event.chatId);
      final chat = result['chat'] as ChatModel?;
      final messages = result['messages'] as List<MessageModel>;
      final pinnedMessageId = result['pinnedMessageId'] as int?;
      
      if (chat == null) {
        emit(const ChatError('Чат не найден'));
        return;
      }
      
      emit(ChatLoaded(
        chat: chat,
        messages: messages,
        pinnedMessageId: pinnedMessageId,
      ));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is ChatLoaded) {
        // Используем ChatRepository вместо прямого вызова WebSocketService
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
        
        emit(currentState.copyWith(
          messages: updatedMessages,
        ));
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
            await _chatRepository.markMessageAsRead(
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

  Future<void> _onChatError(ChatErrorEvent event, Emitter<ChatState> emit) {
    emit(ChatError(event.message));
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

      await _chatRepository.connectToChat(token);
      emit(ChatConnected());
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _onDisconnectFromChat(
    DisconnectFromChat event,
    Emitter<ChatState> emit,
  ) {
    _chatRepository.disconnectFromChat();
    emit(ChatDisconnected());
  }

  Future<void> _onUploadFile(UploadFile event, Emitter<ChatState> emit) async {
    try {
      final currentState = state;
      if (currentState is! ChatLoaded) {
        throw Exception('Chat is not loaded');
      }

      final fileUrl = await _chatRepository.uploadFile(event.file.path);

      // Отправляем сообщение с файлом
      final newMessage = await _chatRepository.sendMessage(
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

      // Обновляем список сообщений в UI
      final updatedMessages = List<MessageModel>.from(currentState.messages)
        ..add(newMessage);

      emit(currentState.copyWith(
        messages: updatedMessages,
      ));
    } catch (e) {
      print('❌ Error uploading file: $e');
      emit(ChatError(e.toString()));
    }
  }

  void _onSendTyping(SendTyping event, Emitter<ChatState> emit) {
    try {
      print(
          '⌨️ Socket: Отправка события typing - chatId: ${event.chatId}, isTyping: ${event.isTyping}');
      _chatRepository.sendTyping(
        chatId: event.chatId,
        isTyping: event.isTyping,
      );
    } catch (_) {}
  }

  Future<void> _onMarkChatAsRead(
    MarkChatAsReadEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.markChatAsRead(event.chatId);
      
      // Обновляем состояние, если необходимо
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(currentState.copyWith(isRead: true));
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onDeleteMessage(
    DeleteMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.deleteMessage(
        event.chatId, 
        event.messageId, 
        event.action,
      );
      
      // Обновляем состояние
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        final updatedMessages = currentState.messages
            .where((msg) => msg.id != event.messageId)
            .toList();
        
        emit(currentState.copyWith(messages: updatedMessages));
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onEditMessage(
    EditMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.editMessage(
        event.chatId, 
        event.messageId, 
        event.text,
      );
      
      // Обновляем состояние
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.id == event.messageId) {
            return msg.copyWith(
              text: event.text,
              edited: true,
            );
          }
          return msg;
        }).toList();
        
        emit(currentState.copyWith(messages: updatedMessages));
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onPinMessage(
    PinMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.pinMessage(
        chatId: event.chatId, 
        messageId: event.messageId,
      );
      
      // Обновляем состояние
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(currentState.copyWith(pinnedMessageId: event.messageId));
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onUnpinMessage(
    UnpinMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.unpinMessage(
        chatId: event.chatId, 
        messageId: event.messageId,
      );
      
      // Обновляем состояние
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(currentState.copyWith(pinnedMessageId: null));
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onGetPinnedMessage(
    GetPinnedMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        final pinnedMessageId = await _chatRepository.getPinnedMessageId(event.chatId);
        
        if (pinnedMessageId != null) {
          final pinnedMessage = await _chatRepository.getPinnedMessage(
            event.chatId, 
            pinnedMessageId,
          );
          
          emit(currentState.copyWith(
            pinnedMessageId: pinnedMessageId,
            pinnedMessage: pinnedMessage,
          ));
        }
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _chatRepository.disconnectFromChat();
    return super.close();
  }
}
