import 'dart:core';

import 'package:bloc/bloc.dart';
import 'package:tap_map/features/password_reset/bloc/password_resert_event.dart';
import 'package:tap_map/features/password_reset/bloc/password_resert_state.dart';
import 'package:tap_map/features/password_reset/data/password_reset_repository.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final ResetPasswordRepositoryImpl repository;
  ResetPasswordBloc(this.repository) : super(SendCodeInitial()) {
    on<SendConfirmationCode>((event, emit) async {
      emit(SendCodeInProgress());
      try {
        final response =
            await repository.sendConfirmationCode(email: event.email);
        if (response.statusCode == 200 || response.statusCode == 201) {
          emit(SendCodeSuccess());
          emit(ConfirmCodeInitial());
        } else {
          emit(SendCodeError(error: response.message));
        }
      } catch (e) {
        emit(SendCodeError(error: e.toString()));
      }
    });

    on<SetNewPassword>((event, emit) async {
      emit(SetNewPasswordInProgress());

      try {
        final response = await repository.setNewPassword(
          uid: event.uid,
          token: event.token,
          newPassword: event.newPassword,
        );

        if (response.statusCode == 200 ||
            response.statusCode == 201 ||
            response.statusCode == 204) {
          emit(SetNewPassworduccess());
        } else {
          emit(SetNewPasswordError(error: response.message));
        }
      } catch (e) {
        emit(SetNewPasswordError(error: e.toString()));
      }
    });
  }
}
