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

        // Create new message
        final newMessage = MessageModel(
          id: DateTime.now().millisecondsSinceEpoch,
          chatId: event.chatId,
          text: event.text,
          senderUsername: _currentUsername ?? 'Unknown',
          createdAt: DateTime.now(),
          replyToId: event.replyToId,
          forwardedFromId: event.forwardedFromId,
        );

        // Update state
        emit(currentState.copyWith(
          messages: [newMessage, ...currentState.messages],
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
          print('📝 Socket: Decoded message: $rawData');
        } catch (e) {
          print('❌ Socket: Failed to decode message: $e');
          return;
        }
      }
      if (rawData is! Map<String, dynamic> || !rawData.containsKey('type')) {
        print('❌ Socket: Invalid message format: $rawData');
        return;
      }

      final messageData = rawData;
      final type = messageData['type'];
      print('📝 Socket: Тип события: $type');

      // Обработка события редактирования сообщения
      if (type == 'edit_message' || type == 'message_edited') {
        print('🖊️ Socket: Получено событие редактирования сообщения');
        final chatId = messageData['chat_id'] as int?;
        final messageId = messageData['message_id'] as int?;
        final newText = messageData['text'] as String?;
        final editedAtStr = messageData['edited_at'] as String?;

        print('🖊️ Socket: chatId=$chatId, messageId=$messageId');
        print('🖊️ Socket: newText="$newText", editedAt=$editedAtStr');

        if (chatId == null || messageId == null || newText == null) {
          print('❌ Socket: Отсутствуют обязательные поля для edit_message');
          return;
        }

        final editedAt =
            editedAtStr != null ? DateTime.parse(editedAtStr) : DateTime.now();

        // Проверяем, существует ли сообщение с таким ID
        final messageExists =
            currentState.messages.any((msg) => msg.id == messageId);
        if (!messageExists) {
          print('❌ Socket: Сообщение с id=$messageId не найдено в списке');
          return;
        }

        // Обновляем сообщение в списке
        print('🖊️ Socket: Обновление сообщения в списке');
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.id == messageId) {
            print('🖊️ Socket: Старый текст: "${msg.text}"');
            print('🖊️ Socket: Новый текст: "$newText"');
            return msg.copyWith(
              text: newText,
              editedAt: editedAt,
            );
          }
          return msg;
        }).toList();

        print('✅ Socket: Сообщение успешно обновлено');
        emit(currentState.copyWith(
          messages: updatedMessages,
          replyTo: currentState.replyTo,
          forwardFrom: currentState.forwardFrom,
        ));

        return;
      }

      if (type == 'typing') {
        final userId = messageData['user_id'] as int?;
        final isTyping = messageData['is_typing'] as bool?;
        print(
            '⌨️ Socket: Событие typing - userId: $userId, isTyping: $isTyping');

        if (userId == null || isTyping == null) {
          print('❌ Socket: Отсутствуют обязательные поля userId или isTyping');
          return;
        }

        try {
          // Получаем username по userId
          final user = await _userRepository.getUserById(userId);
          if (user.username == null) {
            print('❌ Socket: Username не найден для userId: $userId');
            return;
          }
          final username = user.username!;
          print('👤 Socket: Получен username: $username для userId: $userId');

          // Обновляем список печатающих пользователей
          final updatedTypingUsers = Set<String>.from(currentState.typingUsers);
          if (isTyping) {
            updatedTypingUsers.add(username);
            print('➕ Socket: Добавлен печатающий пользователь: $username');
          } else {
            updatedTypingUsers.remove(username);
            print('➖ Socket: Удален печатающий пользователь: $username');
          }

          print('👥 Socket: Текущий список печатающих: $updatedTypingUsers');

          emit(currentState.copyWith(
            typingUsers: updatedTypingUsers,
          ));
        } catch (e) {
          print('❌ Socket: Ошибка получения username для userId $userId: $e');
        }
        return;
      }

      if (type == 'read_message') {
        final chatId = messageData['chat_id'];
        final messageId = messageData['message_id'];
        final readerId = messageData['reader_id'];

        // Обновляем только сообщения, которые мы отправили
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.id == messageId && msg.senderUsername == _currentUsername) {
            final updated = msg.copyWith(isRead: true);
            return updated;
          }
          return msg;
        }).toList();

        for (var msg in updatedMessages) {}

        final newState = currentState.copyWith(
          messages: updatedMessages,
          isRead: true,
          replyTo: currentState.replyTo,
          forwardFrom: currentState.forwardFrom,
        );
        emit(newState);
        return;
      }

      if (type == 'message' || type == 'new_message') {
        final newMessage = MessageModel.fromJson(messageData);

        // Проверяем, существует ли уже сообщение с таким ID
        final messageExists =
            currentState.messages.any((msg) => msg.id == newMessage.id);
        if (messageExists) {
          print('📝 Socket: Сообщение уже существует, пропускаем');
          return;
        }

        // Если это новое сообщение от другого пользователя, отправляем статус прочтения
        if (newMessage.senderUsername != _currentUsername) {
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
        ));
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

        // Создаем новое сообщение
        final newMessage = MessageModel(
          id: DateTime.now().millisecondsSinceEpoch,
          chatId: currentState.chat.chatId,
          text: event.caption ?? '',
          senderUsername: _currentUsername ?? 'Unknown',
          createdAt: DateTime.now(),
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
          type: event.file.path.toLowerCase().endsWith('.mp4') ||
                  event.file.path.toLowerCase().endsWith('.mov') ||
                  event.file.path.toLowerCase().endsWith('.avi') ||
                  event.file.path.toLowerCase().endsWith('.webm')
              ? MessageType.video
              : MessageType.image,
        );

        // Обновляем состояние, сохраняя все важные данные
        emit(currentState.copyWith(
          messages: [newMessage, ...currentState.messages],
          replyTo: currentState.replyTo,
          forwardFrom: currentState.forwardFrom,
        ));
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
