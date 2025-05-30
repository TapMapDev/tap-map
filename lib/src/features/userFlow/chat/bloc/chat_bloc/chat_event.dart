import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

/// События для объединенного ChatBloc
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

//
// СОБЫТИЯ ДЛЯ РАБОТЫ СО СПИСКОМ ЧАТОВ
//

/// Загрузить список чатов
class FetchChatsEvent extends ChatEvent {
  const FetchChatsEvent();
}

//
// СОБЫТИЯ ДЛЯ РАБОТЫ С КОНКРЕТНЫМ ЧАТОМ
//

/// Загрузить чат по ID
class FetchChatEvent extends ChatEvent {
  final int chatId;

  const FetchChatEvent(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

/// Отправить сообщение
class SendMessageEvent extends ChatEvent {
  final int chatId;
  final String text;
  final int? replyToId;
  final int? forwardedFromId;
  final List<Map<String, String>>? attachments;

  const SendMessageEvent({
    required this.chatId,
    required this.text,
    this.replyToId,
    this.forwardedFromId,
    this.attachments,
  });

  @override
  List<Object?> get props => [chatId, text, replyToId, forwardedFromId, attachments];
}

/// Новое сообщение от WebSocket
class NewWebSocketMessageEvent extends ChatEvent {
  final dynamic message;

  const NewWebSocketMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

/// Ошибка в чате
class ChatErrorEvent extends ChatEvent {
  final String message;

  const ChatErrorEvent(this.message);

  @override
  List<Object?> get props => [message];
}

//
// СОБЫТИЯ ДЛЯ РАБОТЫ С WEBSOCKET
//

/// Подключиться к чату
class ConnectToChatEvent extends ChatEvent {
  const ConnectToChatEvent();
}

/// Отключиться от чата
class DisconnectFromChatEvent extends ChatEvent {
  const DisconnectFromChatEvent();
}

/// Отправить статус печати
class SendTypingEvent extends ChatEvent {
  final int chatId;
  final bool isTyping;

  const SendTypingEvent({
    required this.chatId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [chatId, isTyping];
}

//
// СОБЫТИЯ ДЛЯ РАБОТЫ С СООБЩЕНИЯМИ
//

/// Загрузить и отправить файл
class UploadFileEvent extends ChatEvent {
  final File file;
  final String? caption;
  final int chatId;

  const UploadFileEvent({
    required this.file,
    required this.chatId,
    this.caption,
  });

  @override
  List<Object?> get props => [file, caption, chatId];
}

/// Отметить чат как прочитанный
class MarkChatAsReadEvent extends ChatEvent {
  final int chatId;

  const MarkChatAsReadEvent(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

/// Удалить сообщение
class DeleteMessageEvent extends ChatEvent {
  final int chatId;
  final int messageId;
  final String action; // 'self' или 'all'

  const DeleteMessageEvent({
    required this.chatId,
    required this.messageId,
    required this.action,
  });

  @override
  List<Object?> get props => [chatId, messageId, action];
}

/// Редактировать сообщение
class EditMessageEvent extends ChatEvent {
  final int chatId;
  final int messageId;
  final String text;

  const EditMessageEvent({
    required this.chatId,
    required this.messageId,
    required this.text,
  });

  @override
  List<Object?> get props => [chatId, messageId, text];
}

/// Закрепить сообщение
class PinMessageEvent extends ChatEvent {
  final int chatId;
  final int messageId;

  const PinMessageEvent({
    required this.chatId,
    required this.messageId,
  });

  @override
  List<Object?> get props => [chatId, messageId];
}

/// Открепить сообщение
class UnpinMessageEvent extends ChatEvent {
  final int chatId;
  final int messageId;

  const UnpinMessageEvent({
    required this.chatId,
    required this.messageId,
  });

  @override
  List<Object?> get props => [chatId, messageId];
}

/// Получить закрепленное сообщение
class GetPinnedMessageEvent extends ChatEvent {
  final int chatId;

  const GetPinnedMessageEvent(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

/// Установить сообщение для ответа
class SetReplyToMessageEvent extends ChatEvent {
  final MessageModel? message;

  const SetReplyToMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

/// Установить сообщение для пересылки
class SetForwardFromMessageEvent extends ChatEvent {
  final MessageModel? message;

  const SetForwardFromMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

/// Отметить сообщение как прочитанное
class MarkMessageAsReadEvent extends ChatEvent {
  final int chatId;
  final int messageId;

  const MarkMessageAsReadEvent({
    required this.chatId,
    required this.messageId,
  });

  @override
  List<Object?> get props => [chatId, messageId];
}
