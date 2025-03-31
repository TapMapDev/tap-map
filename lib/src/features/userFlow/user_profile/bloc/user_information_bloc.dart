import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/user_profile/data/user_repository.dart';
import 'package:tap_map/src/features/userFlow/user_profile/model/user_response_model.dart';

part 'user_information_event.dart';
part 'user_information_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final IUserRepository repository;

  UserBloc(this.repository) : super(UserInitial()) {
    on<LoadUserProfile>((event, emit) async {
      emit(UserLoading());
      try {
        final user = await repository.getCurrentUser();
        emit(UserLoaded(user));
      } catch (e) {
        emit(UserError(e.toString()));
      }
    });

    on<UpdateUserProfile>((event, emit) async {
      emit(UserLoading());
      try {
        final updatedUser = await repository.updateUser(event.user);
        emit(UserLoaded(updatedUser));
      } catch (e) {
        emit(UserError(e.toString()));
      }
    });
  }
}
