sealed class ResetPasswordEvent {}

class SendConfirmationCode extends ResetPasswordEvent {
  final String email;

  SendConfirmationCode({required this.email});
}

class ConfirmCode extends ResetPasswordEvent {
  final String code;
  final String email;

  ConfirmCode({required this.code, required this.email});
}

class SetNewPassword extends ResetPasswordEvent {
  final String email;
  final String newPassword;
  final String confirmPassword;

  SetNewPassword(
      {required this.email,
      required this.newPassword,
      required this.confirmPassword});
}