import 'package:equatable/equatable.dart';
import 'package:tap_map/src/features/userFlow/chat/models/chat_model.dart';

/// Состояния для блока списка чатов
abstract class ChatsListState extends Equatable {
  const ChatsListState();

  @override
  List<Object?> get props => [];
}

/// Начальное состояние
class ChatsListInitial extends ChatsListState {}

/// Состояние загрузки
class ChatsListLoading extends ChatsListState {}

/// Состояние успешной загрузки чатов
class ChatsListLoaded extends ChatsListState {
  final List<ChatModel> chats;

  const ChatsListLoaded(this.chats);

  @override
  List<Object?> get props => [chats];
}

/// Состояние ошибки
class ChatsListError extends ChatsListState {
  final String message;

  const ChatsListError(this.message);

  @override
  List<Object?> get props => [message];
}
