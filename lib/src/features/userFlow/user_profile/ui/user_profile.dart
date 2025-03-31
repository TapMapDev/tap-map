import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/router/routes.dart';
import 'package:tap_map/src/features/auth/data/authorization_repository.dart';
import 'package:go_router/go_router.dart';
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
          IconButton(
            icon: const Icon(Icons.logout),
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
          Text('${user.firstName ?? ''} ${user.lastName ?? ''}',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

          // Username
          if (user.username != null) ...[
            const SizedBox(height: 8),
            Text('@${user.username}'),
          ],

          // Описание
          if (user.description != null) ...[
            const SizedBox(height: 8),
            Text(user.description!),
          ],

          // Телефон
          if (user.phone != null) ...[
            const SizedBox(height: 8),
            Text('Телефон: ${user.phone}'),
          ],

          // Дата рождения
          if (user.dateOfBirth != null) ...[
            const SizedBox(height: 8),
            Text('Дата рождения: ${user.dateOfBirth}'),
          ],

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(user: user),
                ),
              );
            },
            child: const Text('Редактировать профиль'),
          ),
        ],
      ),
    );
  }
}
