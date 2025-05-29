// Плитка "Откроется через..."
import 'package:flutter/material.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';
import 'package:tap_map/ui/theme/app_colors.dart';

class OpenStatusSection extends StatelessWidget {
  final String statusText;   // «Откроется через 35 минут»
  final IconData? icon;      // можно передать clock icon
  final Color? statusColor;  // по желанию окрасить

  const OpenStatusSection({
    Key? key,
    required this.statusText,
    this.icon,
    this.statusColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.primary20,
            child: icon != null
                ? Icon(icon, color: AppColors.dark, size: 20)
                : const Text('🕒', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              statusText,
              style: AppTextStyles.body16.copyWith(
                color: statusColor ?? AppColors.dark,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.grey),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
