part of 'delete_message_bloc.dart';

abstract class DeleteMessageEvent extends Equatable {
  const DeleteMessageEvent();

  @override
  List<Object> get props => [];
}

class DeleteMessageRequest extends DeleteMessageEvent {
  final int chatId;
  final int messageId;
  final String action;

  const DeleteMessageRequest({
    required this.chatId,
    required this.messageId,
    required this.action,
  });

  @override
  List<Object> get props => [chatId, messageId, action];
}
