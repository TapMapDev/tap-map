import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tap_map/features/userFlow/chat/models/message_model.dart';
part 'reply_event.dart';
part 'reply_state.dart';

class ReplyBloc extends Bloc<ReplyEvent, ReplyState> {
  ReplyBloc() : super(ReplyInitial()) {
    on<SetReplyTo>(_onSetReplyTo);
    on<ClearReplyTo>(_onClearReplyTo);
  }

  void _onSetReplyTo(SetReplyTo event, Emitter<ReplyState> emit) {
    emit(ReplyActive(event.message));
  }

  void _onClearReplyTo(ClearReplyTo event, Emitter<ReplyState> emit) {
    emit(ReplyInitial());
  }
}
