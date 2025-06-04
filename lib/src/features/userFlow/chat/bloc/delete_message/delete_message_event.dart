part of 'delete_message_bloc.dart';

import 'package:flutter/widgets.dart';

abstract class DeleteMessageEvent extends Equatable {
  const DeleteMessageEvent();

  @override
  List<Object> get props => [];
}

class DeleteMessageRequest extends DeleteMessageEvent {
  final int chatId;
  final int messageId;
  final String action;
  final BuildContext? context;

  const DeleteMessageRequest({
    required this.chatId,
    required this.messageId,
    required this.action,
    this.context,
  });

  @override
  List<Object> get props => [chatId, messageId, action];
}
