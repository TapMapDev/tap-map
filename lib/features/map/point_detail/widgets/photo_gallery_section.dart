// Сетка фото + кнопка "Добавить фото"
import 'package:flutter/material.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';
import 'package:tap_map/ui/theme/app_colors.dart';

class PhotoGallerySection extends StatelessWidget {
  final List<String> imageUrls;
  final VoidCallback? onAddPhoto;
  final bool showFullGallery;

  const PhotoGallerySection({
    Key? key,
    required this.imageUrls,
    this.onAddPhoto,
    this.showFullGallery = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showFullGallery) ...[
            Text('Фотографии (${imageUrls.length})', style: AppTextStyles.h18),
            const SizedBox(height: 16),
            _buildFullGallery(),
          ] else ...[
            _buildPreviewGallery(),
          ],
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

  Widget _buildPreviewGallery() {
    final display = imageUrls.take(4).toList();
    
    return SizedBox(
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
    );
  }

  Widget _buildFullGallery() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, i) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(imageUrls[i], fit: BoxFit.cover),
      ),
    );
  }
}
