import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tap_map/src/features/userFlow/chat/data/chat_repository.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

part 'pin_event.dart';
part 'pin_state.dart';

class PinBloc extends Bloc<PinBlocEvent, PinBlocState> {
  final ChatRepository _chatRepository;

  PinBloc({
    required ChatRepository chatRepository,
  })  : _chatRepository = chatRepository,
        super(PinBlocInitial()) {
    on<PinMessage>(_onPinMessage);
    on<UnpinMessage>(_onUnpinMessage);
    on<LoadPinnedMessage>(_onLoadPinnedMessage);
  }

  Future<void> _onPinMessage(
    PinMessage event,
    Emitter<PinBlocState> emit,
  ) async {
    try {
      await _chatRepository.pinMessage(
        chatId: event.chatId,
        messageId: event.messageId,
      );

      // Получаем сообщение, которое закрепляем
      final data = await _chatRepository.fetchChatWithMessages(event.chatId);
      final messages = data['messages'] as List<MessageModel>;
      final pinnedMessage = messages.firstWhere(
        (m) => m.id == event.messageId,
        orElse: () => throw Exception('Message not found'),
      );

      emit(MessagePinned(
        pinnedMessage: pinnedMessage,
        chatId: event.chatId,
      ));
    } catch (e) {
      emit(PinBlocError('Ошибка при закреплении: $e'));
    }
  }

  Future<void> _onUnpinMessage(
    UnpinMessage event,
    Emitter<PinBlocState> emit,
  ) async {
    try {
      await _chatRepository.unpinMessage(
        chatId: event.chatId,
        messageId: event.messageId,
      );

      emit(NoPinnedMessage());
    } catch (e) {
      emit(PinBlocError('Ошибка при откреплении: $e'));
    }
  }

  Future<void> _onLoadPinnedMessage(
    LoadPinnedMessage event,
    Emitter<PinBlocState> emit,
  ) async {
    try {
      final pinnedMessageId =
          await _chatRepository.getPinnedMessageId(event.chatId);

      if (pinnedMessageId == null) {
        emit(NoPinnedMessage());
        return;
      }

      final data = await _chatRepository.fetchChatWithMessages(event.chatId);
      final messages = data['messages'] as List<MessageModel>;

      try {
        final pinnedMessage = messages.firstWhere(
          (m) => m.id == pinnedMessageId,
        );

        emit(MessagePinned(
          pinnedMessage: pinnedMessage,
          chatId: event.chatId,
        ));
      } catch (e) {
        // Сообщение не найдено
        emit(NoPinnedMessage());
      }
    } catch (e) {
      emit(PinBlocError('Ошибка при загрузке закрепленного сообщения: $e'));
    }
  }
}
