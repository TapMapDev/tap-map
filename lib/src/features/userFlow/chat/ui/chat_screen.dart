import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/core/websocket/websocket_service.dart';
import 'package:tap_map/src/features/userFlow/chat/services/chat_api_service.dart';
import 'package:tap_map/src/features/userFlow/user_profile/data/user_repository.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String chatName;
  const ChatScreen({super.key, required this.chatId, required this.chatName});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final WebSocketService _webSocketService;
  late final ChatApiService _chatApiService;
  late final UserRepository _userRepository;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  StreamSubscription? _wsSubscription;
  String? _currentUsername;
  ChatMessage? _replyTo;
  ChatMessage? _forwardFrom;
  bool _isLoading = true;
  bool _isTyping = false;
  bool _otherUserIsTyping = false;
  String? _typingUsername;
  bool _showScrollDownButton = false;

  @override
  void initState() {
    super.initState();
    _chatApiService = GetIt.instance<ChatApiService>();
    _userRepository = GetIt.instance<UserRepository>();
    _initChat();
    _scrollController.addListener(_handleScrollBtnVisibility);
  }

  Future<void> _initChat() async {
    await _loadCurrentUser();
    await _loadChatHistory();
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
    try {
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
        // TODO: handle other event types (new message, read, etc)
      }
    } catch (_) {}
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userRepository.getCurrentUser();
      _currentUsername = user.username;
    } catch (_) {}
  }

  Future<void> _loadChatHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _chatApiService.getChatHistory(widget.chatId);
      _messages
        ..clear()
        ..addAll(history.map((m) => ChatMessage(
              id: m.id,
              text: m.text,
              isMe: m.senderUsername == _currentUsername,
              replyTo: m.replyToId != null
                  ? _messages.firstWhere(
                      (msg) => msg.id == m.replyToId,
                      orElse: () => ChatMessage(
                        id: m.replyToId!,
                        text: 'Сообщение не найдено',
                        isMe: false,
                      ),
                    )
                  : null,
              forwardedFrom: m.forwardedFromId != null
                  ? _messages.firstWhere(
                      (msg) => msg.id == m.forwardedFromId,
                      orElse: () => ChatMessage(
                        id: m.forwardedFromId!,
                        text: 'Сообщение не найдено',
                        isMe: false,
                      ),
                    )
                  : null,
            )));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось загрузить историю сообщений'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleScrollBtnVisibility() {
    if (!_scrollController.hasClients) return;
    final shouldShow = _scrollController.offset > 200;
    if (_showScrollDownButton != shouldShow) {
      setState(() => _showScrollDownButton = shouldShow);
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
    if (text.isEmpty) return;
    _webSocketService.sendMessage(
      chatId: widget.chatId,
      text: text,
      replyToId: _replyTo?.id,
      forwardedFromId: _forwardFrom?.id,
    );
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          text: text,
          isMe: true,
          replyTo: _replyTo,
          forwardedFrom: _forwardFrom,
          timestamp: DateTime.now(),
        ),
      );
      _messageController.clear();
      _replyTo = null;
      _forwardFrom = null;
      _isTyping = false;
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _webSocketService.disconnect();
    _messageController.dispose();
    _scrollController.removeListener(_handleScrollBtnVisibility);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chatName)),
      body: Stack(
        children: [
          Column(
            children: [
              if (_otherUserIsTyping)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_typingUsername ?? "Собеседник"} печатает...',
                      style: const TextStyle(
                          color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              if (_replyTo != null || _forwardFrom != null)
                _ReplyForwardPreview(
                  replyTo: _replyTo,
                  forwardFrom: _forwardFrom,
                  onClose: () => setState(() {
                    _replyTo = null;
                    _forwardFrom = null;
                  }),
                ),
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
                            child: _ChatBubble(message: message),
                          );
                        },
                      ),
              ),
              _MessageInput(
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
              ),
            ],
          ),
          if (_showScrollDownButton)
            Positioned(
              right: 16,
              bottom: 80,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                onPressed: _scrollToBottom,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.arrow_downward, color: Colors.white),
              ),
            ),
        ],
      ),
    );
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
                _replyTo = message;
                _forwardFrom = null;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.forward),
            title: const Text('Переслать'),
            onTap: () {
              setState(() {
                _forwardFrom = message;
                _replyTo = null;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _ReplyForwardPreview extends StatelessWidget {
  final ChatMessage? replyTo;
  final ChatMessage? forwardFrom;
  final VoidCallback onClose;
  const _ReplyForwardPreview(
      {this.replyTo, this.forwardFrom, required this.onClose});
  @override
  Widget build(BuildContext context) {
    final message = replyTo ?? forwardFrom;
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Row(
        children: [
          Icon(replyTo != null ? Icons.reply : Icons.forward,
              color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(replyTo != null ? 'Ответ на:' : 'Переслано из:',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(message?.text ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color:
              message.isMe ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.replyTo != null)
              _BubbleReference(
                  text: message.replyTo!.text,
                  label: 'Ответ на:',
                  isMe: message.isMe),
            if (message.forwardedFrom != null)
              _BubbleReference(
                  text: message.forwardedFrom!.text,
                  label: 'Переслано из:',
                  isMe: message.isMe),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(message.text,
                    style: TextStyle(
                        color: message.isMe ? Colors.white : Colors.black)),
                Text(
                  '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                      fontSize: 10,
                      color: message.isMe
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black.withOpacity(0.7)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleReference extends StatelessWidget {
  final String text;
  final String label;
  final bool isMe;
  const _BubbleReference(
      {required this.text, required this.label, required this.isMe});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: isMe
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black.withOpacity(0.7))),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: isMe
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black.withOpacity(0.7))),
        ],
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  const _MessageInput(
      {required this.controller,
      required this.onChanged,
      required this.onSend});
  @override
  Widget build(BuildContext context) {
    return Container(
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
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Введите сообщение...',
                border: InputBorder.none,
              ),
              onChanged: onChanged,
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: onSend,
          ),
        ],
      ),
    );
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
