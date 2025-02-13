part of 'authorization_bloc.dart';

class AuthorizationEvent {}

class AuthorizationSignInWithEmailPressedEvent extends AuthorizationEvent {
  final String email;
  final String password;

  AuthorizationSignInWithEmailPressedEvent(
      {required this.email, required this.password});
}

class CheckAuthorizationEvent extends AuthorizationEvent {}

class LogoutEvent extends AuthorizationEvent {}
