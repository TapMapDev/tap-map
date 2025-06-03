import 'package:equatable/equatable.dart';
import 'package:tap_map/src/features/userFlow/chat/models/chat_model.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

/// Состояния для объединенного ChatBloc
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

//
// НАЧАЛЬНОЕ СОСТОЯНИЕ
//

/// Начальное состояние
class ChatInitial extends ChatState {
  const ChatInitial();
}

//
// СОСТОЯНИЯ СПИСКА ЧАТОВ
//

/// Загрузка списка чатов
class ChatsLoading extends ChatState {
  const ChatsLoading();
}

/// Список чатов загружен
class ChatsLoaded extends ChatState {
  final List<ChatModel> chats;

  const ChatsLoaded(this.chats);

  @override
  List<Object?> get props => [chats];
}

//
// СОСТОЯНИЯ ЧАТА
//

/// Загрузка данных чата
class ChatLoading extends ChatState {
  final int chatId;
  final List<MessageModel>? currentMessages; // Для сохранения текущих сообщений при обновлении
  
  const ChatLoading(this.chatId, {this.currentMessages});
  
  @override
  List<Object?> get props => [chatId, currentMessages];
}

/// Чат загружен
class ChatLoaded extends ChatState {
  final ChatModel chat;
  final List<MessageModel> messages;
  final bool isConnectionActive;
  final bool isTyping;
  final bool isUserTyping;
  final String? typingUsername;
  final MessageModel? replyToMessage;
  final MessageModel? forwardFromMessage;
  final Set<String> typingUsers;
  final MessageModel? pinnedMessage;
  final DateTime? lastUpdated;
  
  const ChatLoaded({
    required this.chat,
    required this.messages,
    this.isConnectionActive = false,
    this.isTyping = false,
    this.isUserTyping = false,
    this.typingUsername,
    this.replyToMessage,
    this.forwardFromMessage,
    this.typingUsers = const {},
    this.pinnedMessage,
    this.lastUpdated,
  });
  
  /// Создать новое состояние на основе текущего
  ChatLoaded copyWith({
    ChatModel? chat,
    List<MessageModel>? messages,
    bool? isConnectionActive,
    bool? isTyping,
    bool? isUserTyping,
    String? typingUsername,
    MessageModel? replyToMessage,
    bool clearReplyToMessage = false,
    MessageModel? forwardFromMessage,
    bool clearForwardFromMessage = false,
    Set<String>? typingUsers,
    MessageModel? pinnedMessage,
    bool clearPinnedMessage = false,
    DateTime? lastUpdated,
  }) {
    return ChatLoaded(
      chat: chat ?? this.chat,
      messages: messages ?? this.messages,
      isConnectionActive: isConnectionActive ?? this.isConnectionActive,
      isTyping: isTyping ?? this.isTyping,
      isUserTyping: isUserTyping ?? this.isUserTyping,
      typingUsername: typingUsername,
      replyToMessage: clearReplyToMessage ? null : replyToMessage ?? this.replyToMessage,
      forwardFromMessage: clearForwardFromMessage ? null : forwardFromMessage ?? this.forwardFromMessage,
      typingUsers: typingUsers ?? this.typingUsers,
      pinnedMessage: clearPinnedMessage ? null : pinnedMessage ?? this.pinnedMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  @override
  List<Object?> get props => [chat, messages, isConnectionActive, isTyping, isUserTyping, typingUsername, replyToMessage, forwardFromMessage, typingUsers, pinnedMessage, lastUpdated];
}

//
// СОСТОЯНИЯ ДЕЙСТВИЙ
//

/// Отправка сообщения
class ChatSendingMessage extends ChatState {
  final int chatId;
  final String messageText;
  
  const ChatSendingMessage({
    required this.chatId,
    required this.messageText,
  });
  
  @override
  List<Object?> get props => [chatId, messageText];
}

/// Отправка файла
class ChatUploadingFile extends ChatState {
  final int chatId;
  final double progress;
  
  const ChatUploadingFile({
    required this.chatId,
    required this.progress,
  });
  
  @override
  List<Object?> get props => [chatId, progress];
}

/// Ошибка в чате
class ChatError extends ChatState {
  final String message;
  final ChatState? previousState;
  
  const ChatError({
    required this.message,
    this.previousState,
  });
  
  @override
  List<Object?> get props => [message, previousState];
}

//
// СОСТОЯНИЯ СОЕДИНЕНИЯ
//

/// Соединение устанавливается
class ChatConnecting extends ChatState {
  const ChatConnecting();
}

/// Соединение установлено
class ChatConnected extends ChatState {
  const ChatConnected();
}

/// Соединение разорвано
class ChatDisconnected extends ChatState {
  final String? reason;
  
  const ChatDisconnected({this.reason});
  
  @override
  List<Object?> get props => [reason];
}

/// Переподключение
class ChatReconnecting extends ChatState {
  final int attemptNumber;
  final int maxAttempts;
  
  const ChatReconnecting({
    required this.attemptNumber,
    required this.maxAttempts,
  });
  
  @override
  List<Object?> get props => [attemptNumber, maxAttempts];
}
