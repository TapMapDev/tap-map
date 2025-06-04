import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_bloc/chat_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/delete_message/delete_message_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/edit_bloc/edit_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/pin_bloc/pin_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/reply_bloc/reply_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/data/chat_repository.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';
import 'package:tap_map/src/features/userFlow/chat/widgets/chat_bubble.dart';
import 'package:tap_map/src/features/userFlow/chat/widgets/message_input.dart';
import 'package:tap_map/src/features/userFlow/chat/widgets/scrollbottom.dart';
import 'package:tap_map/src/features/userFlow/chat/widgets/typing_indicator.dart';
import 'package:tap_map/src/features/userFlow/user_profile/data/user_repository.dart';

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
  String? _currentUsername;
  int? _currentUserId;
  MessageModel? _forwardFrom;
  bool _isTyping = false;
  MessageModel? _editingMessage;
  File? _selectedMediaFile;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    print(
        '🚀 ChatScreen: Initializing with chatId: ${widget.chatId}, chatName: ${widget.chatName}');
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
      print(
          '👤 ChatScreen: Loading current user - username: ${user.username}, id: ${user.id}');
      setState(() {
        _currentUsername = user.username;
        _currentUserId = user.id;
      });
      print(
          '👤 ChatScreen: Current user set - username: $_currentUsername, id: $_currentUserId');
    } catch (e) {
      print('❌ ChatScreen: Error loading current user: $e');
    }
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

    if (_selectedMediaFile != null || text.isNotEmpty) {
      if (_editingMessage != null) {
        context.read<EditBloc>().add(EditMessageRequest(
              chatId: widget.chatId,
              messageId: _editingMessage!.id,
              text: text,
              context: context,
            ));
      } else if (_selectedMediaFile != null) {
        _chatBloc.add(UploadFile(
          file: _selectedMediaFile!,
          caption: text,
        ));
        setState(() {
          _selectedMediaFile = null;
        });
      } else {
        final replyState = context.read<ReplyBloc>().state;

        int? replyToId;
        if (replyState is ReplyActive) {
          replyToId = replyState.message.id;
        }

        _chatBloc.add(
          SendMessage(
            chatId: widget.chatId,
            text: text,
            replyToId: replyToId,
            forwardedFromId: _forwardFrom?.id,
          ),
        );

        if (replyToId != null) {
          context.read<ReplyBloc>().add(const ClearReplyTo());
        }

        if (_forwardFrom != null) {
          setState(() {
            _forwardFrom = null;
          });
        }
      }

      _messageController.clear();
      _scrollToBottom();
    }
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
          body: MultiBlocListener(
            listeners: [
              BlocListener<DeleteMessageBloc, DeleteMessageState>(
                listener: (context, state) {
                  if (state is DeleteMessageSuccess) {
                    // После успешного удаления обновляем список сообщений в ChatBloc
                    final currentState = _chatBloc.state;
                    if (currentState is ChatLoaded) {
                      final updatedMessages = currentState.messages
                          .where((msg) => msg.id != state.messageId)
                          .toList();

                      // Эмитим новое состояние с обновленным списком сообщений
                      _chatBloc.emit(currentState.copyWith(
                        messages: updatedMessages,
                      ));

                      // Показываем уведомление об успешном удалении
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Сообщение удалено')),
                      );
                    }
                  } else if (state is DeleteMessageFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Ошибка при удалении: ${state.error}')),
                    );
                  }
                },
              ),
              BlocListener<EditBloc, EditState>(
                listener: (context, state) {
                  print('EditBloc state changed: $state');
                  print('Current editing message: $_editingMessage');
                  if (state is EditInProgress) {
                    print(
                        'Setting editing message with ID: ${state.messageId}');
                    setState(() {
                      print('Inside setState, before setting _editingMessage');
                      _editingMessage = MessageModel(
                        id: state.messageId,
                        text: state.originalText,
                        senderUsername: _currentUsername ?? '',
                        createdAt: DateTime.now(),
                        chatId: widget.chatId,
                      );
                      _messageController.text = state.originalText;
                      print(
                          'Inside setState, after setting _editingMessage: $_editingMessage');
                    });
                    print('After setState, editing message: $_editingMessage');
                  } else if (state is EditSuccess) {
                    print('Edit success, clearing editing state');
                    setState(() {
                      _editingMessage = null;
                      _messageController.clear();
                    });
                  } else if (state is EditFailure) {
                    print('Edit failed: ${state.error}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Ошибка при редактировании: ${state.error}')),
                    );
                  }
                },
              ),
            ],
            child: Stack(
              children: [
                Column(
                  children: [
                    BlocBuilder<PinBloc, PinBlocState>(
                      builder: (context, state) {
                        if (state is MessagePinned) {
                          return Container(
                            padding: const EdgeInsets.all(8.0),
                            color: Colors.amber.withOpacity(0.2),
                            child: Row(
                              children: [
                                const Icon(Icons.push_pin, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.pinnedMessage.text,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    context.read<PinBloc>().add(UnpinMessage(
                                          chatId: widget.chatId,
                                          messageId: state.pinnedMessage.id,
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
                    Expanded(
                      child: BlocBuilder<ChatBloc, ChatState>(
                        builder: (context, state) {
                          if (state is ChatLoading) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (state is ChatLoaded) {
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
                                print(
                                    '📱 Message from ${message.senderUsername}, isMe: $isMe, currentUsername: $_currentUsername');

                                return ChatBubble(
                                  message: message,
                                  isMe: isMe,
                                  onLongPress: () =>
                                      _showMessageActions(message),
                                  messages: state.messages,
                                  currentUsername: _currentUsername ?? '',
                                );
                              },
                            );
                          }

                          return const SizedBox();
                        },
                      ),
                    ),
                    BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, state) {
                        if (state is ChatLoaded &&
                            state.typingUsers.isNotEmpty) {
                          final otherTypingUsers = state.typingUsers
                              .where((username) => username != _currentUsername)
                              .toSet();

                          if (otherTypingUsers.isNotEmpty) {
                            return TypingIndicator(
                                typingUsers: otherTypingUsers);
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    BlocBuilder<ReplyBloc, ReplyState>(
                      builder: (context, state) {
                        if (state is ReplyActive) {
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ответ на сообщение',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        state.message.text,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    context
                                        .read<ReplyBloc>()
                                        .add(const ClearReplyTo());
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    if (_selectedMediaFile != null)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        color: Theme.of(context).cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isVideo ? Icons.videocam : Icons.image,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isVideo ? 'Видео' : 'Изображение',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _selectedMediaFile = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _isVideo
                                    ? Container(
                                        color: Colors.black87,
                                        child: const Center(
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Icon(
                                                Icons.video_file,
                                                size: 48,
                                                color: Colors.white54,
                                              ),
                                              Icon(
                                                Icons.play_circle_outline,
                                                size: 48,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : Image.file(
                                        _selectedMediaFile!,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
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
                        final fileToUpload = File(file.path!);
                        final isVideo =
                            file.path!.toLowerCase().endsWith('.mp4') ||
                                file.path!.toLowerCase().endsWith('.mov') ||
                                file.path!.toLowerCase().endsWith('.avi') ||
                                file.path!.toLowerCase().endsWith('.webm');

                        setState(() {
                          _selectedMediaFile = fileToUpload;
                          _isVideo = isVideo;
                        });
                      },
                      onImageSelected: (file) {
                        final fileToUpload = File(file.path);
                        final isVideo =
                            file.path.toLowerCase().endsWith('.mp4') ||
                                file.path.toLowerCase().endsWith('.mov') ||
                                file.path.toLowerCase().endsWith('.avi') ||
                                file.path.toLowerCase().endsWith('.webm');

                        setState(() {
                          _selectedMediaFile = fileToUpload;
                          _isVideo = isVideo;
                        });
                      },
                      editingMessage: _editingMessage,
                      onCancelEdit: () {
                        context.read<EditBloc>().add(const CancelEdit());
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
              context.read<ReplyBloc>().add(SetReplyTo(message));
            },
          ),
          // ListTile(
          //   leading: const Icon(Icons.forward),
          //   title: const Text('Переслать'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     _showChatSelectionDialog(message);
          //   },
          // ),
          if (message.senderUsername == _currentUsername) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Редактировать'),
              onTap: () {
                print('Edit button tapped for message: ${message.id}');
                print('Message text: ${message.text}');
                Navigator.pop(context);
                print('Navigator popped');
                context.read<EditBloc>().add(StartEditing(
                      messageId: message.id,
                      originalText: message.text,
                    ));
                print('StartEditing event added to EditBloc');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Удалить только у себя'),
              onTap: () {
                Navigator.pop(context);
                context.read<DeleteMessageBloc>().add(DeleteMessageRequest(
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
                context.read<DeleteMessageBloc>().add(DeleteMessageRequest(
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
                context.read<PinBloc>().add(PinMessage(
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

  // Функции пересылки сообщений временно отключены
  /*
  void _forwardMessageToChat(MessageModel message, int targetChatId) {
    _chatBloc.add(SendMessage(
      chatId: targetChatId,
      text: message.text,
      forwardedFromId: message.id,
    ));
  }

  Future<void> _showChatSelectionDialog(MessageModel message) async {
    try {
      final chats = await _chatRepository.fetchChats();

      final availableChats =
          chats.where((chat) => chat.chatId != widget.chatId).toList();

      if (!mounted) return;

      if (availableChats.isEmpty) {
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке чатов: $e')),
      );
    }
  }
  */
}
