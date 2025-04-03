import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  late TextEditingController _dateOfBirthController;
  DateTime? _selectedDate;
  bool _isSearchableByEmail = true;
  bool _isSearchableByPhone = true;

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
    _selectedDate = widget.user.dateOfBirth != null
        ? DateTime.tryParse(widget.user.dateOfBirth!)
        : null;
    _dateOfBirthController = TextEditingController(
      text: _selectedDate != null ? _formatDate(_selectedDate!) : '',
    );
    final privacy = widget.user.privacy;
    _isSearchableByEmail = privacy?.isSearchableByEmail ?? true;
    _isSearchableByPhone = privacy?.isSearchableByPhone ?? true;
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _saveProfile() {
    // Отладочная печать текущих значений приватности
    print('Сохранение профиля:');
    print('_isSearchableByEmail: $_isSearchableByEmail');
    print('_isSearchableByPhone: $_isSearchableByPhone');

    // Создаем объект настроек приватности
    final privacySettings = PrivacySettings(
      isSearchableByEmail: _isSearchableByEmail,
      isSearchableByPhone: _isSearchableByPhone,
      isShowGeolocationToFriends:
          widget.user.privacy?.isShowGeolocationToFriends,
      isPreciseGeolocation: widget.user.privacy?.isPreciseGeolocation,
    );

    // Отладочная печать созданного объекта
    print('Созданные настройки приватности: ${privacySettings.toJson()}');

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
      gender: widget.user.gender,
      phone: _phoneController.text,
      isOnline: widget.user.isOnline,
      lastActivity: widget.user.lastActivity,
      isEmailVerified: widget.user.isEmailVerified,
      security: widget.user.security,
      dateOfBirth: _selectedDate != null ? _formatDate(_selectedDate!) : null,
      // Не обновляем стиль карты при обновлении профиля
      // selectedMapStyle: widget.user.selectedMapStyle,
      privacy: privacySettings,
    );

    // Отладочная печать JSON объекта пользователя
    print('Объект пользователя для отправки: ${updatedUser.toJson()}');

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
            Navigator.pop(context, true);
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
              const SizedBox(height: 16),
              Builder(
                builder: (context) => TextField(
                  controller: _dateOfBirthController,
                  decoration: const InputDecoration(
                    labelText: 'Дата рождения',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final now = DateTime.now();
                    final initialDate =
                        _selectedDate ?? DateTime(now.year - 18);
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _dateOfBirthController.text = _formatDate(picked);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Настройки приватности',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Разрешить поиск по email'),
                value: _isSearchableByEmail,
                onChanged: (value) {
                  print('Изменение isSearchableByEmail на: $value');
                  setState(() {
                    _isSearchableByEmail = value;
                  });
                  // Дополнительная проверка
                  Future.delayed(Duration.zero, () {
                    print(
                        'После setState isSearchableByEmail: $_isSearchableByEmail');
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Разрешить поиск по телефону'),
                value: _isSearchableByPhone,
                onChanged: (value) {
                  print('Изменение isSearchableByPhone на: $value');
                  setState(() {
                    _isSearchableByPhone = value;
                  });
                  // Дополнительная проверка
                  Future.delayed(Duration.zero, () {
                    print(
                        'После setState isSearchableByPhone: $_isSearchableByPhone');
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
