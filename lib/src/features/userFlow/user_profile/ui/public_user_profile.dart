import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/navigation/routes.dart';
import 'package:tap_map/src/features/userFlow/chat/data/chat_repository.dart';
import 'package:tap_map/src/features/userFlow/user_profile/bloc/user_information_bloc.dart';
import 'package:tap_map/src/features/userFlow/user_profile/model/user_response_model.dart';
import 'package:tap_map/src/features/userFlow/user_profile/widget/client_avatar.dart';

class PublicUserProfileScreen extends StatefulWidget {
  final String username;

  const PublicUserProfileScreen({super.key, required this.username});

  @override
  State<PublicUserProfileScreen> createState() =>
      _PublicUserProfileScreenState();
}

class _PublicUserProfileScreenState extends State<PublicUserProfileScreen> {
  late UserBloc userBloc;

  @override
  void initState() {
    super.initState();
    userBloc = getIt<UserBloc>();
    userBloc.add(LoadUserByUsername(widget.username));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('@${widget.username}'))),
      body: BlocBuilder<UserBloc, UserState>(
        bloc: userBloc,
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UserError) {
            return Center(child: Text('Ошибка: ${state.error}'));
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
      child: Center(
        child: Column(
          children: [
            ClientAvatar(
              user: user,
              radius: 50,
            ),
            const SizedBox(height: 16),
            if (user.firstName != null || user.lastName != null) ...[
              Text(
                '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            if (user.username != null) ...[
              Text('@${user.username}'),
              const SizedBox(height: 8),
            ],
            if (user.description != null && user.description!.isNotEmpty) ...[
              Text(user.description!),
              const SizedBox(height: 8),
            ],
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  final chatRepository = getIt<ChatRepository>();
                  final chatId = await chatRepository.createChat(
                    type: 'dialog',
                    participantId: user.id,
                  );
                  context.push(
                      '${AppRoutes.chat}?chatId=$chatId&username=${user.username}');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Не удалось создать чат: $e')),
                  );
                }
              },
              child: const Text('Написать сообщение'),
            ),
            TextButton(
              onPressed: () {
                userBloc.add(BlockUser(user.id));
              },
              child: const Text('Заблокировать'),
            ),
          ],
        ),
      ),
    );
  }
}
