// Компонент заголовка детальной информации о точке
// Содержит название места, тип/категорию и кнопку share

import 'package:flutter/material.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';
import 'package:tap_map/ui/theme/app_colors.dart';

/// Заголовок карточки места:
///  • название заведения
///  • категория («Кофейня»)
///  • кнопка share (опционально)
class HeaderSection extends StatelessWidget {
  final String title;
  final String category;
  final VoidCallback? onShare;

  const HeaderSection({
    Key? key,
    required this.title,
    required this.category,
    this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Название + категория
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.h24),
              const SizedBox(height: 4),
              Text(category, style: AppTextStyles.body16Grey),
            ],
          ),
        ),
        // Кнопка share
        if (onShare != null)
          IconButton(
            onPressed: onShare,
            style: ButtonStyle(
              backgroundColor:
              MaterialStateProperty.all(AppColors.primary20),
              shape: MaterialStateProperty.all(const CircleBorder()),
            ),
            icon: const Icon(Icons.share, size: 20, color: AppColors.primary),
          ),
      ],
    );
  }
}
