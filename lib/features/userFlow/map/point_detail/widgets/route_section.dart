// Плитка "Маршрут"
import 'package:flutter/material.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';
import 'package:tap_map/ui/theme/app_colors.dart';

class RouteSection extends StatelessWidget {
  final String address;
  final VoidCallback? onRouteTap;

  const RouteSection({
    Key? key,
    required this.address,
    this.onRouteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onRouteTap,
      child: _tile(
        leading: const Text('📍', style: TextStyle(fontSize: 18)),
        title: address,
        subtitle: 'Маршрут',
        subtitleStyle: AppTextStyles.caption14Primary,
      ),
    );
  }

  Widget _tile(
      {required Widget leading,
        required String title,
        String? subtitle,
        TextStyle? subtitleStyle}) {
    return Container(
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
                Text(
                  title, 
                  style: AppTextStyles.body16,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(subtitle, style: subtitleStyle ?? AppTextStyles.caption14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
