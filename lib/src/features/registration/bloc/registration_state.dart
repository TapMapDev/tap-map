part of 'registration_bloc.dart';

sealed class RegistrationState {}

final class RegistrationStateInitial extends RegistrationState {}

final class RegistarationStateInProccess extends RegistrationState {}

final class RegistarationStateSuccess extends RegistrationState {}

final class RegistarationStatenError extends RegistrationState {
  final String? errorMessage;

  RegistarationStatenError({required this.errorMessage});
}
