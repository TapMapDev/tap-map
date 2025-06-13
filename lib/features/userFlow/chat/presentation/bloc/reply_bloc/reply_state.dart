part of 'reply_bloc.dart';

sealed class ReplyState extends Equatable {
  const ReplyState();

  @override
  List<Object> get props => [];
}

final class ReplyInitial extends ReplyState {}

final class ReplyActive extends ReplyState {
  final MessageModel message;

  const ReplyActive(this.message);

  @override
  List<Object> get props => [message];
}
