import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/core/websocket/websocket_service.dart';
import 'package:tap_map/features/chat/data/repositories/chat_repository.dart';
import 'package:tap_map/features/chat/presentation/bloc/chat_bloc/chat_bloc.dart';

part 'edit_event.dart';
part 'edit_state.dart';

class EditBloc extends Bloc<EditEvent, EditState> {
  final ChatRepository _chatRepository;
  WebSocketService? _webSocketService;

  EditBloc({
    required ChatRepository chatRepository,
    WebSocketService? webSocketService,
  })  : _chatRepository = chatRepository,
        _webSocketService = webSocketService,
        super(EditInitial()) {
    on<StartEditing>(_onStartEditing);
    on<EditMessageRequest>(_onEditMessageRequest);
    on<CancelEdit>(_onCancelEdit);
  }

  /// Устанавливает WebSocketService после инициализации блока
  void setWebSocketService(WebSocketService? webSocketService) {
    _webSocketService = webSocketService;
  }

  void _onStartEditing(StartEditing event, Emitter<EditState> emit) {
    print('EditBloc: _onStartEditing called');
    print('Message ID: ${event.messageId}');
    print('Original text: ${event.originalText}');
    emit(EditInProgress(
      messageId: event.messageId,
      originalText: event.originalText,
    ));
    print('EditBloc: Emitted EditInProgress state');
  }

  void _onCancelEdit(CancelEdit event, Emitter<EditState> emit) {
    print('EditBloc: _onCancelEdit called');
    emit(EditInitial());
    print('EditBloc: Emitted EditInitial state');
  }

  Future<void> _onEditMessageRequest(
    EditMessageRequest event,
    Emitter<EditState> emit,
  ) async {
    print('EditBloc: _onEditMessageRequest called');
    print('Chat ID: ${event.chatId}');
    print('Message ID: ${event.messageId}');
    print('New text: ${event.text}');
    try {
      emit(EditLoading());
      print('EditBloc: Emitted EditLoading state');

      // Попытка получить WebSocketService только если передан context
      if (_webSocketService == null && event.context != null) {
        print('EditBloc: Attempting to get WebSocketService from context');
        try {
          final chatBloc = BlocProvider.of<ChatBloc>(event.context!);
          _webSocketService = chatBloc.webSocketService;
          print(
              'EditBloc: Successfully got WebSocketService from ChatBloc: ${_webSocketService != null}');
        } catch (e) {
          print('EditBloc: Failed to get WebSocketService: $e');
        }
      }

      // Если WebSocketService доступен, используем его
      if (_webSocketService != null) {
        print('EditBloc: Using WebSocketService to edit message');
        try {
          _webSocketService!.editMessage(
            chatId: event.chatId,
            messageId: event.messageId,
            text: event.text,
          );
          print('EditBloc: Edit message sent through WebSocket');
        } catch (e) {
          print('EditBloc: Failed to send edit message through WebSocket: $e');
        }
      } else {
        print(
            'EditBloc: WebSocketService not available, proceeding with API only');
      }

      // Проверяем, является ли сообщение новым (созданным менее 5 секунд назад)
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final messageTime = event.messageId;
      final isNewMessage = currentTime - messageTime < 5000;

      print(
          'EditBloc: Message time: $messageTime, Current time: $currentTime, Diff: ${currentTime - messageTime}ms');
      print('EditBloc: Is new message: $isNewMessage');

      if (!isNewMessage) {
        // В любом случае обновляем через API, если это не новое сообщение
        print('EditBloc: Updating message through API');
        try {
          await _chatRepository.editMessage(
              event.chatId, event.messageId, event.text);
          print('EditBloc: API update successful');
        } catch (e) {
          print(
              'EditBloc: API update failed, but continuing with WebSocket update: $e');
        }
      } else {
        print('EditBloc: Skipping API update for new message');
      }

      // Эмитим успех
      emit(EditSuccess(
        chatId: event.chatId,
        messageId: event.messageId,
        newText: event.text,
        editedAt: DateTime.now(),
      ));
      print('EditBloc: Emitted EditSuccess state');
    } catch (e) {
      print('EditBloc: Error occurred: $e');
      emit(EditFailure(e.toString()));
      print('EditBloc: Emitted EditFailure state');
    }
  }
}
