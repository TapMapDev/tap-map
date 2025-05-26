part of 'chat_bloc.dart';

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
  final int? replyToId;
  final int? forwardedFromId;

  const SendMessage({
    required this.chatId,
    required this.text,
    this.replyToId,
    this.forwardedFromId,
  });

  @override
  List<Object?> get props => [chatId, text, replyToId, forwardedFromId];
}

class SendTyping extends ChatEvent {
  final int chatId;
  final bool isTyping;

  const SendTyping({
    required this.chatId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [chatId, isTyping];
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
  final dynamic message;

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

class ConnectToChat extends ChatEvent {
  final int chatId;

  const ConnectToChat(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class DisconnectFromChat extends ChatEvent {}

class EditMessage extends ChatEvent {
  final int chatId;
  final int messageId;
  final String text;

  const EditMessage({
    required this.chatId,
    required this.messageId,
    required this.text,
  });

  @override
  List<Object?> get props => [chatId, messageId, text];
}
class UploadFile extends ChatEvent {
  final File file;
  final String? caption;

  const UploadFile({
    required this.file,
    this.caption,
  });

  @override
  List<Object?> get props => [file, caption];
}
