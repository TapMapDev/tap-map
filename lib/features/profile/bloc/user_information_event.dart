part of 'user_information_bloc.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

/// Загрузка профиля
class LoadUserProfile extends UserEvent {
  const LoadUserProfile();
}

/// Обновление профиля
class UpdateUserProfile extends UserEvent {
  final UserModel user;

  const UpdateUserProfile(this.user);

  @override
  List<Object?> get props => [user];
}

/// Обновление аватара пользователя
class UpdateUserAvatar extends UserEvent {
  final XFile image;

  const UpdateUserAvatar(this.image);

  @override
  List<Object?> get props => [image];
}

class LoadUserAvatars extends UserEvent {
  const LoadUserAvatars();
}

class DeleteUserAvatar extends UserEvent {
  final int avatarId;

  const DeleteUserAvatar(this.avatarId);

  @override
  List<Object?> get props => [avatarId];
}

class UpdatePrivacySettings extends UserEvent {
  final PrivacySettings privacySettings;

  const UpdatePrivacySettings(this.privacySettings);

  @override
  List<Object?> get props => [privacySettings];
}

class LoadPrivacySettings extends UserEvent {
  const LoadPrivacySettings();
}

class LoadUserByUsername extends UserEvent {
  final String username;

  const LoadUserByUsername(this.username);

  @override
  List<Object?> get props => [username];
}

class BlockUser extends UserEvent {
  final int userId;

  const BlockUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UnblockUser extends UserEvent {
  final int userId;

  const UnblockUser(this.userId);

  @override
  List<Object?> get props => [userId];
}
