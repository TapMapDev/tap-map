part of 'authorization_bloc.dart';

class AuthorizationEvent {}

class AuthorizationSignInWithEmailPressedEvent extends AuthorizationEvent {
  final String login;
  final String password;

  AuthorizationSignInWithEmailPressedEvent(
      {required this.login, required this.password});
}

class CheckAuthorizationEvent extends AuthorizationEvent {}

class LogoutEvent extends AuthorizationEvent {}

class RefreshTokensEvent extends AuthorizationEvent {}
