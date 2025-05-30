import 'package:equatable/equatable.dart';

abstract class ChatMessagesEvent extends Equatable {
  const ChatMessagesEvent();

  @override
  List<Object?> get props => [];
}

class FetchChatMessagesEvent extends ChatMessagesEvent {
  final int chatId;

  const FetchChatMessagesEvent(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class SendMessageEvent extends ChatMessagesEvent {
  final int chatId;
  final String text;
  final int? replyToId;
  final int? forwardedFromId;

  const SendMessageEvent({
    required this.chatId,
    required this.text,
    this.replyToId,
    this.forwardedFromId,
  });

  @override
  List<Object?> get props => [chatId, text, replyToId, forwardedFromId];
}

class MarkMessageAsReadEvent extends ChatMessagesEvent {
  final int messageId;
  final int chatId;

  const MarkMessageAsReadEvent({
    required this.messageId,
    required this.chatId,
  });

  @override
  List<Object?> get props => [messageId, chatId];
}

class NewWebSocketMessageEvent extends ChatMessagesEvent {
  final dynamic message;

  const NewWebSocketMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatMessagesErrorEvent extends ChatMessagesEvent {
  final String message;

  const ChatMessagesErrorEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class ConnectToChatMessagesEvent extends ChatMessagesEvent {
  const ConnectToChatMessagesEvent();
}

class DisconnectFromChatMessagesEvent extends ChatMessagesEvent {
  const DisconnectFromChatMessagesEvent();
}

class SendTypingEvent extends ChatMessagesEvent {
  final int chatId;
  final bool isTyping;

  const SendTypingEvent({
    required this.chatId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [chatId, isTyping];
}
