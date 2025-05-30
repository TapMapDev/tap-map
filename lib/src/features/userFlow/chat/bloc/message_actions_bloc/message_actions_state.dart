import 'package:equatable/equatable.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

/// Тип операции с сообщением для определения состояния
enum MessageActionType {
  pin,
  unpin,
  loadPin,
  delete,
  edit,
}

/// Базовое состояние для всех действий с сообщениями
sealed class MessageActionState extends Equatable {
  const MessageActionState();

  @override
  List<Object?> get props => [];
}

/// Начальное состояние
class MessageActionInitial extends MessageActionState {}

/// Состояние загрузки
class MessageActionLoading extends MessageActionState {
  final MessageActionType actionType;

  const MessageActionLoading(this.actionType);

  @override
  List<Object?> get props => [actionType];
}

/// Успешное выполнение действия с сообщением
class MessageActionSuccess extends MessageActionState {
  final MessageActionType actionType;
  final int chatId;
  final int messageId;
  final MessageModel? message;
  final String? newText;
  final DateTime? timestamp;

  const MessageActionSuccess({
    required this.actionType,
    required this.chatId,
    required this.messageId,
    this.message,
    this.newText,
    this.timestamp,
  });

  @override
  List<Object?> get props => [
        actionType,
        chatId,
        messageId,
        message,
        newText,
        timestamp,
      ];
}

/// Ошибка при выполнении действия
class MessageActionFailure extends MessageActionState {
  final MessageActionType actionType;
  final String message;

  const MessageActionFailure({
    required this.actionType,
    required this.message,
  });

  @override
  List<Object?> get props => [actionType, message];
}

/// Состояние редактирования сообщения
class MessageEditInProgress extends MessageActionState {
  final int messageId;
  final String originalText;

  const MessageEditInProgress({
    required this.messageId,
    required this.originalText,
  });

  @override
  List<Object?> get props => [messageId, originalText];
}

/// Состояние закрепленного сообщения
class MessagePinActive extends MessageActionState {
  final MessageModel pinnedMessage;
  final int chatId;

  const MessagePinActive({
    required this.pinnedMessage,
    required this.chatId,
  });

  @override
  List<Object?> get props => [pinnedMessage, chatId];
}

/// Состояние отсутствия закрепленного сообщения
class MessagePinEmpty extends MessageActionState {}
