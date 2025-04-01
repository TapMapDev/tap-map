import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker/talker.dart';
import 'package:tap_map/src/features/userFlow/user_profile/bloc/user_information_bloc.dart';
import 'package:tap_map/src/features/userFlow/user_profile/model/user_response_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  final Talker talker = Talker();

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _usernameController = TextEditingController(text: widget.user.username);
    _descriptionController =
        TextEditingController(text: widget.user.description);
    _phoneController = TextEditingController(text: widget.user.phone);
    _websiteController = TextEditingController(text: widget.user.website);

    // Логируем информацию о стиле карты при загрузке экрана
    if (widget.user.selectedMapStyle != null) {
      talker.info(
          'Initial selectedMapStyle: id=${widget.user.selectedMapStyle!.id}, name=${widget.user.selectedMapStyle!.name}, url=${widget.user.selectedMapStyle!.styleUrl}');
    } else {
      talker.info('Initial selectedMapStyle is null');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    // Логируем информацию о стиле карты перед созданием модели
    if (widget.user.selectedMapStyle != null) {
      talker.info(
          'Before update - selectedMapStyle: id=${widget.user.selectedMapStyle!.id}, name=${widget.user.selectedMapStyle!.name}, url=${widget.user.selectedMapStyle!.styleUrl}');
    } else {
      talker.info('Before update - selectedMapStyle is null');
    }

    // Не передаем selectedMapStyle, чтобы избежать ошибок валидации
    final updatedUser = UserModel(
      id: widget.user.id,
      email: widget.user.email,
      username: _usernameController.text,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      website: _websiteController.text,
      avatarUrl: widget.user.avatarUrl,
      description: _descriptionController.text,
      dateOfBirth: widget.user.dateOfBirth,
      gender: widget.user.gender,
      phone: _phoneController.text,
      isOnline: widget.user.isOnline,
      lastActivity: widget.user.lastActivity,
      isEmailVerified: widget.user.isEmailVerified,
      privacy: widget.user.privacy,
      security: widget.user.security,
      // Не обновляем стиль карты при обновлении профиля
      // selectedMapStyle: widget.user.selectedMapStyle,
    );

    // Логируем информацию о созданной модели
    talker.info('Created updatedUser without selectedMapStyle');

    context.read<UserBloc>().add(UpdateUserProfile(updatedUser));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Профиль успешно обновлен')),
            );
            Navigator.pop(context);
          } else if (state is UserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка: ${state.error}')),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Фамилия',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Имя пользователя',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
