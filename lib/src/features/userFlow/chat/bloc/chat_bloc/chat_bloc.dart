import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_bloc/chat_event.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_bloc/chat_state.dart';
import 'package:tap_map/src/features/userFlow/chat/data/chat_repository.dart';
import 'package:tap_map/src/features/userFlow/chat/models/chat_model.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_websocket_service.dart';

/// Объединенный блок для управления чатами и сообщениями
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final ChatWebSocketService _chatWebSocketService;
  StreamSubscription<WebSocketEventData>? _webSocketSubscription;
  
  /// Текущий активный чат
  int? _currentChatId;
  
  /// Публичный доступ к ChatWebSocketService для других блоков
  ChatWebSocketService get webSocketService => _chatWebSocketService;
  
  /// Конструктор блока
  ChatBloc({
    required ChatRepository chatRepository,
    required ChatWebSocketService chatWebSocketService,
  }) : _chatRepository = chatRepository,
       _chatWebSocketService = chatWebSocketService,
       super(const ChatInitial()) {
    // События для списка чатов
    on<FetchChatsEvent>(_onFetchChats);
    
    // События для конкретного чата
    on<FetchChatEvent>(_onFetchChat);
    on<SendMessageEvent>(_onSendMessage);
    on<NewWebSocketMessageEvent>(_onNewWebSocketMessage);
    on<ChatErrorEvent>(_onChatError);
    
    // События для WebSocket
    on<ConnectToChatEvent>(_onConnectToChat);
    on<DisconnectFromChatEvent>(_onDisconnectFromChat);
    on<SendTypingEvent>(_onSendTyping);
    
    // События для работы с сообщениями
    on<UploadFileEvent>(_onUploadFile);
    on<MarkChatAsReadEvent>(_onMarkChatAsRead);
    on<MarkMessageAsReadEvent>(_onMarkMessageAsRead);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<EditMessageEvent>(_onEditMessage);
    on<PinMessageEvent>(_onPinMessage);
    on<UnpinMessageEvent>(_onUnpinMessage);
    on<GetPinnedMessageEvent>(_onGetPinnedMessage);
    on<SetReplyToMessageEvent>(_onSetReplyToMessage);
    on<SetForwardFromMessageEvent>(_onSetForwardFromMessage);
    on<UpdateMessagesEvent>(_onUpdateMessages);
    
    // Подписываемся на события WebSocket
    _subscribeToWebSocket();
  }
  
  /// Подписка на события WebSocket
  void _subscribeToWebSocket() {
    print('🔄 ChatBloc: Подписываемся на события WebSocket');
    _webSocketSubscription = _chatWebSocketService.events.listen((event) {
      print('🔄 ChatBloc: Получено событие WebSocket: ${event.type}');
      
      if (event.type == WebSocketEventType.message && event.data != null) {
        print('🔄 ChatBloc: Получено событие сообщения: ${event.data}');
        add(NewWebSocketMessageEvent(event.data));
      } else if (event.type == WebSocketEventType.error) {
        print('🔄 ChatBloc: Получено событие ошибки: ${event.error}');
        add(ChatErrorEvent(event.error ?? 'Ошибка WebSocket'));
      } else if (event.type == WebSocketEventType.connection) {
        // Обрабатываем изменения состояния подключения
        final connectionState = event.data?['state'];
        print('🔄 ChatBloc: Изменение состояния соединения: $connectionState');
        
        if (connectionState != null) {
          if (connectionState.toString().contains('connected')) {
            // Если подключение установлено успешно
            print('🔄 ChatBloc: Состояние изменено на ПОДКЛЮЧЕНО');
            if (state is ChatLoaded) {
              final chatLoaded = state as ChatLoaded;
              emit(chatLoaded.copyWith(isConnectionActive: true));
            } else {
              emit(const ChatConnected());
            }
          } else if (connectionState.toString().contains('disconnected') || 
                    connectionState.toString().contains('error')) {
            // Если соединение разорвано или произошла ошибка
            print('🔄 ChatBloc: Состояние изменено на ОТКЛЮЧЕНО/ОШИБКА');
            if (state is ChatLoaded) {
              final chatLoaded = state as ChatLoaded;
              emit(chatLoaded.copyWith(isConnectionActive: false));
            } else {
              emit(const ChatDisconnected(reason: 'Соединение разорвано'));
            }
          }
        }
      }
    });
  }
  
  /// Обработка события загрузки списка чатов
  Future<void> _onFetchChats(
    FetchChatsEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatsLoading());
    try {
      final chats = await _chatRepository.fetchChats();
      emit(ChatsLoaded(chats));
    } catch (e) {
      emit(ChatError(message: 'Ошибка загрузки чатов: $e'));
    }
  }
  
  /// Обработка события загрузки конкретного чата
  Future<void> _onFetchChat(
    FetchChatEvent event,
    Emitter<ChatState> emit,
  ) async {
    _currentChatId = event.chatId;
    
    // Сохраняем текущие сообщения если они есть
    List<MessageModel>? currentMessages;
    if (state is ChatLoaded) {
      currentMessages = (state as ChatLoaded).messages;
    }
    
    emit(ChatLoading(event.chatId, currentMessages: currentMessages));
    
    try {
      // Загружаем данные чата
      final chat = await _chatRepository.getChatById(event.chatId);
      if (chat == null) {
        emit(ChatError(message: 'Чат не найден'));
        return;
      }
      
      // Загружаем сообщения чата
      final messages = await _chatRepository.getMessages(event.chatId);
      
      // Загружаем закрепленное сообщение
      MessageModel? pinnedMessage;
      try {
        final pinnedMessageId = await _chatRepository.getPinnedMessageId(event.chatId);
        if (pinnedMessageId != null) {
          // Ищем закрепленное сообщение среди загруженных сообщений
          pinnedMessage = messages.firstWhere(
            (message) => message.id == pinnedMessageId,
            orElse: () => null,
          );
          
          // Если не нашли в загруженных сообщениях, пробуем загрузить напрямую
          if (pinnedMessage == null) {
            pinnedMessage = await _chatRepository.getMessageById(event.chatId, pinnedMessageId);
          }
        }
      } catch (e) {
        // Логируем ошибку, но продолжаем выполнение - отсутствие закрепленного сообщения не критично
        print('Ошибка при загрузке закрепленного сообщения: $e');
      }
      
      // Отмечаем чат как прочитанный
      await _chatRepository.markChatAsRead(event.chatId);
      
      // Подключаемся к WebSocket если еще не подключены
      bool isConnected = _chatRepository.currentConnectionState == ConnectionState.connected;
      if (!isConnected) {
        _chatRepository.connectToChat();
      }
      
      emit(ChatLoaded(
        chat: chat,
        messages: messages,
        isConnectionActive: isConnected,
        pinnedMessage: pinnedMessage, // Добавляем закрепленное сообщение в состояние
      ));
    } catch (e) {
      emit(ChatError(message: 'Ошибка загрузки чата: $e'));
    }
  }
  
  /// Обработка события отправки сообщения
  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;
    
    final currentState = state as ChatLoaded;
    
    // Проверяем соединение и пытаемся подключиться, если нет соединения
    if (!currentState.isConnectionActive) {
      print('🌐 ChatBloc: Попытка переподключения перед отправкой сообщения...');
      final success = await _chatRepository.connectToChat();
      if (!success) {
        emit(currentState.copyWith());
        add(ChatErrorEvent('Невозможно отправить сообщение пока нет соединения'));
        return;
      }
    }
    
    // Временно отображаем состояние отправки
    emit(ChatSendingMessage(
      chatId: event.chatId,
      messageText: event.text,
    ));
    
    try {
      print('🌐 ChatBloc: Отправка сообщения...');
      final message = await _chatRepository.sendMessage(
        chatId: event.chatId,
        text: event.text,
        replyToId: event.replyToId,
        forwardedFromId: event.forwardedFromId,
        attachments: event.attachments,
      );
      
      // Получаем обновленные сообщения и состояние чата
      if (message != null) {
        print('🌐 ChatBloc: Сообщение успешно отправлено');
        final updatedMessages = [...currentState.messages, message];
        
        emit(currentState.copyWith(
          messages: updatedMessages,
          clearReplyToMessage: true,
          clearForwardFromMessage: true,
          isConnectionActive: true, // Явно устанавливаем флаг соединения
        ));
      } else {
        // Возвращаем предыдущее состояние если сообщение не было отправлено
        print('🌐 ChatBloc: Не удалось отправить сообщение');
        emit(currentState);
        add(ChatErrorEvent('Не удалось отправить сообщение'));
      }
    } catch (e) {
      print('🌐 ChatBloc: Ошибка отправки сообщения: $e');
      emit(currentState);
      add(ChatErrorEvent('Ошибка отправки сообщения: $e'));
    }
  }
  
  /// Обработка нового сообщения от WebSocket
  Future<void> _onNewWebSocketMessage(
    NewWebSocketMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    // Обрабатываем только если у нас открыт чат
    if (state is! ChatLoaded) return;
    
    final currentState = state as ChatLoaded;
    final messageData = event.message;
    
    // Обработка разных типов сообщений
    if (messageData['type'] == 'message') {
      // Обработка нового сообщения
      final processedMessage = await _chatRepository.processWebSocketMessage(messageData);
      
      if (processedMessage != null) {
        // Проверяем, относится ли сообщение к текущему чату
        if (processedMessage.chatId == currentState.chat.chatId) {
          // Добавляем новое сообщение к списку
          final updatedMessages = [...currentState.messages, processedMessage];
          
          emit(currentState.copyWith(
            messages: updatedMessages,
          ));
          
          // Отмечаем сообщение как прочитанное
          _chatRepository.markMessageAsRead(
            chatId: processedMessage.chatId,
            messageId: processedMessage.id,
          );
        }
      }
    } else if (messageData['type'] == 'typing') {
      // Обработка статуса печати
      final chatId = messageData['chatId'] as int?;
      final userId = messageData['userId'] as int?;
      final isTyping = messageData['isTyping'] as bool? ?? false;
      
      if (chatId != null && userId != null && chatId == currentState.chat.chatId) {
        emit(currentState.copyWith(isTyping: isTyping));
      }
    } else if (messageData['type'] == 'read') {
      // Обработка статуса прочтения
      final chatId = messageData['chatId'] as int?;
      final messageId = messageData['messageId'] as int?;
      
      if (chatId != null && messageId != null && chatId == currentState.chat.chatId) {
        // Обновляем статус прочтения сообщения
        final updatedMessages = currentState.messages.map((message) {
          if (message.id == messageId) {
            return message.copyWith(isRead: true);
          }
          return message;
        }).toList();
        
        emit(currentState.copyWith(messages: updatedMessages));
      }
    }
  }
  
  /// Обработка события ошибки чата
  void _onChatError(
    ChatErrorEvent event,
    Emitter<ChatState> emit,
  ) {
    emit(ChatError(
      message: event.message,
      previousState: state is ChatInitial ? null : state,
    ));
  }
  
  /// Обработка события подключения к чату
  Future<void> _onConnectToChat(
    ConnectToChatEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      print('🔄 ChatBloc: Подключаемся к чату');
      final success = await _chatWebSocketService.connect();
      print('🔄 ChatBloc: Результат подключения к WebSocket: ${success ? "успешно" : "неудачно"}');
      
      if (success) {
        emit(const ChatConnected());
      } else {
        emit(const ChatDisconnected(reason: 'Не удалось подключиться к WebSocket'));
      }
    } catch (e) {
      print('🔄 ChatBloc: Ошибка при подключении к чату: $e');
      emit(ChatError(message: e.toString()));
    }
  }
  
  /// Обработка события отключения от чата
  void _onDisconnectFromChat(
    DisconnectFromChatEvent event,
    Emitter<ChatState> emit,
  ) {
    _chatRepository.disconnectFromChat();
    
    if (state is ChatLoaded) {
      final chatLoaded = state as ChatLoaded;
      emit(chatLoaded.copyWith(isConnectionActive: false));
    } else {
      emit(const ChatDisconnected());
    }
  }
  
  /// Обработка события отправки статуса печати
  void _onSendTyping(
    SendTypingEvent event,
    Emitter<ChatState> emit,
  ) {
    _chatRepository.sendTyping(
      chatId: event.chatId,
      isTyping: event.isTyping,
    );
  }
  
  /// Обработка события загрузки файла
  Future<void> _onUploadFile(
    UploadFileEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;
    
    final currentState = state as ChatLoaded;
    
    try {
      // Начинаем загрузку файла
      emit(ChatUploadingFile(
        chatId: event.chatId,
        progress: 0.0,
      ));
      
      // Загружаем файл
      final uploadResult = await _chatRepository.uploadFile(
        file: event.file,
        onProgress: (progress) {
          emit(ChatUploadingFile(
            chatId: event.chatId,
            progress: progress,
          ));
        },
      );
      
      if (uploadResult == null) {
        emit(ChatError(
          message: 'Не удалось загрузить файл',
          previousState: currentState,
        ));
        return;
      }
      
      // Отправляем сообщение с вложением
      add(SendMessageEvent(
        chatId: event.chatId,
        text: event.caption ?? '',
        attachments: [{
          'url': uploadResult,
          'type': _getFileTypeFromExtension(event.file.path),
        }],
      ));
      
    } catch (e) {
      emit(ChatError(
        message: 'Ошибка загрузки файла: $e',
        previousState: currentState,
      ));
    }
  }
  
  /// Обработка события пометки чата как прочитанного
  Future<void> _onMarkChatAsRead(
    MarkChatAsReadEvent event,
    Emitter<ChatState> emit,
  ) async {
    await _chatRepository.markChatAsRead(event.chatId);
    
    // Обновляем состояние только если текущее состояние - загруженный чат
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      // Помечаем все сообщения как прочитанные
      final updatedMessages = currentState.messages.map((message) {
        return message.copyWith(isRead: true);
      }).toList();
      
      emit(currentState.copyWith(messages: updatedMessages));
    }
  }
  
  /// Обработка события пометки сообщения как прочитанного
  Future<void> _onMarkMessageAsRead(
    MarkMessageAsReadEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;
    
    final currentState = state as ChatLoaded;
    
    try {
      // Отмечаем сообщение как прочитанное
      _chatRepository.markMessageAsRead(
        chatId: event.chatId,
        messageId: event.messageId,
      );
      
      // Обновляем статус прочтения сообщения
      final updatedMessages = currentState.messages.map((message) {
        if (message.id == event.messageId) {
          return message.copyWith(isRead: true);
        }
        return message;
      }).toList();
      
      emit(currentState.copyWith(messages: updatedMessages));
    } catch (e) {
      emit(ChatError(
        message: 'Ошибка пометки сообщения как прочитанного: $e',
        previousState: currentState,
      ));
    }
  }
  
  /// Обработка события удаления сообщения
  Future<void> _onDeleteMessage(
    DeleteMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;
    
    final currentState = state as ChatLoaded;
    
    try {
      // Отправляем запрос на удаление сообщения
      final success = await _chatRepository.deleteMessage(
        chatId: event.chatId,
        messageId: event.messageId,
        deleteForAll: event.action == 'all',
      );
      
      if (success) {
        // Обновляем список сообщений
        final updatedMessages = currentState.messages.where((message) {
          return message.id != event.messageId;
        }).toList();
        
        emit(currentState.copyWith(messages: updatedMessages));
      } else {
        emit(ChatError(
          message: 'Не удалось удалить сообщение',
          previousState: currentState,
        ));
      }
    } catch (e) {
      emit(ChatError(
        message: 'Ошибка удаления сообщения: $e',
        previousState: currentState,
      ));
    }
  }
  
  /// Обработка события редактирования сообщения
  Future<void> _onEditMessage(
    EditMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;
    
    final currentState = state as ChatLoaded;
    
    try {
      // Отправляем запрос на редактирование сообщения
      final updatedMessage = await _chatRepository.editMessage(
        chatId: event.chatId,
        messageId: event.messageId,
        text: event.text,
      );
      
      if (updatedMessage != null) {
        // Обновляем сообщение в списке
        final updatedMessages = currentState.messages.map((message) {
          if (message.id == event.messageId) {
            return updatedMessage;
          }
          return message;
        }).toList();
        
        emit(currentState.copyWith(messages: updatedMessages));
      } else {
        emit(ChatError(
          message: 'Не удалось отредактировать сообщение',
          previousState: currentState,
        ));
      }
    } catch (e) {
      emit(ChatError(
        message: 'Ошибка редактирования сообщения: $e',
        previousState: currentState,
      ));
    }
  }
  
  /// Обработка события закрепления сообщения
  Future<void> _onPinMessage(
    PinMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;
    
    final currentState = state as ChatLoaded;
    
    try {
      // Отправляем запрос на закрепление сообщения
      final success = await _chatRepository.pinMessage(
        chatId: event.chatId,
        messageId: event.messageId,
      );
      
      if (success) {
        // Получаем закрепленное сообщение
        add(GetPinnedMessageEvent(event.chatId));
      } else {
        emit(ChatError(
          message: 'Не удалось закрепить сообщение',
          previousState: currentState,
        ));
      }
    } catch (e) {
      emit(ChatError(
        message: 'Ошибка закрепления сообщения: $e',
        previousState: currentState,
      ));
    }
  }
  
  /// Обработка события открепления сообщения
  Future<void> _onUnpinMessage(
    UnpinMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;
    
    final currentState = state as ChatLoaded;
    
    try {
      // Отправляем запрос на открепление сообщения
      final success = await _chatRepository.unpinMessage(
        chatId: event.chatId,
        messageId: event.messageId,
      );
      
      if (success) {
        // Получаем обновленный статус закрепленных сообщений
        add(GetPinnedMessageEvent(event.chatId));
      } else {
        emit(ChatError(
          message: 'Не удалось открепить сообщение',
          previousState: currentState,
        ));
      }
    } catch (e) {
      emit(ChatError(
        message: 'Ошибка открепления сообщения: $e',
        previousState: currentState,
      ));
    }
  }
  
  /// Обработка события получения закрепленного сообщения
  Future<void> _onGetPinnedMessage(
    GetPinnedMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;
    
    final currentState = state as ChatLoaded;
    
    try {
      // Получаем закрепленное сообщение
      final pinnedMessage = await _chatRepository.getPinnedMessage(event.chatId);
      
      // Обновляем чат с закрепленным сообщением
      final updatedChat = currentState.chat.copyWith(
        pinnedMessageId: pinnedMessage?.id,
      );
      
      emit(currentState.copyWith(chat: updatedChat));
    } catch (e) {
      emit(ChatError(
        message: 'Ошибка получения закрепленного сообщения: $e',
        previousState: currentState,
      ));
    }
  }
  
  /// Обработка события установки сообщения для ответа
  void _onSetReplyToMessage(
    SetReplyToMessageEvent event,
    Emitter<ChatState> emit,
  ) {
    if (state is! ChatLoaded) return;
    
    final currentState = state as ChatLoaded;
    emit(currentState.copyWith(replyToMessage: event.message));
  }
  
  /// Обработка события установки сообщения для пересылки
  void _onSetForwardFromMessage(
    SetForwardFromMessageEvent event,
    Emitter<ChatState> emit,
  ) {
    if (state is! ChatLoaded) return;
    
    final currentState = state as ChatLoaded;
    emit(currentState.copyWith(forwardFromMessage: event.message));
  }
  
  /// Обработка события обновления сообщений
  Future<void> _onUpdateMessages(
    UpdateMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded && currentState.chat.chatId == event.chatId) {
      emit(currentState.copyWith(
        messages: event.messages,
      ));
    }
  }
  
  @override
  Future<void> close() {
    _webSocketSubscription?.cancel();
    return super.close();
  }
  
  /// Определяет тип файла на основе расширения
  String _getFileTypeFromExtension(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return 'image';
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return 'video';
      case 'mp3':
      case 'wav':
      case 'ogg':
        return 'audio';
      case 'pdf':
        return 'document';
      default:
        return 'file';
    }
  }
}
