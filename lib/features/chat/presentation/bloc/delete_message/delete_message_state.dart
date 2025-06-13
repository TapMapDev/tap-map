part of 'delete_message_bloc.dart';

abstract class DeleteMessageState extends Equatable {
  const DeleteMessageState();

  @override
  List<Object> get props => [];
}

class DeleteMessageInitial extends DeleteMessageState {}

class DeleteMessageLoading extends DeleteMessageState {}

class DeleteMessageSuccess extends DeleteMessageState {
  final int chatId;
  final int messageId;

  const DeleteMessageSuccess({
    required this.chatId,
    required this.messageId,
  });

  @override
  List<Object> get props => [chatId, messageId];
}

class DeleteMessageFailure extends DeleteMessageState {
  final String error;

  const DeleteMessageFailure(this.error);

  @override
  List<Object> get props => [error];
}
