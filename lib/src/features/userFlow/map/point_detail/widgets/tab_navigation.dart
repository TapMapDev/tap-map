// Таббар "Обзор / Фото / Отзывы..."
import 'package:flutter/material.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';
import 'package:tap_map/ui/theme/app_colors.dart';

class DetailTabNavigation extends StatelessWidget {
  final TabController controller;
  final int photoCount;
  final int reviewCount;

  const DetailTabNavigation({
    Key? key,
    required this.controller,
    required this.photoCount,
    required this.reviewCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 37,
      child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip('Обзор', 0),
                _chipWithBadge('Фото', 1, photoCount),
                _chipWithBadge('Отзывы', 2, reviewCount),
                _chip('Меню', 3),
                _chip('Особенности', 4),
              ],
            );
          },
      ),
    );
  }

  Widget _chip(String text, int index) {
    final selected = controller.index == index;
    return GestureDetector(
      onTap: () => controller.animateTo(index),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenLight : null,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          text,
          style: selected
              ? AppTextStyles.body16.copyWith(color: AppColors.green)
              : AppTextStyles.body16Grey,
        ),
      ),
    );
  }

  Widget _chipWithBadge(String text, int index, int count) {
    final selected = controller.index == index;
    return GestureDetector(
      onTap: () => controller.animateTo(index),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenLight : null,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: selected
                  ? AppTextStyles.body16.copyWith(color: AppColors.green)
                  : AppTextStyles.body16Grey,
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.badge12Green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
