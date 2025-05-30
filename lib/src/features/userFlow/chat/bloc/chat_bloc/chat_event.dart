part of 'chat_bloc.dart';

import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class FetchChatsEvent extends ChatEvent {
  const FetchChatsEvent();
}

class FetchChatEvent extends ChatEvent {
  final int chatId;

  const FetchChatEvent(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class SendMessage extends ChatEvent {
  final int chatId;
  final String text;
  final int? replyToId;
  final int? forwardedFromId;
  final List<Map<String, String>>? attachments;

  const SendMessage({
    required this.chatId,
    required this.text,
    this.replyToId,
    this.forwardedFromId,
    this.attachments,
  });

  @override
  List<Object?> get props => [chatId, text, replyToId, forwardedFromId, attachments];
}

class NewMessageEvent extends ChatEvent {
  final dynamic message;

  const NewMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatErrorEvent extends ChatEvent {
  final String message;

  const ChatErrorEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class ConnectToChat extends ChatEvent {
  const ConnectToChat();
}

class DisconnectFromChat extends ChatEvent {
  const DisconnectFromChat();
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

class MarkChatAsReadEvent extends ChatEvent {
  final int chatId;

  const MarkChatAsReadEvent(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class DeleteMessageEvent extends ChatEvent {
  final int chatId;
  final int messageId;
  final String action; // 'self' или 'all'

  const DeleteMessageEvent({
    required this.chatId,
    required this.messageId,
    required this.action,
  });

  @override
  List<Object?> get props => [chatId, messageId, action];
}

class EditMessageEvent extends ChatEvent {
  final int chatId;
  final int messageId;
  final String text;

  const EditMessageEvent({
    required this.chatId,
    required this.messageId,
    required this.text,
  });

  @override
  List<Object?> get props => [chatId, messageId, text];
}

class PinMessageEvent extends ChatEvent {
  final int chatId;
  final int messageId;

  const PinMessageEvent({
    required this.chatId,
    required this.messageId,
  });

  @override
  List<Object?> get props => [chatId, messageId];
}

class UnpinMessageEvent extends ChatEvent {
  final int chatId;
  final int messageId;

  const UnpinMessageEvent({
    required this.chatId,
    required this.messageId,
  });

  @override
  List<Object?> get props => [chatId, messageId];
}

class GetPinnedMessageEvent extends ChatEvent {
  final int chatId;

  const GetPinnedMessageEvent(this.chatId);

  @override
  List<Object?> get props => [chatId];
}
