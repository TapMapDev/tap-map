part of 'user_information_bloc.dart';

abstract class UserState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final UserModel user;
  UserLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class UserError extends UserState {
  final String error;
  UserError(this.error);

  @override
  List<Object?> get props => [error];
}

class AvatarUpdating extends UserState {}

class AvatarUpdated extends UserState {
  final String avatarUrl;

  AvatarUpdated(this.avatarUrl);

  @override
  List<Object?> get props => [avatarUrl];
}

class AvatarsLoading extends UserState {}

class AvatarsLoaded extends UserState {
  final List<UserAvatarModel> avatars;
  final UserModel user;

  AvatarsLoaded(this.avatars, this.user);

  @override
  List<Object?> get props => [avatars, user];
}

class PrivacySettingsLoaded extends UserState {
  final PrivacySettings privacySettings;

  PrivacySettingsLoaded(this.privacySettings);
}

class PrivacySettingsUpdating extends UserState {}

class PrivacySettingsUpdated extends UserState {
  final PrivacySettings privacySettings;

  PrivacySettingsUpdated(this.privacySettings);
}
