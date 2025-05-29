// Чипы "Особенности"
import 'package:flutter/material.dart';
import 'package:tap_map/ui/theme/app_colors.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';

class FeaturesSection extends StatelessWidget {
  final List<String> features; // пример: ['Wi-Fi', 'Парковка 🚗', …]
  final VoidCallback? onMoreTap;

  const FeaturesSection({
    Key? key,
    required this.features,
    this.onMoreTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final display = features.take(5).toList();
    final hasMore = features.length > 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Особенности', style: AppTextStyles.h18),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...display.map(_chip),
              if (hasMore) _chip('Ещё', trailing: const Icon(Icons.add, size: 16), onTap: onMoreTap),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, {Widget? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryLightest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: AppTextStyles.caption14Dark),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
