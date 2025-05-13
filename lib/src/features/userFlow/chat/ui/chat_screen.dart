import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_event.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_state.dart'
    as states;
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_state.dart';
import 'package:tap_map/src/features/userFlow/chat/data/chat_repository.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';
import 'package:tap_map/src/features/userFlow/chat/widgets/chat_bubble.dart';
import 'package:tap_map/src/features/userFlow/chat/widgets/message_input.dart';
import 'package:tap_map/src/features/userFlow/chat/widgets/scrollbottom.dart';
import 'package:tap_map/src/features/userFlow/user_profile/data/user_repository.dart';

enum MessageStatus {
  sent,
  delivered,
  read,
}

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String chatName;
  const ChatScreen({super.key, required this.chatId, required this.chatName});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatRepository _chatRepository;
  late final UserRepository _userRepository;
  late final ChatBloc _chatBloc;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<MessageModel> _messages = [];
  String? _currentUsername;
  int? _currentUserId;
  MessageModel? _replyTo;
  MessageModel? _forwardFrom;
  final bool _isLoading = true;
  bool _isTyping = false;
  final bool _otherUserIsTyping = false;
  String? _typingUsername;
  MessageModel? _editingMessage;

  @override
  void initState() {
    super.initState();
    _chatRepository = GetIt.instance<ChatRepository>();
    _userRepository = GetIt.instance<UserRepository>();
    _chatBloc = context.read<ChatBloc>();
    _initChat();
    _chatBloc.add(ConnectToChat(widget.chatId));
    _chatBloc.add(FetchChatById(widget.chatId));
  }

  Future<void> _initChat() async {
    await _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userRepository.getCurrentUser();
      _currentUsername = user.username;
      _currentUserId = user.id;
    } catch (_) {}
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_editingMessage != null) {
      _chatBloc.add(EditMessage(
        chatId: widget.chatId,
        messageId: _editingMessage!.id,
        text: text,
      ));
      setState(() {
        _editingMessage = null;
      });
    } else {
      final currentState = context.read<ChatBloc>().state;
      final replyToId =
          currentState is states.ChatLoaded ? currentState.replyTo?.id : null;

      _chatBloc.add(
        SendMessage(
          chatId: widget.chatId,
          text: text,
          replyToId: replyToId,
        ),
      );
    }

    _messageController.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatBloc.add(DisconnectFromChat());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          Navigator.of(context).pop();
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          Navigator.of(context).pop();
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: () {
                context.push('/users/${widget.chatName}');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.chatName),
                  const SizedBox(width: 4),
                  const Icon(Icons.kayaking, size: 20),
                ],
              ),
            ),
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      if (state is ChatLoaded &&
                          state.pinnedMessage != null &&
                          state.messages
                              .any((m) => m.id == state.pinnedMessage!.id)) {
                        return Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Colors.amber.withOpacity(0.2),
                          child: Row(
                            children: [
                              const Icon(Icons.push_pin, color: Colors.amber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.pinnedMessage!.text,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  context.read<ChatBloc>().add(UnpinMessage(
                                        chatId: widget.chatId,
                                        messageId: state.pinnedMessage!.id,
                                      ));
                                },
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      if (state is states.ChatLoaded && state.replyTo != null) {
                        return Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Theme.of(context).cardColor,
                          child: Row(
                            children: [
                              Icon(
                                Icons.reply,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ответ на сообщение',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      state.replyTo!.text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  context.read<ChatBloc>().add(ClearReplyTo());
                                },
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Expanded(
                    child: BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, state) {
                        if (state is states.ChatLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (state is states.ChatLoaded) {
                          if (state.messages.isEmpty) {
                            return const Center(
                              child: Text('Нет сообщений'),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              final message = state.messages[index];
                              final isMe =
                                  message.senderUsername == _currentUsername;

                              return ChatBubble(
                                message: message,
                                isMe: isMe,
                                onLongPress: () => _showMessageActions(message),
                                messages: state.messages,
                              );
                            },
                          );
                        }

                        return const SizedBox();
                      },
                    ),
                  ),
                  MessageInput(
                    controller: _messageController,
                    onSend: _sendMessage,
                    onChanged: (text) {
                      if (!_isTyping && text.isNotEmpty) {
                        _isTyping = true;
                        _chatBloc.add(SendTyping(
                          chatId: widget.chatId,
                          isTyping: true,
                        ));
                      } else if (_isTyping && text.isEmpty) {
                        _isTyping = false;
                        _chatBloc.add(SendTyping(
                          chatId: widget.chatId,
                          isTyping: false,
                        ));
                      }
                    },
                    onFileSelected: (file) {
                      print('📤 File selected in ChatScreen: ${file.path}');
                      final fileToUpload = File(file.path!);
                      print(
                          '📤 Converting to File object: ${fileToUpload.path}');
                      _chatBloc.add(UploadFile(file: fileToUpload));
                      print('📤 UploadFile event added to ChatBloc');
                    },
                    onImageSelected: (file) {
                      print(
                          '📤 Image/Video selected in ChatScreen: ${file.path}');
                      final fileToUpload = File(file.path);
                      print(
                          '📤 Converting to File object: ${fileToUpload.path}');
                      _chatBloc.add(UploadFile(file: fileToUpload));
                      print('📤 UploadFile event added to ChatBloc');
                    },
                    editingMessage: _editingMessage,
                    onCancelEdit: () {
                      setState(() {
                        _editingMessage = null;
                        _messageController.clear();
                      });
                    },
                  ),
                ],
              ),
              ScrollToBottomButton(
                scrollController: _scrollController,
                onPressed: _scrollToBottom,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageActions(MessageModel message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('Ответить'),
            onTap: () {
              Navigator.pop(context);
              context.read<ChatBloc>().add(SetReplyTo(message));
            },
          ),
          ListTile(
            leading: const Icon(Icons.forward),
            title: const Text('Переслать'),
            onTap: () {
              Navigator.pop(context);
              _showChatSelectionDialog(message);
            },
          ),
          if (message.senderUsername == _currentUsername) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Редактировать'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _editingMessage = message;
                  _messageController.text = message.text;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Удалить только у себя'),
              onTap: () {
                Navigator.pop(context);
                _chatBloc.add(DeleteMessage(
                  chatId: widget.chatId,
                  messageId: message.id,
                  action: 'for_me',
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _chatBloc.add(DeleteMessage(
                  chatId: widget.chatId,
                  messageId: message.id,
                  action: 'for_all',
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: const Text('Закрепить сообщение'),
              onTap: () {
                Navigator.of(context).pop();
                context.read<ChatBloc>().add(PinMessage(
                      chatId: widget.chatId,
                      messageId: message.id,
                    ));
              },
            ),
          ],
        ],
      ),
    );
  }

  void _forwardMessageToChat(MessageModel message, int targetChatId) {
    print('🔄 Starting message forward process');
    print('📨 Original message: ${message.text}');
    print('🎯 Target chat ID: $targetChatId');
    print('📝 Original message ID: ${message.id}');

    _chatBloc.add(SendMessage(
      chatId: targetChatId,
      text: message.text,
      forwardedFromId: message.id,
    ));
    print('✅ Forward event added to ChatBloc');
  }

  Future<void> _showChatSelectionDialog(MessageModel message) async {
    print('🔍 Opening chat selection dialog');
    print('📨 Message to forward: ${message.text}');
    try {
      final chats = await _chatRepository.fetchChats();
      print('📱 Fetched ${chats.length} chats');

      final availableChats =
          chats.where((chat) => chat.chatId != widget.chatId).toList();
      print('🎯 Available chats for forwarding: ${availableChats.length}');

      if (!mounted) return;

      if (availableChats.isEmpty) {
        print('⚠️ No available chats for forwarding');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет доступных чатов для пересылки')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Выберите чат для пересылки'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableChats.length,
              itemBuilder: (context, index) {
                final chat = availableChats[index];
                return ListTile(
                  title: Text(chat.chatName),
                  onTap: () {
                    print(
                        '🎯 Selected chat for forwarding: ${chat.chatName} (ID: ${chat.chatId})');
                    Navigator.pop(context);
                    _forwardMessageToChat(message, chat.chatId);
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      print('❌ Error in chat selection: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке чатов: $e')),
      );
    }
  }
}
