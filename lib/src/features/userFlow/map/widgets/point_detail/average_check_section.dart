// Строка "Средний чек"
import 'package:flutter/material.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';
import 'package:tap_map/ui/theme/app_colors.dart';

class AverageCheckSection extends StatelessWidget {
  final String priceRange; // «10–20 $»

  const AverageCheckSection({Key? key, required this.priceRange}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('Средний чек:', style: AppTextStyles.body16Grey),
          const SizedBox(width: 4),
          Text(priceRange, style: AppTextStyles.body16),
        ],
      ),
    );
  }
}
