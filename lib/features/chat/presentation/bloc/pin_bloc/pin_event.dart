part of 'pin_bloc.dart';

sealed class PinBlocEvent extends Equatable {
  const PinBlocEvent();

  @override
  List<Object> get props => [];
}

class PinMessage extends PinBlocEvent {
  final int chatId;
  final int messageId;

  const PinMessage({required this.chatId, required this.messageId});

  @override
  List<Object> get props => [chatId, messageId];
}

class UnpinMessage extends PinBlocEvent {
  final int chatId;
  final int messageId;

  const UnpinMessage({required this.chatId, required this.messageId});

  @override
  List<Object> get props => [chatId, messageId];
}

class LoadPinnedMessage extends PinBlocEvent {
  final int chatId;

  const LoadPinnedMessage(this.chatId);

  @override
  List<Object> get props => [chatId];
}
