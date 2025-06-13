import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/core/websocket/websocket_service.dart';
import 'package:tap_map/features/userFlow/chat/presentation/bloc/chat_bloc/chat_bloc.dart';
import 'package:tap_map/features/userFlow/chat/data/repositories/chat_repository.dart';

part 'delete_message_event.dart';
part 'delete_message_state.dart';

class DeleteMessageBloc extends Bloc<DeleteMessageEvent, DeleteMessageState> {
  final ChatRepository _chatRepository;
  WebSocketService? _webSocketService;

  DeleteMessageBloc({
    required ChatRepository chatRepository,
    WebSocketService? webSocketService,
  })  : _chatRepository = chatRepository,
        _webSocketService = webSocketService,
        super(DeleteMessageInitial()) {
    on<DeleteMessageRequest>(_onDeleteMessageRequest);
  }

  void setWebSocketService(WebSocketService? webSocketService) {
    _webSocketService = webSocketService;
  }

  Future<void> _onDeleteMessageRequest(
    DeleteMessageRequest event,
    Emitter<DeleteMessageState> emit,
  ) async {
    try {
      emit(DeleteMessageLoading());

      if (_webSocketService == null && event.context != null) {
        try {
          final chatBloc = BlocProvider.of<ChatBloc>(event.context!);
          _webSocketService = chatBloc.webSocketService;
        } catch (_) {}
      }

      // Используем только WebSocket для удаления сообщений
      print('DeleteMessageBloc: Using WebSocket for message deletion');
      if (_webSocketService != null) {
        try {
          _webSocketService!.deleteMessage(
            chatId: event.chatId,
            messageId: event.messageId,
            action: event.action,
          );
          print('DeleteMessageBloc: WebSocket delete message sent');
          emit(DeleteMessageSuccess(
            chatId: event.chatId,
            messageId: event.messageId,
          ));
          print('DeleteMessageBloc: Emitted DeleteMessageSuccess state');
        } catch (e) {
          print('DeleteMessageBloc: Error occurred while deleting via WebSocket: $e');
          emit(DeleteMessageFailure(e.toString()));
          print('DeleteMessageBloc: Emitted DeleteMessageFailure state');
        }
      } else {
        print('DeleteMessageBloc: WebSocketService is null, cannot delete via WebSocket');
        emit(const DeleteMessageFailure('WebSocketService unavailable'));
        print('DeleteMessageBloc: Emitted DeleteMessageFailure state');
      }
    } catch (e) {
      print('DeleteMessageBloc: Error occurred: $e');
      emit(DeleteMessageFailure(e.toString()));
      print('DeleteMessageBloc: Emitted DeleteMessageFailure state');
    }
  }
}
