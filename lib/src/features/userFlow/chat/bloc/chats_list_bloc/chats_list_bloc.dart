import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chats_list_bloc/chats_list_event.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chats_list_bloc/chats_list_state.dart';
import 'package:tap_map/src/features/userFlow/chat/data/chat_repository.dart';

/// Блок для управления списком чатов
class ChatsListBloc extends Bloc<ChatsListEvent, ChatsListState> {
  final ChatRepository _chatRepository;

  ChatsListBloc({
    required ChatRepository chatRepository,
  })  : _chatRepository = chatRepository,
        super(ChatsListInitial()) {
    on<FetchChatsListEvent>(_onFetchChats);
    on<RefreshChatsListEvent>(_onRefreshChats);
  }

  /// Обработчик события загрузки списка чатов
  Future<void> _onFetchChats(
    FetchChatsListEvent event,
    Emitter<ChatsListState> emit,
  ) async {
    emit(ChatsListLoading());
    try {
      final chats = await _chatRepository.fetchChats();
      emit(ChatsListLoaded(chats));
    } catch (e) {
      emit(ChatsListError('Не удалось загрузить чаты: ${e.toString()}'));
    }
  }

  /// Обработчик события обновления списка чатов
  Future<void> _onRefreshChats(
    RefreshChatsListEvent event,
    Emitter<ChatsListState> emit,
  ) async {
    // Не меняем состояние на Loading при обновлении, чтобы не терять текущие данные
    try {
      final chats = await _chatRepository.fetchChats();
      emit(ChatsListLoaded(chats));
    } catch (e) {
      emit(ChatsListError('Не удалось обновить чаты: ${e.toString()}'));
    }
  }
}
