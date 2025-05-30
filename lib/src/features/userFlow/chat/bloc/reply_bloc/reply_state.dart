part of 'reply_bloc.dart';

/// Состояния для блока ответа на сообщения
sealed class ReplyState extends Equatable {
  const ReplyState();

  @override
  List<Object> get props => [];
}

/// Начальное состояние, когда нет выбранного сообщения для ответа
final class ReplyInitial extends ReplyState {}

/// Состояние активного ответа на сообщение
final class ReplyActive extends ReplyState {
  /// Сообщение, на которое создается ответ
  final MessageModel message;

  const ReplyActive(this.message);

  @override
  List<Object> get props => [message];
}
