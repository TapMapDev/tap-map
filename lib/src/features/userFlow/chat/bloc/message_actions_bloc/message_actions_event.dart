import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Базовое событие для всех действий с сообщениями
sealed class MessageActionEvent extends Equatable {
  const MessageActionEvent();

  @override
  List<Object?> get props => [];
}

/// Закрепление сообщения
class PinMessageAction extends MessageActionEvent {
  final int chatId;
  final int messageId;

  const PinMessageAction({
    required this.chatId,
    required this.messageId,
  });

  @override
  List<Object?> get props => [chatId, messageId];
}

/// Открепление сообщения
class UnpinMessageAction extends MessageActionEvent {
  final int chatId;
  final int messageId;

  const UnpinMessageAction({
    required this.chatId,
    required this.messageId,
  });

  @override
  List<Object?> get props => [chatId, messageId];
}

/// Загрузка закрепленного сообщения
class LoadPinnedMessageAction extends MessageActionEvent {
  final int chatId;

  const LoadPinnedMessageAction(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

/// Удаление сообщения
class DeleteMessageAction extends MessageActionEvent {
  final int chatId;
  final int messageId;
  final String action;

  const DeleteMessageAction({
    required this.chatId,
    required this.messageId,
    required this.action,
  });

  @override
  List<Object?> get props => [chatId, messageId, action];
}

/// Начало редактирования сообщения
class StartEditingAction extends MessageActionEvent {
  final int messageId;
  final String originalText;

  const StartEditingAction({
    required this.messageId,
    required this.originalText,
  });

  @override
  List<Object?> get props => [messageId, originalText];
}

/// Редактирование сообщения
class EditMessageAction extends MessageActionEvent {
  final int chatId;
  final int messageId;
  final String text;
  final BuildContext? context;

  const EditMessageAction({
    required this.chatId,
    required this.messageId,
    required this.text,
    this.context,
  });

  @override
  List<Object?> get props => [chatId, messageId, text];
}

/// Отмена редактирования
class CancelEditAction extends MessageActionEvent {
  const CancelEditAction();
}
