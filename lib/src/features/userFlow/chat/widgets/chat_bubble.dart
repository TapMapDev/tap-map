import 'package:flutter/material.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final Color? bubbleColor;
  final Color? textColor;
  final Color? secondaryTextColor;
  final double maxWidth;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.bubbleColor,
    this.textColor,
    this.secondaryTextColor,
    this.maxWidth = 0.75,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBubbleColor = isMe ? theme.primaryColor : Colors.grey[300];
    final defaultTextColor = isMe ? Colors.white : Colors.black;
    final defaultSecondaryColor =
        isMe ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7);

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
                  text: 'Ответ на сообщение',
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
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: textColor ?? defaultTextColor,
                      ),
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.isEdited) ...[
                        Text(
                          '(ред.)',
                          style: TextStyle(
                            fontSize: 10,
                            color: secondaryTextColor ?? defaultSecondaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: secondaryTextColor ?? defaultSecondaryColor,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done,
                          size: 14,
                          color: secondaryTextColor ?? defaultSecondaryColor,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
