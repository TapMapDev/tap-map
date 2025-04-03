import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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
        add(LoadUserAvatars());
      } catch (e) {
        emit(UserError(e.toString()));
      }
    });

    on<UpdateUserAvatar>((event, emit) async {
      emit(AvatarUpdating());
      try {
        final file = File(event.image.path);
        final avatarUrl = await repository.updateAvatar(file);
        emit(AvatarUpdated(avatarUrl));
        add(LoadUserProfile());
      } catch (e) {
        emit(UserError(e.toString()));
      }
    });

    on<LoadUserAvatars>((event, emit) async {
      UserModel? currentUser;
      if (state is UserLoaded) {
        currentUser = (state as UserLoaded).user;
      }

      emit(AvatarsLoading());
      try {
        currentUser ??= await repository.getCurrentUser();
        final avatars = await repository.getUserAvatars();
        emit(AvatarsLoaded(avatars, currentUser));
      } catch (e) {
        emit(UserError(e.toString()));
      }
    });
    on<DeleteUserAvatar>((event, emit) async {
      try {
        final success = await repository.deleteAvatar(event.avatarId);
        if (success) {
          add(LoadUserAvatars());
        }
      } catch (e) {
        emit(UserError(e.toString()));
      }
    });
  }
}
