import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/router/routes.dart';
import 'package:tap_map/src/features/auth/data/authorization_repository.dart';
import 'package:tap_map/src/features/userFlow/user_profile/bloc/user_information_bloc.dart';
import 'package:tap_map/src/features/userFlow/user_profile/model/user_response_model.dart';
import 'package:tap_map/src/features/userFlow/user_profile/ui/edit_profile_page.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late UserBloc userBloc;
  @override
  void initState() {
    userBloc = getIt<UserBloc>();
    userBloc.add(LoadUserProfile());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          // Иконка настроек/редактирования профиля
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Редактировать профиль',
            onPressed: () {
              if (userBloc.state is UserLoaded) {
                final user = (userBloc.state as UserLoaded).user;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(user: user),
                  ),
                );
              }
            },
          ),
          // Иконка выхода
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              await getIt<AuthorizationRepositoryImpl>().logout();
              context.go(AppRoutes.authorization);
            },
          ),
        ],
      ),
      body: BlocBuilder<UserBloc, UserState>(
        bloc: userBloc,
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UserError) {
            return Center(
              child: Text('Ошибка: ${state.error}'),
            );
          } else if (state is UserLoaded) {
            final user = state.user;
            return _buildProfileView(user);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProfileView(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Аватар
          CircleAvatar(
            radius: 50,
            backgroundImage:
                (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                    ? NetworkImage(user.avatarUrl!)
                    : null,
            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),

          // Имя и Фамилия
          if (user.firstName != null || user.lastName != null) ...[
            Text(
              '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],

          // Username
          if (user.username != null) ...[
            Text('@${user.username}'),
            const SizedBox(height: 8),
          ],

          // Email
          if (user.email != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(user.email!, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Описание
          if (user.description != null && user.description!.isNotEmpty) ...[
            Text(user.description!),
            const SizedBox(height: 8),
          ],

          // Телефон
          if (user.phone != null && user.phone!.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, size: 16),
                const SizedBox(width: 4),
                Text('Телефон: ${user.phone}'),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Дата рождения
          if (user.dateOfBirth != null && user.dateOfBirth!.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cake, size: 16),
                const SizedBox(width: 4),
                Text('Дата рождения: ${user.dateOfBirth}'),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
