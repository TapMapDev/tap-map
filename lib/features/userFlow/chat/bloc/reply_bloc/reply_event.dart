part of 'reply_bloc.dart';

sealed class ReplyEvent extends Equatable {
  const ReplyEvent();

  @override
  List<Object> get props => [];
}

class SetReplyTo extends ReplyEvent {
  final MessageModel message; 
  const SetReplyTo(this.message);

  @override
  List<Object> get props => [message];
}

class ClearReplyTo extends ReplyEvent {
  const ClearReplyTo(); 

  @override
  List<Object> get props => [];
}

