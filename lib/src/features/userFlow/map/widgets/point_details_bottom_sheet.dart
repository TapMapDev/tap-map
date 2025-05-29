import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/bloc/point_detail_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/bloc/point_detail_state.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/bloc/point_detail_event.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/widgets/header_section.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/widgets/friends_section.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/widgets/favorite_section.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/widgets/route_section.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/widgets/open_status_section.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/widgets/features_section.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/widgets/contacts_section.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/widgets/photo_gallery_section.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/widgets/rating_summary_section.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/widgets/reviews_section.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/widgets/bottom_action_bar.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/widgets/tab_navigation_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/data/models/point_detail.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';

/// Bottom-sheet с полной информацией о выбранной точке на карте.
/// Данные подтягиваются из [PointDetailBloc].
class PointDetailsBottomSheet extends StatefulWidget {
  const PointDetailsBottomSheet({Key? key}) : super(key: key);

  @override
  State<PointDetailsBottomSheet> createState() => _PointDetailsBottomSheetState();
}

class _PointDetailsBottomSheetState extends State<PointDetailsBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: BlocBuilder<PointDetailBloc, PointDetailState>(
        builder: (context, state) {
          // ───── loading / error ─────
          if (state is PointDetailLoading) {
            return const SizedBox(
              height: 250,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is PointDetailError) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Text(
                state.message,
                style: AppTextStyles.body16,
              ),
            );
          }
          if (state is! PointDetailLoaded) return const SizedBox.shrink();

          final d = state.detail;
          final selectedTab = state.selectedTab;

          // ───── основной контент ─────
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.60,
            minChildSize: 0.40,
            maxChildSize: 0.95,
            builder: (_, scroll) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  // ─── drag-indicator ───
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      // Кнопка закрытия
                      Positioned(
                        right: 16,
                        top: 8,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // ─── основная информация (всегда видна) ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        HeaderSection(title: d.name, category: d.category),
                        const SizedBox(height: 8),
                
                        // ─── Рейтинг и расстояние ───
                        Row(
                          children: [
                            // Звездочка и рейтинг
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  d.rating.toStringAsFixed(1),
                                  style: AppTextStyles.caption14Dark,
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            // Кол-во оценок
                            Text(
                              '${d.totalReviews} оценок',
                              style: AppTextStyles.caption14,
                            ),
                            const SizedBox(width: 8),
                            // Разделитель
                            Container(
                              height: 4,
                              width: 4,
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Расстояние
                            Row(
                              children: [
                                const Icon(Icons.place_outlined, color: Colors.grey, size: 16),
                                const SizedBox(width: 2),
                                Text(
                                  '340 м', // TODO: Получать расстояние из модели
                                  style: AppTextStyles.caption14,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                
                        FriendsSection(
                          totalFriends: d.friendsCount,
                          avatarUrls: d.friendAvatars,
                        ),
                        const SizedBox(height: 13),
                
                        // TODO d.isFavorite
                        FavoriteSection(isFavorite: false, listName: 'Кофейни'),
                        const SizedBox(height: 13),
                
                        RouteSection(address: d.address),
                        const SizedBox(height: 13),
                
                        // TODO d.openStatus
                        OpenStatusSection(statusText: 'Откроется через 35 минут'),
                        const SizedBox(height: 13),
                      ],
                    ),
                  ),
                  
                  // ─── навигация по табам ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TabNavigationBloc(
                      photoCount: d.imageUrls.length,
                      reviewCount: d.totalReviews,
                    ),
                  ),
                  
                  // ─── контент в зависимости от выбранного таба ───
                  Expanded(
                    child: ListView(
                      controller: scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Отображаем разный контент в зависимости от выбранного таба
                        ..._buildTabContent(d, selectedTab, context),
                        
                        const SizedBox(height: 24),
                        
                        // Кнопки внизу (всегда видны)
                        BottomActionBar(
                          onRoute: () {}, // TODO: callback
                          onCall: () {},  // TODO: callback
                          onShare: () {}, // TODO: callback
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// Возвращает содержимое в зависимости от выбранной вкладки
  List<Widget> _buildTabContent(PointDetail d, PointDetailTab selectedTab, BuildContext context) {
    switch (selectedTab) {
      case PointDetailTab.overview:
        return [
          // Обзор содержит все блоки с базовой информацией
          FeaturesSection(
            features: d.features.map((f) => f.title).toList(),
          ),
          const SizedBox(height: 13),

          ContactsSection(
            phone: d.phone,
            website: d.website,
          ),
          const SizedBox(height: 13),

          PhotoGallerySection(
            imageUrls: d.imageUrls,
            onAddPhoto: () {}, // TODO: callback
          ),
          const SizedBox(height: 13),

          RatingSummarySection(
            rating: d.rating,
            totalReviews: d.totalReviews,
            onRateTap: () {}, // TODO: callback
          ),
          const SizedBox(height: 13),

          ReviewsSection(
            reviews: d.reviews,
            totalCount: d.totalReviews,
            onSeeAll: () => context.read<PointDetailBloc>().add(
              SwitchPointDetailTab(PointDetailTab.reviews)),
          ),
        ];
        
      case PointDetailTab.photos:
        return [
          // Вкладка Фото показывает полную галерею
          PhotoGallerySection(
            imageUrls: d.imageUrls,
            onAddPhoto: () {}, // TODO: callback
            showFullGallery: true,
          ),
        ];
        
      case PointDetailTab.reviews:
        return [
          // Вкладка Отзывы показывает все отзывы и рейтинг
          RatingSummarySection(
            rating: d.rating,
            totalReviews: d.totalReviews,
            onRateTap: () {}, // TODO: callback
          ),
          const SizedBox(height: 13),
          
          ReviewsSection(
            reviews: d.reviews,
            totalCount: d.totalReviews,
            showFullReviews: true,
          ),
        ];
        
      case PointDetailTab.menu:
        return [
          // Вкладка Меню (пока заглушка)
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              'Меню этого заведения появится здесь в ближайшее время',
              style: AppTextStyles.body16Grey,
              textAlign: TextAlign.center,
            ),
          ),
        ];
        
      default:
        // Обработка на случай добавления новых вкладок в будущем
        return [
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Text(
              'Содержимое для этой вкладки находится в разработке',
              style: AppTextStyles.body16Grey,
              textAlign: TextAlign.center,
            ),
          ),
        ];
    }
  }
}
