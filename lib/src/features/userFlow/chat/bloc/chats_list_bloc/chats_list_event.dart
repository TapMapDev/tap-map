import 'package:equatable/equatable.dart';

/// События для блока списка чатов
abstract class ChatsListEvent extends Equatable {
  const ChatsListEvent();

  @override
  List<Object?> get props => [];
}

/// Событие для получения списка чатов
class FetchChatsListEvent extends ChatsListEvent {
  const FetchChatsListEvent();
}

/// Событие для обновления списка чатов
class RefreshChatsListEvent extends ChatsListEvent {
  const RefreshChatsListEvent();
}
