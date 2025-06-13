import 'package:flutter/material.dart';

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
