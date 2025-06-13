part of 'edit_bloc.dart';

abstract class EditEvent extends Equatable {
  const EditEvent();

  @override
  List<Object> get props => [];
}

class EditMessageRequest extends EditEvent {
  final int chatId;
  final int messageId;
  final String text;
  final BuildContext? context;

  const EditMessageRequest({
    required this.chatId,
    required this.messageId,
    required this.text,
    this.context,
  });

  @override
  List<Object> get props => [chatId, messageId, text];
}

class CancelEdit extends EditEvent {
  const CancelEdit();
}

class StartEditing extends EditEvent {
  final int messageId;
  final String originalText;

  const StartEditing({
    required this.messageId,
    required this.originalText,
  });

  @override
  List<Object> get props => [messageId, originalText];
}
