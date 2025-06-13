import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/features/userFlow/chat/presentation/bloc/chat_bloc/chat_bloc.dart';
import 'package:tap_map/features/userFlow/chat/data/models/message_model.dart';
import 'package:tap_map/features/userFlow/chat/presentation/widgets/bubble_reference.dart';
import 'package:tap_map/features/userFlow/chat/presentation/widgets/message_content.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback onLongPress;
  final List<MessageModel> messages;
  final String currentUsername;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onLongPress,
    required this.messages,
    required this.currentUsername,
  });

  Widget _buildReadStatus(MessageModel message) {
    final isOwnMessage = message.senderUsername == currentUsername;
    if (!isOwnMessage) return const SizedBox.shrink();

    debugPrint(
        'ChatBubble: messageId=${message.id}, isRead=${message.isRead}, currentUser=$currentUsername');

    // TODO: Re-enable read status icons once design is finalized.
    // final icon = message.isRead ? Icons.done_all : Icons.check;
    // final color = message.isRead ? Colors.blue : Colors.grey;

    // return Padding(
    //   padding: const EdgeInsets.only(left: 4),
    //   child: Icon(icon, size: 16, color: color),
    // );

    // Temporarily hide read status visuals while keeping the logic intact.
    return const SizedBox.shrink();
  }

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
                  const SizedBox(width: 4),
                  BlocSelector<ChatBloc, ChatState, MessageModel?>(
                    selector: (state) {
                      if (state is ChatLoaded) {
                        final updatedMessage = state.messages.firstWhere(
                          (m) => m.id == message.id,
                          orElse: () => message,
                        );
                        return updatedMessage;
                      }
                      return message;
                    },
                    builder: (context, updatedMessage) {
                      return _buildReadStatus(updatedMessage ?? message);
                    },
                  ),
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
