import 'package:equatable/equatable.dart';
import 'package:tap_map/src/features/userFlow/chat/models/chat_model.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

abstract class ChatMessagesState extends Equatable {
  const ChatMessagesState();

  @override
  List<Object?> get props => [];
}

class ChatMessagesInitial extends ChatMessagesState {}

class ChatMessagesLoading extends ChatMessagesState {}

class ChatMessagesError extends ChatMessagesState {
  final String message;

  const ChatMessagesError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatMessagesLoaded extends ChatMessagesState with EquatableMixin {
  final ChatModel chat;
  final List<MessageModel> messages;
  final MessageModel? replyTo;
  final MessageModel? forwardFrom;
  final bool isRead;
  final Set<String> typingUsers;

  const ChatMessagesLoaded({
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

  ChatMessagesLoaded copyWith({
    ChatModel? chat,
    List<MessageModel>? messages,
    MessageModel? replyTo,
    MessageModel? forwardFrom,
    bool? isRead,
    Set<String>? typingUsers,
  }) {
    return ChatMessagesLoaded(
      chat: chat ?? this.chat,
      messages: messages ?? this.messages,
      replyTo: replyTo,
      forwardFrom: forwardFrom ?? this.forwardFrom,
      isRead: isRead ?? this.isRead,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }
}

class ChatMessagesConnected extends ChatMessagesState {}

class ChatMessagesDisconnected extends ChatMessagesState {}
