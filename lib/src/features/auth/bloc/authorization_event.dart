part of 'authorization_bloc.dart';

class AuthorizationEvent {}

class AuthorizationSignInWithEmailPressedEvent extends AuthorizationEvent {
  final String username;
  final String password;

  AuthorizationSignInWithEmailPressedEvent(
      {required this.username, required this.password});
}

class CheckAuthorizationEvent extends AuthorizationEvent {}

class LogoutEvent extends AuthorizationEvent {}
