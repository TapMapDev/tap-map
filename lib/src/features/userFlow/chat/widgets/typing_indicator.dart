import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  final Set<String> typingUsers;

  const TypingIndicator({
    super.key,
    required this.typingUsers,
  });

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodySmall?.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(textColor ?? Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getTypingText(typingUsers),
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypingText(Set<String> users) {
    if (users.isEmpty) return '';
    if (users.length == 1) {
      return '${users.first} печатает...';
    }
    if (users.length == 2) {
      return '${users.first} и ${users.last} печатают...';
    }
    return 'Несколько пользователей печатают...';
  }
}
