part of 'reply_bloc.dart';

/// События для блока ответа на сообщения
sealed class ReplyEvent extends Equatable {
  const ReplyEvent();

  @override
  List<Object> get props => [];
}

/// Событие выбора сообщения для ответа
class SetReplyTo extends ReplyEvent {
  /// Сообщение, на которое создается ответ
  final MessageModel message; 
  const SetReplyTo(this.message);

  @override
  List<Object> get props => [message];
}

/// Событие отмены ответа на сообщение
class ClearReplyTo extends ReplyEvent {
  const ClearReplyTo(); 

  @override
  List<Object> get props => [];
}
