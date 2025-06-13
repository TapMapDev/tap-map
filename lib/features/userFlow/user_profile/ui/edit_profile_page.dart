import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/features/userFlow/user_profile/bloc/user_information_bloc.dart';
import 'package:tap_map/features/userFlow/user_profile/model/user_response_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;
  late final TextEditingController _dateOfBirthController;

  DateTime? _selectedDate;
  bool _isSearchableByEmail = false;
  bool _isSearchableByPhone = false;
  bool _isPrivacyLoaded = false;

  @override
  void initState() {
    super.initState();
    _initFormData();
    context.read<UserBloc>().add(LoadPrivacySettings());
  }

  void _initFormData() {
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
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _updatePrivacySettings({
    bool? isSearchableByEmail,
    bool? isSearchableByPhone,
  }) {
    setState(() {
      if (isSearchableByEmail != null) {
        _isSearchableByEmail = isSearchableByEmail;
      }
      if (isSearchableByPhone != null) {
        _isSearchableByPhone = isSearchableByPhone;
      }
    });

    final privacySettings = PrivacySettings(
      isSearchableByEmail: _isSearchableByEmail,
      isSearchableByPhone: _isSearchableByPhone,
      isShowGeolocationToFriends:
          widget.user.privacy?.isShowGeolocationToFriends,
      isPreciseGeolocation: widget.user.privacy?.isPreciseGeolocation,
    );

    context.read<UserBloc>().add(UpdatePrivacySettings(privacySettings));
  }

  void _submitProfile() {
    final updatedUser = widget.user.copyWith(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      username: _usernameController.text,
      description: _descriptionController.text,
      phone: _phoneController.text,
      website: _websiteController.text,
      dateOfBirth: _selectedDate != null ? _formatDate(_selectedDate!) : null,
      privacy: null,
    );

    context.read<UserBloc>().add(UpdateUserProfile(updatedUser));
  }

  void _handleBlocStates(BuildContext context, UserState state) {
    if (state is UserLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль успешно обновлен')),
      );
      Navigator.pop(context, true);
    } else if (state is UserError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${state.error}')),
      );
    } else if (state is PrivacySettingsLoaded) {
      setState(() {
        _isPrivacyLoaded = true;
        _isSearchableByEmail =
            state.privacySettings.isSearchableByEmail ?? false;
        _isSearchableByPhone =
            state.privacySettings.isSearchableByPhone ?? false;
      });
    } else if (state is PrivacySettingsUpdated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки приватности обновлены')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitProfile,
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<UserBloc, UserState>(
            listener: _handleBlocStates,
          )
        ],
        child: !_isPrivacyLoaded
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileTextField(
                        label: 'Имя', controller: _firstNameController),
                    const SizedBox(height: 16),
                    ProfileTextField(
                        label: 'Фамилия', controller: _lastNameController),
                    const SizedBox(height: 16),
                    ProfileTextField(
                        label: 'Имя пользователя',
                        controller: _usernameController),
                    const SizedBox(height: 16),
                    ProfileTextField(
                      label: 'Описание',
                      controller: _descriptionController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ProfileTextField(
                      label: 'Телефон',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildDatePickerField(),
                    const SizedBox(height: 16),
                    PrivacySettingsSection(
                      isSearchableByEmail: _isSearchableByEmail,
                      isSearchableByPhone: _isSearchableByPhone,
                      onEmailChanged: (value) =>
                          _updatePrivacySettings(isSearchableByEmail: value),
                      onPhoneChanged: (value) =>
                          _updatePrivacySettings(isSearchableByPhone: value),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return TextField(
      controller: _dateOfBirthController,
      decoration: const InputDecoration(
        labelText: 'Дата рождения',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () async {
        final now = DateTime.now();
        final initialDate = _selectedDate ?? DateTime(now.year - 18);
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
    );
  }
}

class ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

  const ProfileTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class PrivacySettingsSection extends StatelessWidget {
  final bool isSearchableByEmail;
  final bool isSearchableByPhone;
  final ValueChanged<bool> onEmailChanged;
  final ValueChanged<bool> onPhoneChanged;

  const PrivacySettingsSection({
    super.key,
    required this.isSearchableByEmail,
    required this.isSearchableByPhone,
    required this.onEmailChanged,
    required this.onPhoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Настройки приватности',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Разрешить поиск по email'),
          value: isSearchableByEmail,
          onChanged: onEmailChanged,
        ),
        SwitchListTile(
          title: const Text('Разрешить поиск по телефону'),
          value: isSearchableByPhone,
          onChanged: onPhoneChanged,
        ),
      ],
    );
  }
}
