part of 'authorization_bloc.dart';

@immutable
sealed class AuthorizationState {}

final class AuthorizationInitial extends AuthorizationState {}

final class AuthorizationInProcess extends AuthorizationState {}

final class AuthorizationFailed extends AuthorizationState {
  final String? errorMessage;

  AuthorizationFailed({required this.errorMessage});
}

final class AuthorizationSuccess extends AuthorizationState {}

class AuthorizedState extends AuthorizationState {} // Авторизован

class UnAuthorizedState extends AuthorizationState {} // 
