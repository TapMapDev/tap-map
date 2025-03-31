part of 'user_information_bloc.dart';

abstract class UserEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Загрузка профиля
class LoadUserProfile extends UserEvent {}

/// Обновление профиля
class UpdateUserProfile extends UserEvent {
  final UserModel user;

  UpdateUserProfile(this.user);

  @override
  List<Object?> get props => [user];
}