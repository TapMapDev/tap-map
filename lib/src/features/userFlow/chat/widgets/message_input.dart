import 'package:flutter/material.dart';
import 'package:tap_map/src/features/userFlow/chat/models/message_model.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String) onChanged;
  final MessageModel? editingMessage;
  final VoidCallback? onCancelEdit;
  final String hintText;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSend,
    this.editingMessage,
    this.onCancelEdit,
    this.hintText = 'Введите сообщение...',
    this.backgroundColor,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = theme.scaffoldBackgroundColor;
    final defaultTextColor = theme.textTheme.bodyLarge?.color;
    final defaultIconColor = theme.iconTheme.color;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (editingMessage != null) _buildEditPreview(context),
          _buildInputField(context),
        ],
      ),
    );
  }

  Widget _buildEditPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Row(
        children: [
          Icon(Icons.edit, color: iconColor ?? Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Редактирование сообщения',
                  style: TextStyle(
                    color: textColor ?? Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  editingMessage!.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor ?? Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: iconColor),
            onPressed: onCancelEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              hintStyle: TextStyle(
                color: textColor?.withOpacity(0.5),
              ),
            ),
            style: TextStyle(color: textColor),
            onChanged: onChanged,
            onSubmitted: (_) => onSend(),
          ),
        ),
        IconButton(
          icon: Icon(Icons.send, color: iconColor),
          onPressed: onSend,
        ),
      ],
    );
  }
}
