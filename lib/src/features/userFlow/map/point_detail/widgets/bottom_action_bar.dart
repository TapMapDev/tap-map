// Нижняя панель с "Маршрут" и иконками
import 'package:flutter/material.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';
import 'package:tap_map/ui/theme/app_colors.dart';

class BottomActionBar extends StatelessWidget {
  final VoidCallback onRoute;
  final VoidCallback? onCall;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;

  const BottomActionBar({
    Key? key,
    required this.onRoute,
    this.onCall,
    this.onShare,
    this.onBookmark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0x1E767680)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Row(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.directions),
            label: const Text('Маршрут', style: AppTextStyles.body16),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenLight,
              foregroundColor: AppColors.green,
              shape: const StadiumBorder(),
            ),
            onPressed: onRoute,
          ),
          const Spacer(),
          _circle(onCall, Icons.phone),
          const SizedBox(width: 8),
          _circle(onShare, Icons.share),
          const SizedBox(width: 8),
          _circle(onBookmark, Icons.bookmark_border),
        ],
      ),
    );
  }

  Widget _circle(VoidCallback? tap, IconData icon) {
    return GestureDetector(
      onTap: tap,
      child: CircleAvatar(
        radius: 21,
        backgroundColor: AppColors.primary20,
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}
