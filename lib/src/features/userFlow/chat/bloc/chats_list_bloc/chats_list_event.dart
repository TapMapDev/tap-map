import 'package:equatable/equatable.dart';
import '../../models/chat_model.dart';

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

/// Внутреннее событие при обновлении списка чатов через стрим
class ChatsUpdatedEvent extends ChatsListEvent {
  final List<ChatModel> chats;

  const ChatsUpdatedEvent(this.chats);

  @override
  List<Object?> get props => [chats];
}
