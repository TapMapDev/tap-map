import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class FetchChats extends ChatEvent {}

class FetchChatById extends ChatEvent {
  final int chatId;

  const FetchChatById(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class SendMessage extends ChatEvent {
  final int chatId;
  final String text;

  const SendMessage({
    required this.chatId,
    required this.text,
  });

  @override
  List<Object?> get props => [chatId, text];
}

class SendTyping extends ChatEvent {
  final int chatId;

  const SendTyping(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class MarkMessageAsRead extends ChatEvent {
  final int chatId;

  const MarkMessageAsRead(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class TogglePinChat extends ChatEvent {
  final int chatId;

  const TogglePinChat(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class NewMessageEvent extends ChatEvent {
  final Map<String, dynamic> message;

  const NewMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class UserTypingEvent extends ChatEvent {
  final int userId;
  final bool isTyping;

  const UserTypingEvent({
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [userId, isTyping];
}

class ChatErrorEvent extends ChatEvent {
  final String message;

  const ChatErrorEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class SendReadReceipt extends ChatEvent {
  final int messageId;

  const SendReadReceipt(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class NewMessageReceived extends ChatEvent {
  final dynamic message;

  const NewMessageReceived({required this.message});

  @override
  List<Object?> get props => [message];
}

class TypingReceived extends ChatEvent {
  final int chatId;
  final int userId;

  const TypingReceived({
    required this.chatId,
    required this.userId,
  });

  @override
  List<Object?> get props => [chatId, userId];
}

class ReadReceiptReceived extends ChatEvent {
  final int messageId;
  final int userId;

  const ReadReceiptReceived({
    required this.messageId,
    required this.userId,
  });

  @override
  List<Object?> get props => [messageId, userId];
}
