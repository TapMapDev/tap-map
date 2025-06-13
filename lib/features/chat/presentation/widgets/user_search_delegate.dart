import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:tap_map/features/chat/data/repositories/chat_repository.dart';
import 'package:tap_map/features/chat/presentation/pages/chat_screen.dart';
import 'package:tap_map/features/user_profile/data/user_repository.dart';
import 'package:tap_map/features/user_profile/model/user_response_model.dart';

class UserSearchDelegate extends SearchDelegate<UserModel?> {
  final UserRepository _userRepository = GetIt.instance<UserRepository>();
  final ChatRepository _chatRepository = GetIt.instance<ChatRepository>();

  @override
  String get searchFieldLabel => 'Поиск пользователей';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  Future<List<UserModel>> _searchUsers(String query) async {
    if (query.isEmpty) return [];
    try {
      return await _userRepository.searchUsers(query);
    } catch (_) {
      return [];
    }
  }

  Widget _buildUserList(
      BuildContext context, AsyncSnapshot<List<UserModel>> snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!snap.hasData || snap.data!.isEmpty) {
      return const Center(child: Text('Ничего не найдено'));
    }
    final users = snap.data!;
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: user.avatarUrl != null
              ? CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl!))
              : CircleAvatar(
                  child: Text(
                    (user.username ?? '?').substring(0, 1).toUpperCase(),
                  ),
                ),
          title: Text(user.username ?? 'Без имени'),
          subtitle: user.email != null ? Text(user.email!) : null,
          onTap: () async {
            close(context, user);
            try {
              final chatId = await _chatRepository.createChat(
                type: 'dialog',
                participantId: user.id,
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatId: chatId,
                    chatName: user.username ?? 'Пользователь',
                  ),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Не удалось создать чат: $e')),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: _searchUsers(query),
      builder: _buildUserList,
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Введите имя или email'));
    }
    return FutureBuilder<List<UserModel>>(
      future: _searchUsers(query),
      builder: _buildUserList,
    );
  }
}
