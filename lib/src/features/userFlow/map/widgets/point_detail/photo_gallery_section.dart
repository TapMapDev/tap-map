// Сетка фото + кнопка "Добавить фото"
import 'package:flutter/material.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';
import 'package:tap_map/ui/theme/app_colors.dart';

class PhotoGallerySection extends StatelessWidget {
  final List<String> imageUrls;
  final VoidCallback? onAddPhoto;

  const PhotoGallerySection({
    Key? key,
    required this.imageUrls,
    this.onAddPhoto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final display = imageUrls.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary20, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 163,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: display.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(display[i], width: 178, height: 163, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onAddPhoto,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary20,
                borderRadius: BorderRadius.circular(100),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Добавить фото', style: AppTextStyles.body16.copyWith(color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }
}
