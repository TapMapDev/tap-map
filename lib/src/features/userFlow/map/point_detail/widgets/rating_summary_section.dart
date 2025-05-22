// Большой рейтинг + "Оцени и напиши отзыв"
import 'package:flutter/material.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';
import 'package:tap_map/ui/theme/app_colors.dart';

class RatingSummarySection extends StatelessWidget {
  final double rating;          // 4.5
  final int totalReviews;       // 1200
  final VoidCallback? onRateTap;

  const RatingSummarySection({
    Key? key,
    required this.rating,
    required this.totalReviews,
    this.onRateTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary20, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(rating.toStringAsFixed(1), style: AppTextStyles.ratingBig),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stars(),
                  Text('$totalReviews оценок', style: AppTextStyles.body16Grey),
                ],
              ),
            ],
          ),
          const Divider(height: 32, color: AppColors.primary20),
          GestureDetector(
            onTap: onRateTap,
            child: Column(
              children: [
                Text('Оцени и напиши отзыв', textAlign: TextAlign.center, style: AppTextStyles.body16Grey),
                const SizedBox(height: 12),
                _stars(interactive: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stars({bool interactive = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 1;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          color: filled ? Colors.amber : AppColors.grey30,
          size: 20,
        );
      }),
    );
  }
}
