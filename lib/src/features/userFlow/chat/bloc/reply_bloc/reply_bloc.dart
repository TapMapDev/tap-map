import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

part 'reply_event.dart';
part 'reply_state.dart';

/// Блок для управления ответами на сообщения
/// 
/// Этот блок отвечает только за подготовку ответа на сообщение
/// и не затрагивает другие действия с сообщениями
class ReplyBloc extends Bloc<ReplyEvent, ReplyState> {
  ReplyBloc() : super(ReplyInitial()) {
    on<SetReplyTo>(_onSetReplyTo);
    on<ClearReplyTo>(_onClearReplyTo);
  }

  /// Обработка выбора сообщения для ответа
  void _onSetReplyTo(SetReplyTo event, Emitter<ReplyState> emit) {
    emit(ReplyActive(event.message));
  }

  /// Обработка отмены ответа
  void _onClearReplyTo(ClearReplyTo event, Emitter<ReplyState> emit) {
    emit(ReplyInitial());
  }
}
