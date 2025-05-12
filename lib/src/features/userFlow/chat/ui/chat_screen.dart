import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/core/websocket/websocket_service.dart';
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
  late final WebSocketService _webSocketService;
  late final ChatRepository _chatRepository;
  late final UserRepository _userRepository;
  late final ChatBloc _chatBloc;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<MessageModel> _messages = [];
  StreamSubscription? _wsSubscription;
  String? _currentUsername;
  int? _currentUserId;
  MessageModel? _replyTo;
  MessageModel? _forwardFrom;
  final bool _isLoading = true;
  bool _isTyping = false;
  bool _otherUserIsTyping = false;
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
    await _initWebSocket();
  }

  Future<void> _initWebSocket() async {
    final token =
        await GetIt.instance<SharedPrefsRepository>().getAccessToken();
    if (token == null) return;
    _webSocketService = WebSocketService(jwtToken: token);
    _webSocketService.connect();
    await _wsSubscription?.cancel();
    _wsSubscription = _webSocketService.stream.listen(_onSocketEvent);
  }

  void _onSocketEvent(dynamic data) {
    final decoded = jsonDecode(data is String ? data : data.toString());
    if (decoded is! Map<String, dynamic>) return;

    switch (decoded['type']) {
      case 'typing':
        if (decoded['chat_id'] == widget.chatId) {
          setState(() {
            _otherUserIsTyping = decoded['is_typing'] == true;
            _typingUsername = decoded['username'] ?? 'Собеседник';
          });
        }
        break;

      case 'message':
        if (decoded['chat_id'] == widget.chatId) {
          setState(() {
            _messages.insert(
              0,
              MessageModel(
                id: decoded['message_id'] as int,
                text: decoded['text'] as String,
                chatId: widget.chatId,
                senderUsername: decoded['sender_username'] as String,
                createdAt: DateTime.parse(decoded['created_at'] as String),
              ),
            );
          });
        }
        break;

      case 'read_message':
        if (decoded['chat_id'] == widget.chatId) {
          final readerId = decoded['reader_id'] as int?;
          if (readerId != null && readerId != _currentUserId) {
            setState(() {
              final messageId = decoded['message_id'] as int;
              final messageIndex =
                  _messages.indexWhere((m) => m.id == messageId);
              if (messageIndex != -1) {
                _messages[messageIndex] = _messages[messageIndex].copyWith();
              }
            });
          }
        }
        break;
    }
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
      _chatBloc.add(
        SendMessage(
          chatId: widget.chatId,
          text: text,
        ),
      );
    }

    _messageController.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _webSocketService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    _chatBloc.add(DisconnectFromChat());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chatName)),
      body: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is states.NewMessageReceived) {
            _scrollToBottom();
          }
        },
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      if (state is states.ChatLoaded) {
                        final messages = state.messages;
                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: messages.length,
                          padding: const EdgeInsets.all(8.0),
                          reverse: true,
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width,
                              ),
                              child: ChatBubble(
                                message: message,
                                isMe:
                                    message.senderUsername == _currentUsername,
                                onLongPress: () => _showMessageActions(message),
                              ),
                            );
                          },
                        );
                      } else if (state is states.ChatLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                ),
                MessageInput(
                  controller: _messageController,
                  onChanged: (text) {
                    if (!_isTyping && text.isNotEmpty) {
                      _isTyping = true;
                      _webSocketService.sendTyping(
                          chatId: widget.chatId, isTyping: true);
                    } else if (_isTyping && text.isEmpty) {
                      _isTyping = false;
                      _webSocketService.sendTyping(
                          chatId: widget.chatId, isTyping: false);
                    }
                  },
                  onSend: _sendMessage,
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
            },
          ),
          ListTile(
            leading: const Icon(Icons.forward),
            title: const Text('Переслать'),
            onTap: () {
              Navigator.pop(context);
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
          ],
        ],
      ),
    );
  }
}
