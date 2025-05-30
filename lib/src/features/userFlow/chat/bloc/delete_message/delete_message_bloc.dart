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

      // Проверяем, является ли сообщение новым (созданным менее 5 секунд назад)
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final messageTime = event.messageId;
      final isNewMessage = currentTime - messageTime < 5000;

      print(
          'DeleteMessageBloc: Message time: $messageTime, Current time: $currentTime, Diff: ${currentTime - messageTime}ms');
      print('DeleteMessageBloc: Is new message: $isNewMessage');

      if (!isNewMessage) {
        // Если сообщение не новое, пытаемся удалить через API
        print('DeleteMessageBloc: Deleting message through API');
        try {
          await _chatRepository.deleteMessage(
            event.chatId,
            event.messageId,
            event.action,
          );
          print('DeleteMessageBloc: API delete successful');
        } catch (e) {
          print('DeleteMessageBloc: API delete failed: $e');
          // Даже если API удаление не удалось, продолжаем с локальным удалением
        }
      } else {
        print('DeleteMessageBloc: Skipping API delete for new message');
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
