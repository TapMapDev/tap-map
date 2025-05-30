part of 'chat_bloc.dart';

import 'package:equatable/equatable.dart';
import 'package:tap_map/src/features/userFlow/chat/models/chat_model.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatConnected extends ChatState {}

class ChatDisconnected extends ChatState {}

class ChatsLoaded extends ChatState {
  final List<ChatModel> chats;

  const ChatsLoaded({required this.chats});

  @override
  List<Object?> get props => [chats];
}

class ChatLoaded extends ChatState {
  final ChatModel chat;
  final List<MessageModel> messages;
  final bool isRead;
  final MessageModel? replyTo;
  final MessageModel? forwardFrom;
  final int? pinnedMessageId;
  final MessageModel? pinnedMessage;
  final bool isTyping;

  const ChatLoaded({
    required this.chat,
    required this.messages,
    this.isRead = false,
    this.replyTo,
    this.forwardFrom,
    this.pinnedMessageId,
    this.pinnedMessage,
    this.isTyping = false,
  });

  ChatLoaded copyWith({
    ChatModel? chat,
    List<MessageModel>? messages,
    bool? isRead,
    MessageModel? replyTo,
    MessageModel? forwardFrom,
    int? pinnedMessageId,
    MessageModel? pinnedMessage,
    bool? isTyping,
  }) {
    return ChatLoaded(
      chat: chat ?? this.chat,
      messages: messages ?? this.messages,
      isRead: isRead ?? this.isRead,
      replyTo: replyTo ?? this.replyTo,
      forwardFrom: forwardFrom ?? this.forwardFrom,
      pinnedMessageId: pinnedMessageId ?? this.pinnedMessageId,
      pinnedMessage: pinnedMessage ?? this.pinnedMessage,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  @override
  List<Object?> get props => [
        chat,
        messages,
        isRead,
        replyTo,
        forwardFrom,
        pinnedMessageId,
        pinnedMessage,
        isTyping,
      ];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
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

class FileUploaded extends ChatState {
  final String filePath;

  const FileUploaded(this.filePath);
}
