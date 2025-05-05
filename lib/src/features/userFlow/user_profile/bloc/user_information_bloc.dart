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
        add(const LoadUserAvatars());
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
        add(const LoadUserProfile());
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
          add(const LoadUserAvatars());
        }
      } catch (e) {
        emit(UserError(e.toString()));
      }
    });

    on<UpdatePrivacySettings>((event, emit) async {
      emit(PrivacySettingsUpdating());
      try {
        final updatedPrivacy =
            await repository.updatePrivacySettings(event.privacySettings);
        emit(PrivacySettingsUpdated(updatedPrivacy));
      } catch (e) {
        emit(UserError(e.toString()));
      }
    });

    on<LoadPrivacySettings>((event, emit) async {
      emit(UserLoading());
      try {
        final privacySettings = await repository.getPrivacySettings();
        emit(PrivacySettingsLoaded(privacySettings));
      } catch (e) {
        emit(UserError(e.toString()));
      }
    });

    on<LoadUserByUsername>(_onLoadUserByUsername);
    on<BlockUser>(_onBlockUser);
    on<UnblockUser>(_onUnblockUser);
  }

  Future<void> _onLoadUserByUsername(
    LoadUserByUsername event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(UserLoading());
      final user = await repository.getUserByUsername(event.username);
      emit(UserLoaded(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onBlockUser(
    BlockUser event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(UserLoading());
      await repository.blockUser(event.userId);
      if (state is UserLoaded) {
        final currentUser = (state as UserLoaded).user;
        final updatedUser = currentUser.copyWith(isBlocked: true);
        emit(UserLoaded(updatedUser));
      }
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onUnblockUser(
    UnblockUser event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(UserLoading());
      await repository.unblockUser(event.userId);
      if (state is UserLoaded) {
        final currentUser = (state as UserLoaded).user;
        final updatedUser = currentUser.copyWith(isBlocked: false);
        emit(UserLoaded(updatedUser));
      }
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
