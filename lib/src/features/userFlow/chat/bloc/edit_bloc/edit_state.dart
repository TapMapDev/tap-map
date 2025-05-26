part of 'edit_bloc.dart';

abstract class EditState extends Equatable {
  const EditState();

  @override
  List<Object> get props => [];
}

class EditInitial extends EditState {}

class EditInProgress extends EditState {
  final int messageId;
  final String originalText;

  const EditInProgress({
    required this.messageId,
    required this.originalText,
  });

  @override
  List<Object> get props => [messageId, originalText];
}

class EditLoading extends EditState {}

class EditSuccess extends EditState {
  final int chatId;
  final int messageId;
  final String newText;
  final DateTime editedAt;

  const EditSuccess({
    required this.chatId,
    required this.messageId,
    required this.newText,
    required this.editedAt,
  });

  @override
  List<Object> get props => [chatId, messageId, newText, editedAt];
}

class EditFailure extends EditState {
  final String error;

  const EditFailure(this.error);

  @override
  List<Object> get props => [error];
}
