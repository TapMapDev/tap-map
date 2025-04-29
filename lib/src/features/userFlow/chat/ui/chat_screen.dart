import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<MessageModel> _messages = [];

  @override
  void initState() {
    super.initState();
    // Инициализация чата
    context.read<ChatBloc>().add(FetchChatById(widget.chatId));
    context.read<ChatBloc>().add(SendTyping(widget.chatId));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      context.read<ChatBloc>().add(
            SendMessage(
              chatId: widget.chatId,
              text: _messageController.text,
            ),
          );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чат'),
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is MessageReceived) {
            final message = MessageModel.fromJson(state.message);
            setState(() {
              _messages.add(message);
            });
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          } else if (state is TypingStatus) {
            // Показать индикатор печати
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Пользователь ${state.userId} печатает...'),
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is ChatError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return ListTile(
                      title: Text(message.text),
                      subtitle: Text(
                        'От: ${message.userId}',
                      ),
                      trailing: Text(
                        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Введите сообщение...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (text) {
                          if (text.isNotEmpty) {
                            context
                                .read<ChatBloc>()
                                .add(SendTyping(widget.chatId));
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
