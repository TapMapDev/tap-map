import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/features/userFlow/user_profile/bloc/user_information_bloc.dart';
import 'package:tap_map/features/userFlow/user_profile/model/user_response_model.dart';

class ClientAvatar extends StatefulWidget {
  final UserModel user;
  final double radius;
  final bool editable;
  final Function(String)? onAvatarUpdated;
  final bool showAllAvatars;

  const ClientAvatar({
    super.key,
    required this.user,
    this.radius = 50,
    this.editable = false,
    this.onAvatarUpdated,
    this.showAllAvatars = false,
  });

  @override
  State<ClientAvatar> createState() => _ClientAvatarState();
}

class _ClientAvatarState extends State<ClientAvatar> {
  late UserBloc _userBloc;
  final ImagePicker _picker = ImagePicker();
  List<UserAvatarModel>? _userAvatars;

  @override
  void initState() {
    super.initState();
    _userBloc = getIt<UserBloc>();

    // Если нужно показать все аватары, загружаем их
    if (widget.showAllAvatars) {
      _userBloc.add(const LoadUserAvatars());
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        _userBloc.add(UpdateUserAvatar(image));
      }
    } catch (e) {
      // Показать ошибку
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выборе изображения: $e')),
      );
    }
  }

  void _showAvatarGallery() {
    if (_userAvatars == null || _userAvatars!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У вас нет доступных аватаров')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите аватар'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: _userAvatars!.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final avatar = _userAvatars![index];

                return Stack(
                  children: [
                    // Выбор аватара при тапе
                    GestureDetector(
                      onTap: () {
                        widget.onAvatarUpdated?.call(avatar.imageUrl);
                        // Закрываем только диалог выбора аватаров
                        Navigator.of(context).pop();
                      },
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(avatar.imageUrl),
                        radius: 40,
                      ),
                    ),
                    // Кнопка удаления (крестик)
                    Positioned(
                      top: -10,
                      right: -10,
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: Colors.grey),
                        onPressed: () async {
                          // Показываем диалог подтверждения удаления
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Удалить аватар?'),
                              content: const Text(
                                  'Вы уверены, что хотите удалить этот аватар?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Отмена'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            _userBloc.add(DeleteUserAvatar(avatar.id));
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      bloc: _userBloc,
      listener: (context, state) {
        if (state is AvatarUpdated) {
          if (widget.onAvatarUpdated != null) {
            widget.onAvatarUpdated!(state.avatarUrl);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Аватар обновлен')),
          );
          // После обновления аватара, обновляем список аватаров
          if (widget.showAllAvatars) {
            _userBloc.add(const LoadUserAvatars());
          }
        } else if (state is UserError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: ${state.error}')),
          );
        } else if (state is AvatarsLoaded) {
          setState(() {
            _userAvatars = state.avatars;
          });
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            CircleAvatar(
              radius: widget.radius,
              backgroundImage: (widget.user.avatarUrl != null &&
                      widget.user.avatarUrl!.isNotEmpty)
                  ? NetworkImage(widget.user.avatarUrl!)
                  : null,
              child: (widget.user.avatarUrl == null ||
                      widget.user.avatarUrl!.isEmpty)
                  ? Icon(Icons.person, size: widget.radius)
                  : null,
            ),
            if (widget.editable)
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            if (widget.showAllAvatars && (_userAvatars?.isNotEmpty ?? false))
              Positioned(
                left: 0,
                bottom: 0,
                child: InkWell(
                  onTap: _showAvatarGallery,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
