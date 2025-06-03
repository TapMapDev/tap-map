import 'package:bloc/bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_bloc/chat_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/data/chat_repository.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_websocket_service.dart';

import 'message_actions_event.dart';
import 'message_actions_state.dart';

/// Единый блок для управления действиями с сообщениями 
/// (закрепление, открепление, удаление, редактирование)
class MessageActionsBloc extends Bloc<MessageActionEvent, MessageActionState> {
  final ChatRepository _chatRepository;
  final ChatWebSocketService _chatWebSocketService;
  final ChatBloc _chatBloc;

  MessageActionsBloc({
    required ChatRepository chatRepository,
    required ChatWebSocketService chatWebSocketService,
    required ChatBloc chatBloc,
  })  : _chatRepository = chatRepository,
        _chatWebSocketService = chatWebSocketService,
        _chatBloc = chatBloc,
        super(MessageActionInitial()) {
    // Регистрация обработчиков событий
    on<PinMessageAction>(_onPinMessage);
    on<UnpinMessageAction>(_onUnpinMessage);
    on<LoadPinnedMessageAction>(_onLoadPinnedMessage);
    on<DeleteMessageAction>(_onDeleteMessage);
    on<StartEditingAction>(_onStartEditing);
    on<EditMessageAction>(_onEditMessage);
    on<CancelEditAction>(_onCancelEdit);
  }

  /// Обработка закрепления сообщения
  Future<void> _onPinMessage(
    PinMessageAction event, 
    Emitter<MessageActionState> emit
  ) async {
    try {
      emit(const MessageActionLoading(MessageActionType.pin));
      
      await _chatRepository.pinMessage(
        chatId: event.chatId,
        messageId: event.messageId,
      );

      // Получаем сообщение, которое закрепляем
      final data = await _chatRepository.fetchChatWithMessages(event.chatId);
      final messages = data['messages'] as List<MessageModel>;
      final pinnedMessage = messages.firstWhere(
        (m) => m.id == event.messageId,
        orElse: () => throw Exception('Сообщение не найдено'),
      );

      emit(MessagePinActive(
        pinnedMessage: pinnedMessage,
        chatId: event.chatId,
      ));
    } catch (e) {
      emit(MessageActionFailure(
        actionType: MessageActionType.pin,
        message: 'Ошибка при закреплении: $e',
      ));
    }
  }

  /// Обработка открепления сообщения
  Future<void> _onUnpinMessage(
    UnpinMessageAction event, 
    Emitter<MessageActionState> emit
  ) async {
    try {
      emit(const MessageActionLoading(MessageActionType.unpin));
      
      await _chatRepository.unpinMessage(
        chatId: event.chatId,
        messageId: event.messageId,
      );

      emit(MessagePinEmpty());
    } catch (e) {
      emit(MessageActionFailure(
        actionType: MessageActionType.unpin,
        message: 'Ошибка при откреплении: $e',
      ));
    }
  }

  /// Загрузка закрепленного сообщения
  Future<void> _onLoadPinnedMessage(
    LoadPinnedMessageAction event, 
    Emitter<MessageActionState> emit
  ) async {
    try {
      emit(const MessageActionLoading(MessageActionType.loadPin));

      final result = await _chatRepository.getPinnedMessage(event.chatId);
      
      if (result != null) {
        emit(MessagePinActive(
          pinnedMessage: result,
          chatId: event.chatId,
        ));
      } else {
        emit(MessagePinEmpty());
      }
    } catch (e) {
      emit(MessageActionFailure(
        actionType: MessageActionType.loadPin,
        message: 'Ошибка при загрузке закрепленного сообщения: $e',
      ));
    }
  }

  /// Обработка удаления сообщения
  Future<void> _onDeleteMessage(
    DeleteMessageAction event, 
    Emitter<MessageActionState> emit
  ) async {
    try {
      emit(const MessageActionLoading(MessageActionType.delete));

      // Проверяем, является ли сообщение новым (создано менее 5 секунд назад)
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final messageTime = event.messageId;
      final isNewMessage = currentTime - messageTime < 5000;

      if (!isNewMessage) {
        // Если сообщение не новое, пытаемся удалить через API
        try {
          await _chatRepository.deleteMessage(
            chatId: event.chatId,
            messageId: event.messageId,
            deleteForAll: event.action == 'all',
          );
        } catch (e) {
          // Даже если API удаление не удалось, продолжаем с локальным удалением
        }
      }

      // Обновляем UI через ChatBloc
      _chatBloc.updateMessage(event.messageId, isDeleted: true);

      // В любом случае эмитим успех для локального удаления
      emit(MessageActionSuccess(
        actionType: MessageActionType.delete,
        chatId: event.chatId,
        messageId: event.messageId,
      ));
    } catch (e) {
      emit(MessageActionFailure(
        actionType: MessageActionType.delete,
        message: 'Ошибка при удалении: $e',
      ));
    }
  }

  /// Начало редактирования сообщения
  void _onStartEditing(
    StartEditingAction event, 
    Emitter<MessageActionState> emit
  ) {
    emit(MessageEditInProgress(
      messageId: event.messageId,
      originalText: event.originalText,
    ));
  }

  /// Отмена редактирования
  void _onCancelEdit(
    CancelEditAction event, 
    Emitter<MessageActionState> emit
  ) {
    emit(MessageActionInitial());
  }

  /// Редактирование сообщения
  Future<void> _onEditMessage(
    EditMessageAction event, 
    Emitter<MessageActionState> emit
  ) async {
    try {
      emit(const MessageActionLoading(MessageActionType.edit));

      final success = await _chatRepository.editMessage(
        chatId: event.chatId,
        messageId: event.messageId,
        newText: event.newText,
      );

      if (success) {
        // Обновляем UI через ChatBloc с новым текстом
        _chatBloc.updateMessage(event.messageId, newText: event.newText);
        
        emit(const MessageActionSuccess(
          actionType: MessageActionType.edit,
        ));
      } else {
        emit(const MessageActionFailure(
          actionType: MessageActionType.edit,
          message: 'Не удалось отредактировать сообщение',
        ));
      }
    } catch (e) {
      emit(MessageActionFailure(
        actionType: MessageActionType.edit,
        message: 'Ошибка при редактировании: $e',
      ));
    }
  }
}
