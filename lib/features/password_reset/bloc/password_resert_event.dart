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
  final String? uid;
  final String? token;
  final String newPassword;

  SetNewPassword({
    required this.uid,
    required this.token,
    required this.newPassword,
  });
}
