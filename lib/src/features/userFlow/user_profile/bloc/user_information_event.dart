part of 'user_information_bloc.dart';

abstract class UserEvent {}

/// Загрузка профиля
class LoadUserProfile extends UserEvent {}

/// Обновление профиля
class UpdateUserProfile extends UserEvent {
  final UserModel user;

  UpdateUserProfile(this.user);
}

/// Обновление аватара пользователя
class UpdateUserAvatar extends UserEvent {
  final XFile image;

  UpdateUserAvatar(this.image);
}

class LoadUserAvatars extends UserEvent {}

class DeleteUserAvatar extends UserEvent {
  final int avatarId;

  DeleteUserAvatar(this.avatarId);
}

class UpdatePrivacySettings extends UserEvent {
  final PrivacySettings privacySettings;

  UpdatePrivacySettings(this.privacySettings);
}

class LoadPrivacySettings extends UserEvent {}
