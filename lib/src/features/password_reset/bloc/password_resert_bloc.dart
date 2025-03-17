import 'dart:core';

import 'package:bloc/bloc.dart';
import 'package:tap_map/src/features/password_reset/bloc/password_resert_event.dart';
import 'package:tap_map/src/features/password_reset/bloc/password_resert_state.dart';
import 'package:tap_map/src/features/password_reset/password_reset_repository.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final ResetPasswordRepositoryImpl repository;
  ResetPasswordBloc(this.repository) : super(SendCodeInitial()) {
    on<SendConfirmationCode>((event, emit) async {
      emit(SendCodeInProgress());
      final response =
          await repository.sendConfirmationCode(email: event.email);
      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(SendCodeSuccess());
        emit(ConfirmCodeInitial());
      } else {
        emit(SendCodeError(error: response.message));
      }
    });

    // on<ConfirmCode>(
    //   (event, emit) async {
    //     emit(ConfirmCodeInProgress());
    //     final response =
    //         await repository.confirmCode(email: event.email, code: event.code);
    //     if (response.statusCode == 200 || response.statusCode == 201) {
    //       emit(ConfirmCodeSuccess());
    //       emit(SetNewPasswordInitial());
    //     } else {
    //       emit(ConfirmCodeError(error: response.message));
    //     }
    //   },
    // );

    on<SetNewPassword>(
      (event, emit) async {
        emit(SetNewPasswordInProgress());
        final response = await repository.setNewPassword(
            newPassword: event.newPassword,
            confrimPassword: event.confirmPassword);
        if (response.statusCode == 200 || response.statusCode == 201) {
          emit(SetNewPassworduccess());
        } else {
          emit(SetNewPasswordError(error: response.message));
        }
      },
    );
  }
}
