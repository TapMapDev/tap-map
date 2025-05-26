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
    final display = showFullGallery ? imageUrls : imageUrls.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary20, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showFullGallery && imageUrls.isNotEmpty) 
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Фотографии (${imageUrls.length})', 
                style: AppTextStyles.h18,
              ),
            ),
          
          if (imageUrls.isEmpty)
            Container(
              height: 163,
              alignment: Alignment.center,
              child: Text(
                'Фотографии отсутствуют',
                style: AppTextStyles.body16Grey,
              ),
            )
          else if (showFullGallery)
            _buildFullGalleryGrid(display)
          else
            _buildPreviewGallery(display),
            
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
  
  /// Строит компактную горизонтальную галерею для предпросмотра
  Widget _buildPreviewGallery(List<String> photos) {
    return SizedBox(
      height: 163,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(photos[i], width: 178, height: 163, fit: BoxFit.cover),
        ),
      ),
    );
  }
  
  /// Строит полную галерею с сеткой фотографий
  Widget _buildFullGalleryGrid(List<String> photos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            photos[index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
