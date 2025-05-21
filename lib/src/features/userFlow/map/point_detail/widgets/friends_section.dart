// Компонент "Были друзья" с аватарками
import 'package:flutter/material.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';
import 'package:tap_map/ui/theme/app_colors.dart';

class FriendsSection extends StatelessWidget {
  final int totalFriends;           // сколько всего друзей были
  final List<ImageProvider> avatars; // первые 4 аватарки
  final VoidCallback? onMoreTap;

  const FriendsSection({
    Key? key,
    required this.totalFriends,
    required this.avatars,
    this.onMoreTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final moreCount = totalFriends - avatars.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary20, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Текст слева
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Были друзья:', style: AppTextStyles.h18),
                const SizedBox(height: 4),
                Text('$totalFriends друзей',
                    style: AppTextStyles.caption14),
              ],
            ),
          ),
          // Аватарки
          ...avatars.take(4).map((img) => Padding(
            padding: const EdgeInsets.only(left: 4),
            child: CircleAvatar(radius: 23, backgroundImage: img),
          )),
          // Кнопка «ещё»
          if (moreCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: onMoreTap,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.primary20),
                    borderRadius: BorderRadius.circular(43),
                  ),
                  alignment: Alignment.center,
                  child: Text('$moreCount +',
                      style: AppTextStyles.caption14Primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
