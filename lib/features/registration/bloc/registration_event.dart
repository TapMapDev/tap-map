part of 'registration_bloc.dart';

sealed class RegistrationEvent {}

class RegistrationCreateAccountEvent extends RegistrationEvent {
  final String username;
  final String email;
  final String password1;
  final String password2;

  RegistrationCreateAccountEvent({
    required this.username,
    required this.email,
    required this.password1,
    required this.password2,
  });
}
