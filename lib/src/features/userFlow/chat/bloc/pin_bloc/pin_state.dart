part of 'pin_bloc.dart';

sealed class PinBlocState extends Equatable {
  const PinBlocState();

  @override
  List<Object?> get props => [];
}

class PinBlocInitial extends PinBlocState {}

class MessagePinned extends PinBlocState {
  final MessageModel pinnedMessage;
  final int chatId;

  const MessagePinned({
    required this.pinnedMessage,
    required this.chatId,
  });

  @override
  List<Object?> get props => [pinnedMessage, chatId];
}

class NoPinnedMessage extends PinBlocState {}

class PinBlocError extends PinBlocState {
  final String message;

  const PinBlocError(this.message);

  @override
  List<Object?> get props => [message];
}
