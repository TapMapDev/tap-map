import 'package:flutter/material.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final Color? bubbleColor;
  final Color? textColor;
  final double maxWidth;
  final List<MessageModel>? messages;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onLongPress,
    this.bubbleColor,
    this.textColor,
    this.maxWidth = 0.7,
    this.messages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBubbleColor = isMe ? theme.primaryColor : theme.cardColor;
    final defaultTextColor =
        isMe ? Colors.white : theme.textTheme.bodyLarge?.color;
    final defaultSecondaryColor = isMe ? Colors.white70 : Colors.grey;

    MessageModel? repliedMessage;
    if (message.replyToId != null && messages != null) {
      repliedMessage = messages!.firstWhere(
        (m) => m.id == message.replyToId,
        orElse: () => message,
      );
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: bubbleColor ?? defaultBubbleColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * maxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.replyToId != null)
                BubbleReference(
                  text: repliedMessage?.text ?? 'Сообщение не найдено',
                  label: 'Ответ на:',
                  isMe: isMe,
                  textColor: defaultSecondaryColor,
                ),
              if (message.forwardedFromId != null)
                BubbleReference(
                  text: 'Пересланное сообщение',
                  label: 'Переслано из:',
                  isMe: isMe,
                  textColor: defaultSecondaryColor,
                ),
              Text(
                message.text,
                style: TextStyle(
                  color: textColor ?? defaultTextColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: defaultSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                  if (message.editedAt != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(ред.)',
                      style: TextStyle(
                        color: defaultSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class BubbleReference extends StatelessWidget {
  final String text;
  final String label;
  final bool isMe;
  final Color? textColor;
  final Color? backgroundColor;

  const BubbleReference({
    super.key,
    required this.text,
    required this.label,
    required this.isMe,
    this.textColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = textColor ??
        (isMe ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7));
    final defaultBackgroundColor =
        backgroundColor ?? Colors.white.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: defaultBackgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: defaultTextColor,
            ),
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: defaultTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
