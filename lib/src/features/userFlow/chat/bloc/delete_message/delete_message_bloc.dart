import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/core/websocket/websocket_service.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_bloc/chat_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/data/chat_repository.dart';

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

      // Проверяем, является ли сообщение новым (созданным менее 5 секунд назад)
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final messageTime = event.messageId;
      final isNewMessage = currentTime - messageTime < 5000;

      print(
          'DeleteMessageBloc: Message time: $messageTime, Current time: $currentTime, Diff: ${currentTime - messageTime}ms');
      print('DeleteMessageBloc: Is new message: $isNewMessage');

      // Используем только WebSocket для удаления сообщений
      print('DeleteMessageBloc: Using WebSocket for message deletion');
      if (_webSocketService != null) {
        _webSocketService!.deleteMessage(
          chatId: event.chatId,
          messageId: event.messageId,
          action: event.action,
        );
        print('DeleteMessageBloc: WebSocket delete message sent');
      } else {
        print('DeleteMessageBloc: WebSocketService is null, cannot delete via WebSocket');
      }

      // В любом случае эмитим успех для локального удаления
      emit(DeleteMessageSuccess(
        chatId: event.chatId,
        messageId: event.messageId,
      ));
      print('DeleteMessageBloc: Emitted DeleteMessageSuccess state');
    } catch (e) {
      print('DeleteMessageBloc: Error occurred: $e');
      emit(DeleteMessageFailure(e.toString()));
      print('DeleteMessageBloc: Emitted DeleteMessageFailure state');
    }
  }
}
