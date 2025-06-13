sealed class ResetPasswordState {}

// sent code

final class SendCodeInitial extends ResetPasswordState {}

final class SendCodeInProgress extends ResetPasswordState {}

final class SendCodeError extends ResetPasswordState {
  final String? error;

  SendCodeError({required this.error});
}

final class SendCodeSuccess extends ResetPasswordState {}

// code confirmation

final class ConfirmCodeInitial extends ResetPasswordState {}

final class ConfirmCodeInProgress extends ResetPasswordState {}

final class ConfirmCodeError extends ResetPasswordState {
  final String? error;

  ConfirmCodeError({required this.error});
}

final class ConfirmCodeSuccess extends ResetPasswordState {}

final class SetNewPasswordInitial extends ResetPasswordState {}

final class SetNewPasswordInProgress extends ResetPasswordState {}

final class SetNewPasswordError extends ResetPasswordState {
  final String? error;

  SetNewPasswordError({required this.error});
}

final class SetNewPassworduccess extends ResetPasswordState {}