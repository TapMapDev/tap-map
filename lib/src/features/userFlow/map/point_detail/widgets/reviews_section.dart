// Список отзывов + "Смотреть все"
import 'package:flutter/material.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';
import 'package:tap_map/ui/theme/app_colors.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/data/models/point_review_model.dart';

class ReviewsSection extends StatelessWidget {
  final List<PointReviewModel> reviews;
  final int totalCount;
  final VoidCallback? onSeeAll;
  final bool showFullReviews;

  const ReviewsSection({
    Key? key,
    required this.reviews,
    required this.totalCount,
    this.onSeeAll,
    this.showFullReviews = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayReviews = showFullReviews ? reviews : reviews.take(2).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            showFullReviews 
                ? 'Отзывы ($totalCount)' 
                : 'Что говорят о месте:', 
            style: AppTextStyles.h18
          ),
          const SizedBox(height: 12),
          
          if (reviews.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Text(
                'Отзывов пока нет. Будьте первым!',
                style: AppTextStyles.body16Grey,
              ),
            )
          else
            ...displayReviews.map(_card),
            
          if (!showFullReviews && reviews.length > 2) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary20,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('Смотреть все $totalCount',
                    style: AppTextStyles.body16.copyWith(color: AppColors.primary)),
              ),
            ),
          ] else if (showFullReviews) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {}, // TODO: добавить callback для написания отзыва
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary20,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('Написать отзыв',
                    style: AppTextStyles.body16.copyWith(color: AppColors.primary)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card(PointReviewModel r) {
    return Column(
      children: [
        Row(
          children: [
            // Заглушка-аватар
            const CircleAvatar(radius: 21, backgroundColor: AppColors.primary20),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.author, style: AppTextStyles.body16),
                  Text(_formatDate(r.date), style: AppTextStyles.caption14),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary20,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Text('${r.rating}',
                      style: AppTextStyles.caption14Dark),
                  const SizedBox(width: 4),
                  Text(r.label, style: AppTextStyles.caption14Dark),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(r.text, style: AppTextStyles.body16),
        const SizedBox(height: 8),
        Row(
          children: [
            _reaction(Icons.thumb_up, r.likes, positive: true),
            const SizedBox(width: 12),
            _reaction(Icons.thumb_down, r.dislikes),
          ],
        ),
        const Divider(height: 24, color: AppColors.primary20),
      ],
    );
  }

  Widget _reaction(IconData icon, int count, {bool positive = false}) {
    final color = positive ? AppColors.primary : AppColors.grey;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text('$count',
            style: AppTextStyles.caption14.copyWith(color: color)),
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${_monthRu[d.month]} ${d.year} г';

  static const _monthRu = [
    '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
  ];
}
