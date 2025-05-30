part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatsLoaded extends ChatState {
  final List<ChatModel> chats;

  const ChatsLoaded(this.chats);

  @override
  List<Object?> get props => [chats];
}

class ChatLoaded extends ChatState with EquatableMixin {
  final ChatModel chat;
  final List<MessageModel> messages;
  final MessageModel? replyTo;
  final MessageModel? forwardFrom;
  final bool isRead;
  final Set<String> typingUsers;

  ChatLoaded({
    required this.chat,
    required this.messages,
    this.replyTo,
    this.forwardFrom,
    this.isRead = false,
    this.typingUsers = const {},
  });

  @override
  List<Object?> get props => [
        chat,
        messages,
        replyTo,
        forwardFrom,
        isRead,
        typingUsers,
      ];

  ChatLoaded copyWith({
    ChatModel? chat,
    List<MessageModel>? messages,
    MessageModel? replyTo,
    MessageModel? forwardFrom,
    bool? isRead,
    Set<String>? typingUsers,
  }) {
    return ChatLoaded(
      chat: chat ?? this.chat,
      messages: messages ?? this.messages,
      forwardFrom: forwardFrom ?? this.forwardFrom,
      isRead: isRead ?? this.isRead,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }
}

class MessageSent extends ChatState {
  final MessageModel message;

  const MessageSent(this.message);

  @override
  List<Object?> get props => [message];
}

class MessageReceived extends ChatState {
  final dynamic message;

  const MessageReceived({required this.message});

  @override
  List<Object?> get props => [message];
}

class TypingStatus extends ChatState {
  final int chatId;
  final int userId;
  final bool isTyping;

  const TypingStatus({
    required this.chatId,
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [chatId, userId, isTyping];
}

class MessageRead extends ChatState {
  final int messageId;
  final int userId;

  const MessageRead({
    required this.messageId,
    required this.userId,
  });

  @override
  List<Object?> get props => [messageId, userId];
}

class ChatConnected extends ChatState {}

class ChatDisconnected extends ChatState {}

class FileUploaded extends ChatState {
  final String filePath;

  const FileUploaded(this.filePath);
}
