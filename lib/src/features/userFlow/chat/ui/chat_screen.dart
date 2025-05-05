import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/core/websocket/websocket_service.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_api_service.dart';
import 'package:tap_map/src/features/userFlow/user_profile/data/user_repository.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String chatName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late WebSocketService _webSocketService;
  late ChatApiService _chatApiService;
  late UserRepository _userRepository;
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  ChatMessage? _replyToMessage;
  ChatMessage? _forwardFromMessage;
  bool _isConnected = false;
  bool _isLoading = true;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _chatApiService = GetIt.instance<ChatApiService>();
    _userRepository = GetIt.instance<UserRepository>();
    _initializeWebSocket();
    _loadCurrentUser();
    _loadChatHistory();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userRepository.getCurrentUser();
      setState(() {
        _currentUsername = user.username;
      });
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await _chatApiService.getChatHistory(widget.chatId);
      setState(() {
        _messages.clear();
        _messages.addAll(history.map((message) => ChatMessage(
              id: message.id,
              text: message.text,
              isMe: message.senderUsername == _currentUsername,
              replyTo: message.replyToId != null
                  ? _messages.firstWhere(
                      (m) => m.id == message.replyToId,
                      orElse: () => ChatMessage(
                        id: message.replyToId!,
                        text: 'Сообщение не найдено',
                        isMe: false,
                      ),
                    )
                  : null,
              forwardedFrom: message.forwardedFromId != null
                  ? _messages.firstWhere(
                      (m) => m.id == message.forwardedFromId,
                      orElse: () => ChatMessage(
                        id: message.forwardedFromId!,
                        text: 'Сообщение не найдено',
                        isMe: false,
                      ),
                    )
                  : null,
            )));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось загрузить историю сообщений'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initializeWebSocket() async {
    final token =
        await GetIt.instance<SharedPrefsRepository>().getAccessToken();
    if (token == null) {
      print('❌ No access token available');
      return;
    }

    _webSocketService = WebSocketService(jwtToken: token);
    _webSocketService.connect();
    setState(() {
      _isConnected = true;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _webSocketService.disconnect();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showMessageActions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('Ответить'),
            onTap: () {
              setState(() {
                _replyToMessage = message;
                _forwardFromMessage = null;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.forward),
            title: const Text('Переслать'),
            onTap: () {
              setState(() {
                _forwardFromMessage = message;
                _replyToMessage = null;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chatName),
            Text(
              _isConnected ? 'Подключено' : 'Отключено',
              style: TextStyle(
                fontSize: 12,
                color: _isConnected ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: () {
              if (!_isConnected) {
                _initializeWebSocket();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Reply/Forward preview
          if (_replyToMessage != null || _forwardFromMessage != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Icon(
                    _replyToMessage != null ? Icons.reply : Icons.forward,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyToMessage != null
                              ? 'Ответ на:'
                              : 'Переслано из:',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          (_replyToMessage ?? _forwardFromMessage)!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _replyToMessage = null;
                        _forwardFromMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    padding: const EdgeInsets.all(8.0),
                    reverse: true,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return GestureDetector(
                        onLongPress: () => _showMessageActions(message),
                        child: Align(
                          alignment: message.isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 8.0,
                            ),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: message.isMe
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message.replyTo != null)
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ответ на:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: message.isMe
                                                ? Colors.white.withOpacity(0.7)
                                                : Colors.black.withOpacity(0.7),
                                          ),
                                        ),
                                        Text(
                                          message.replyTo!.text,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: message.isMe
                                                ? Colors.white.withOpacity(0.7)
                                                : Colors.black.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (message.forwardedFrom != null)
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Переслано из:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: message.isMe
                                                ? Colors.white.withOpacity(0.7)
                                                : Colors.black.withOpacity(0.7),
                                          ),
                                        ),
                                        Text(
                                          message.forwardedFrom!.text,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: message.isMe
                                                ? Colors.white.withOpacity(0.7)
                                                : Colors.black.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      message.text,
                                      style: TextStyle(
                                        color: message.isMe
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: message.isMe
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.black.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Message input
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
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
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      final message = _messageController.text;
      _webSocketService.sendMessage(
        chatId: widget.chatId,
        text: message,
        replyToId: _replyToMessage?.id,
        forwardedFromId: _forwardFromMessage?.id,
      );

      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          text: message,
          isMe: true,
          replyTo: _replyToMessage,
          forwardedFrom: _forwardFromMessage,
          timestamp: DateTime.now(),
        ));
        _messageController.clear();
        _replyToMessage = null;
        _forwardFromMessage = null;
      });

      _scrollToBottom();
    }
  }
}

class ChatMessage {
  final int id;
  final String text;
  final bool isMe;
  final ChatMessage? replyTo;
  final ChatMessage? forwardedFrom;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    this.replyTo,
    this.forwardedFrom,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
