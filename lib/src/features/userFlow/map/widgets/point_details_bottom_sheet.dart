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
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  
                  // ─── основная информация (всегда видна) ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        HeaderSection(title: d.name, category: d.category),
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
                        if (selectedTab == PointDetailTab.overview) ...[
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
                        ] else if (selectedTab == PointDetailTab.photos) ...[
                          // Вкладка Фото показывает полную галерею
                          PhotoGallerySection(
                            imageUrls: d.imageUrls,
                            onAddPhoto: () {}, // TODO: callback
                            showFullGallery: true,
                          ),
                        ] else if (selectedTab == PointDetailTab.reviews) ...[
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
                        ] else if (selectedTab == PointDetailTab.menu) ...[
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
                        ],
                        
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
}
