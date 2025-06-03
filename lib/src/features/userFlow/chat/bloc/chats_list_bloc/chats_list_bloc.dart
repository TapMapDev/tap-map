import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chats_list_bloc/chats_list_event.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chats_list_bloc/chats_list_state.dart';
import 'package:tap_map/src/features/userFlow/chat/data/chat_repository.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_websocket_service.dart';
import '../../models/chat_model.dart';

/// Блок для управления списком чатов
class ChatsListBloc extends Bloc<ChatsListEvent, ChatsListState> {
  final ChatRepository _chatRepository;
  StreamSubscription<List<ChatModel>>? _chatsSub;
  StreamSubscription<WebSocketEventData>? _wsSub;

  ChatsListBloc({
    required ChatRepository chatRepository,
  })  : _chatRepository = chatRepository,
        super(ChatsListInitial()) {
    on<FetchChatsListEvent>(_onFetchChats);
    on<RefreshChatsListEvent>(_onRefreshChats);
    on<ChatsUpdatedEvent>(_onChatsUpdated);

    _chatsSub = _chatRepository.watchChats().listen(
      (chats) => add(ChatsUpdatedEvent(chats)),
    );

    _wsSub = _chatRepository.webSocketEvents.listen((event) {
      if (event.type == WebSocketEventType.message && event.data != null) {
        _chatRepository.processWebSocketMessage(event.data!);
      }
    });
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

  void _onChatsUpdated(
    ChatsUpdatedEvent event,
    Emitter<ChatsListState> emit,
  ) {
    emit(ChatsListLoaded(event.chats));
  }

  @override
  Future<void> close() {
    _chatsSub?.cancel();
    _wsSub?.cancel();
    return super.close();
  }
}
