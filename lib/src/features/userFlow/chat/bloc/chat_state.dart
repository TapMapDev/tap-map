import 'package:equatable/equatable.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';

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

class ChatLoaded extends ChatState {
  final ChatModel chat;
  final List<MessageModel> messages;
  final MessageModel? replyTo;

  const ChatLoaded({
    required this.chat,
    required this.messages,
    this.replyTo,
  });

  ChatLoaded copyWith({
    ChatModel? chat,
    List<MessageModel>? messages,
    MessageModel? replyTo,
  }) {
    return ChatLoaded(
      chat: chat ?? this.chat,
      messages: messages ?? this.messages,
      replyTo: replyTo ?? this.replyTo,
    );
  }

  @override
  List<Object?> get props => [chat, messages, replyTo];
}

class MessageSent extends ChatState {
  final MessageModel message;

  const MessageSent(this.message);

  @override
  List<Object?> get props => [message];
}

class NewMessageReceived extends ChatState {
  final MessageModel message;

  const NewMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class UserTyping extends ChatState {
  final int userId;
  final bool isTyping;

  const UserTyping({
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [userId, isTyping];
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

class MessageDeleted extends ChatState {
  final int messageId;

  const MessageDeleted(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class MessageEdited extends ChatState {
  final int messageId;
  final String newText;

  const MessageEdited({
    required this.messageId,
    required this.newText,
  });

  @override
  List<Object?> get props => [messageId, newText];
}
