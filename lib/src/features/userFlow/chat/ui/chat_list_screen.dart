import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/ui/chat_screen.dart';

import '../bloc/chat_bloc.dart';
import '../models/chat_model.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Загружаем список чатов при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatBloc>().add(FetchChats());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatDisconnected) {
            context.read<ChatBloc>().add(FetchChats());
          } else if (state is MessageDeleted) {
            context.read<ChatBloc>().add(FetchChats());
          }
        },
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChatError) {
            return Center(child: Text(state.message));
          }

          if (state is ChatsLoaded) {
            if (state.chats.isEmpty) {
              return const Center(child: Text('Нет доступных чатов'));
            }
            return _buildChatList(state.chats);
          }

          return const Center(child: Text('Нет доступных чатов'));
        },
      ),
    );
  }

  Widget _buildChatList(List<ChatModel> chats) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ChatBloc>().add(FetchChats());
      },
      child: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return _ChatListItem(chat: chat);
        },
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final ChatModel chat;

  const _ChatListItem({required this.chat});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(chat.chatName[0].toUpperCase()),
      ),
      title: Text(chat.chatName),
      subtitle: Text(
        chat.lastMessageText ?? 'Нет сообщений',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (chat.lastMessageCreatedAt != null)
            Text(
              _formatDateTime(chat.lastMessageCreatedAt!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (chat.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chat.chatId,
              chatName: chat.chatName,
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return _getWeekdayName(dateTime.weekday);
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}';
    }
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Пн';
      case 2:
        return 'Вт';
      case 3:
        return 'Ср';
      case 4:
        return 'Чт';
      case 5:
        return 'Пт';
      case 6:
        return 'Сб';
      case 7:
        return 'Вс';
      default:
        return '';
    }
  }
}
