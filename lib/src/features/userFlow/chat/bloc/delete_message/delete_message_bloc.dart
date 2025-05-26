import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tap_map/src/features/userFlow/chat/data/chat_repository.dart';

part 'delete_message_event.dart';
part 'delete_message_state.dart';

class DeleteMessageBloc extends Bloc<DeleteMessageEvent, DeleteMessageState> {
  final ChatRepository _chatRepository;

  DeleteMessageBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(DeleteMessageInitial()) {
    on<DeleteMessageRequest>(_onDeleteMessageRequest);
  }

  Future<void> _onDeleteMessageRequest(
    DeleteMessageRequest event,
    Emitter<DeleteMessageState> emit,
  ) async {
    try {
      emit(DeleteMessageLoading());

      await _chatRepository.deleteMessage(
        event.chatId,
        event.messageId,
        event.action,
      );

      emit(DeleteMessageSuccess(
        chatId: event.chatId,
        messageId: event.messageId,
      ));
    } catch (e) {
      emit(DeleteMessageFailure(e.toString()));
    }
  }
}
