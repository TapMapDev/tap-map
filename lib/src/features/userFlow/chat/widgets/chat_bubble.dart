import 'package:flutter/material.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';
import 'package:tap_map/src/features/userFlow/chat/widgets/bubble_reference.dart';
import 'package:tap_map/src/features/userFlow/chat/widgets/message_content.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback onLongPress;
  final List<MessageModel> messages;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onLongPress,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBubbleColor = isMe ? theme.primaryColor : theme.cardColor;
    final defaultTextColor =
        isMe ? Colors.white : theme.textTheme.bodyLarge?.color;
    final defaultSecondaryColor = isMe ? Colors.white70 : Colors.grey;

    MessageModel? repliedMessage;
    if (message.replyToId != null) {
      repliedMessage = messages.firstWhere(
        (m) => m.id == message.replyToId,
        orElse: () => message,
      );
    }

    MessageModel? forwardedMessage;
    if (message.forwardedFromId != null) {
      forwardedMessage = messages.firstWhere(
        (m) => m.id == message.forwardedFromId,
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
            color: defaultBubbleColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
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
                  text: forwardedMessage?.text ?? 'Сообщение не найдено',
                  label:
                      'Переслано от ${forwardedMessage?.senderUsername ?? "неизвестного пользователя"}:',
                  isMe: isMe,
                  textColor: defaultSecondaryColor,
                ),
              MessageContent(message: message),
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
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
