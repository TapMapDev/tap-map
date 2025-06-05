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
  Timer? _typingResetTimer;

  // Добавляем геттер для доступа к WebSocketService
  WebSocketService? get webSocketService => _webSocketService;

  String? _currentUsername;
  int? _currentUserId; // Добавляем ID текущего пользователя
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
    on<LocalMessageEdited>(_onLocalMessageEdited);
    on<AutoResetTypingStatus>(_onAutoResetTypingStatus);
    on<MarkMessageReadEvent>(_onMarkMessageRead); // Добавляем обработчик для нового события
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
      // TODO лишнее - можно брать 1 раз
      final token = await _prefsRepository.getAccessToken();
      if (token == null) {
        emit(const ChatError('No access token available'));
        return;
      }

      // TODO лишнее - можно брать 1 раз
      final user = await _userRepository.getCurrentUser();
      _currentUsername = user.username;
      _currentUserId = user.id; // Обновляем ID текущего пользователя

      // TODO лишнее - можно открывать когда в чаты только заходим
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
      print(messageData);
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
        
        // Сбрасываем статус "печатает..." при получении любого сообщения
        // Это решает проблему "зависшего" индикатора
        var mutableState = currentState;
        if (mutableState.isOtherUserTyping) {
          print('⌨️ ChatBloc: Сброс статуса печати, получено новое сообщение');
          final updatedState = mutableState.copyWith(isOtherUserTyping: false);
          emit(updatedState);
          mutableState = updatedState;
        }
        
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

          // TODO мб убрать sender_username из модели приходится лишние запросы
          // TODO либо при открытии чата писать в поле и брать из chat_list[0].chat_name
          var newMessage = MessageModel.fromJson({
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
            newMessage = newMessage.copyWith(isRead: true);
          }

          final updatedMessages = List<MessageModel>.from(mutableState.messages)
            ..insert(0, newMessage);

          print(
              '📨 ChatBloc: Emitting new state with ${updatedMessages.length} messages');
          emit(mutableState.copyWith(
            messages: updatedMessages,
            isRead: true,
            replyTo: mutableState.replyTo,
            forwardFrom: mutableState.forwardFrom,
          ));
        } catch (e) {
          print('❌ ChatBloc: Error getting user info: $e');
        }
        return;
      } else if (type == 'edit_message') {
        final messageId = messageData['message_id'] as int?;
        final newText = messageData['text'] as String?;
        final editedAtStr = messageData['edited_at'] as String?;
        final editedAt =
            editedAtStr != null ? DateTime.parse(editedAtStr) : DateTime.now();

        if (messageId != null && newText != null) {
          final updatedMessages = currentState.messages.map((m) {
            if (m.id == messageId) {
              return m.copyWith(text: newText, editedAt: editedAt);
            }
            return m;
          }).toList();

          emit(currentState.copyWith(messages: updatedMessages));
        }
        return;
      } else if (type == 'read_message') {
        // Обработка события о прочтении сообщения
        final messageId = messageData['message_id'] as int?;
        final chatId = messageData['chat_id'] as int?;
        
        if (messageId != null && chatId != null) {
          print('📖 ChatBloc: Обработка события о прочтении сообщения ID: $messageId в чате: $chatId');
          
          // Обновляем статус прочтения для этого сообщения
          final updatedMessages = currentState.messages.map((message) {
            if (message.id == messageId) {
              return message.copyWith(isRead: true);
            }
            return message;
          }).toList();
          
          emit(currentState.copyWith(messages: updatedMessages));
        }
        return;
      } else if (type == 'message_edited') {
        // Обрабатываем сообщение об отредактированном сообщении
        final chatId = messageData['chat_id'] as int?;
        final messageId = messageData['message_id'] as int?;
        final newText = messageData['text'] as String?;
        final editedAtStr = messageData['edited_at'] as String?;
        final editedAt =
            editedAtStr != null ? DateTime.parse(editedAtStr) : DateTime.now();

        print('📝 ChatBloc: Обработка отредактированного сообщения - id: $messageId, новый текст: $newText');

        if (messageId != null && newText != null && currentState.chat.chatId == chatId) {
          final updatedMessages = currentState.messages.map((m) {
            if (m.id == messageId) {
              print('📝 ChatBloc: Обновление сообщения $messageId с текстом "$newText"');
              return m.copyWith(text: newText, editedAt: editedAt);
            }
            return m;
          }).toList();

          emit(currentState.copyWith(messages: updatedMessages));
        }
        return;
      }

      if (type == 'delete_message') {
        final messageId = messageData['message_id'] as int?;
        if (messageId == null) {
          return;
        }

        final updatedMessages =
            currentState.messages.where((m) => m.id != messageId).toList();

        emit(currentState.copyWith(messages: updatedMessages));

        return;
      }

      if (type == 'message_deleted') {
        // Обрабатываем сообщение об удалении сообщения
        final chatId = messageData['chat_id'] as int?;
        final messageId = messageData['message_id'] as int?;
        final action = messageData['action'] as String?;
        final deletedBy = messageData['deleted_by'] as int?;
        
        print('📝 ChatBloc: Обработка удаленного сообщения - id: $messageId, action: $action, deletedBy: $deletedBy');
        
        if (messageId != null && currentState.chat.chatId == chatId) {
          print('📝 ChatBloc: Удаление сообщения $messageId из списка сообщений');
          final updatedMessages = 
              currentState.messages.where((m) => m.id != messageId).toList();
              
          emit(currentState.copyWith(messages: updatedMessages));
        }
        return;
      } else if (type == 'typing') {
        // Обрабатываем уведомление о печатании сообщения
        final chatId = messageData['chat_id'] as int?;
        final isTyping = messageData['is_typing'] as bool?;
        final userId = messageData['user_id'] as int?;
        
        print('⌨️ ChatBloc: Получено событие typing - chatId: $chatId, userId: $userId, isTyping: $isTyping');
        
        if (chatId != null && isTyping != null && userId != null && currentState.chat.chatId == chatId) {
          // Проверяем, не является ли это нашим собственным событием
          if (userId == _currentUserId) {
            print('⌨️ ChatBloc: Это собственное событие typing, игнорируем');
            return;
          }
          
          print('⌨️ ChatBloc: Пользователь ${isTyping ? "начал печатать" : "перестал печатать"}');
          
          // Обновляем состояние индикатора печати
          emit(currentState.copyWith(isOtherUserTyping: isTyping));
          
          // Для безопасности: если кто-то начал печатать, через 10 секунд сбрасываем статус
          if (isTyping) {
            _typingResetTimer?.cancel();
            _typingResetTimer = Timer(const Duration(seconds: 10), () {
              if (!isClosed) {
                final currentState = state;
                if (currentState is ChatLoaded && currentState.isOtherUserTyping) {
                  print('⌨️ ChatBloc: Автоматический сброс статуса печати (таймаут)');
                  add(const AutoResetTypingStatus());
                }
              }
            });
          }
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

  void _onAutoResetTypingStatus(
    AutoResetTypingStatus event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(isOtherUserTyping: false));
    }
  }

  // Обработчик события отметки сообщения как прочитанного
  Future<void> _onMarkMessageRead(
    MarkMessageReadEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      if (_webSocketService == null) {
        return;
      }
      
      // Вызываем websocket метод для отметки сообщения как прочитанного
      _webSocketService!.readMessage(
        chatId: event.chatId,
        messageId: event.messageId,
      );
      
      // Обновляем состояние, чтобы отметить это сообщение и все предыдущие от того же отправителя как прочитанные
      final currentState = state;
      if (currentState is ChatLoaded) {
        String? senderUsername;
        
        // Находим отправителя сообщения, которое мы пометили как прочитанное
        for (var message in currentState.messages) {
          if (message.id == event.messageId) {
            senderUsername = message.senderUsername;
            break;
          }
        }
        
        if (senderUsername != null && senderUsername != _currentUsername) {
          // Обновляем все сообщения от этого отправителя, которые имеют timestamp меньше или равный текущему сообщению
          final timestamp = currentState.messages
              .firstWhere((m) => m.id == event.messageId, 
                  orElse: () => MessageModel.empty())
              .createdAt;
              
          final updatedMessages = currentState.messages.map((message) {
            // Если сообщение от того же отправителя, было отправлено до или одновременно
            // с текущим сообщением, и оно не прочитано, то помечаем его как прочитанное
            if (message.senderUsername == senderUsername &&
                !message.isRead &&
                (message.createdAt.isBefore(timestamp) || message.createdAt.isAtSameMomentAs(timestamp))) {
              return message.copyWith(isRead: true);
            }
            return message;
          }).toList();

          emit(currentState.copyWith(messages: updatedMessages));
        }
      }
    } catch (e) {
      print('❌ ChatBloc: Ошибка при отметке сообщения как прочитанного: $e');
      // Не эмиттим состояние ошибки, чтобы не прерывать работу пользователя
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    _webSocketService?.disconnect();
    _typingResetTimer?.cancel();
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

  void _onLocalMessageEdited(
    LocalMessageEdited event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    final updatedMessages = currentState.messages.map((message) {
      if (message.id == event.messageId) {
        return message.copyWith(
          text: event.newText,
          editedAt: event.editedAt,
        );
      }
      return message;
    }).toList();

    emit(currentState.copyWith(messages: updatedMessages));
  }
}
