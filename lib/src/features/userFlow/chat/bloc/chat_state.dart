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

  const ChatLoaded({
    required this.chat,
    required this.messages,
  });

  @override
  List<Object?> get props => [chat, messages];
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
