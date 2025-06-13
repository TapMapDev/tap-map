// Плитка "Избранное"
import 'package:flutter/material.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';
import 'package:tap_map/ui/theme/app_colors.dart';

class FavoriteSection extends StatelessWidget {
  final bool isFavorite;
  final String listName;         // например «Кофейни»
  final VoidCallback? onToggle;

  const FavoriteSection({
    Key? key,
    required this.isFavorite,
    required this.listName,
    this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: _tile(
        leading: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: AppColors.primary,
        ),
        title: 'Избранное',
        subtitle: 'В списке $listName',
      ),
    );
  }

  Widget _tile(
      {required Widget leading,
        required String title,
        String? subtitle}) =>
      Container(
        height: 66,
        padding: const EdgeInsets.only(left: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.primary20),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primary20,
              child: leading,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body16),
                  if (subtitle != null)
                    Text(subtitle, style: AppTextStyles.caption14),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey),
          ],
        ),
      );
}
