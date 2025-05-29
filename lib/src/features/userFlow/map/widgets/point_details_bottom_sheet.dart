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
import 'package:tap_map/ui/theme/app_colors.dart';

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
            snap: true,
            snapSizes: const [0.60, 0.95],
            builder: (_, scrollController) => Stack(
              clipBehavior: Clip.none,
              children: [
                // Основной контейнер
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 10),
                    ],
                  ),
                  // Используем ListView вместо Column для правильного скроллинга
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            
                            // ─── навигация по табам ─── (перенесено сюда согласно дизайну)
                            TabNavigationBloc(
                              photoCount: d.imageUrls.length,
                              reviewCount: d.totalReviews,
                            ),
                          ],
                        ),
                      ),
                      
                      // Контент в зависимости от выбранной вкладки
                      Container(
                        color: AppColors.contentBg,
                        padding: const EdgeInsets.only(top: 16, bottom: 24),
                        child: _buildTabContent(d, selectedTab, context),
                      ),
                      
                      // Кнопки внизу (всегда видны)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            BottomActionBar(
                              onRoute: () {}, // TODO: callback
                              onCall: () {},  // TODO: callback
                              onShare: () {}, // TODO: callback
                            ),
                          ],
                        ),
                      ),
                      
                      // Добавляем отступ внизу, чтобы контент был полностью виден
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
                
                // Кнопка закрытия
                Positioned(
                  right: 16,
                  top: 16,
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
          );
        },
      ),
    );
  }
  
  /// Возвращает содержимое в зависимости от выбранной вкладки
  Widget _buildTabContent(PointDetail d, PointDetailTab selectedTab, BuildContext context) {
    switch (selectedTab) {
      case PointDetailTab.overview:
        // Вкладка Обзор
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок секции
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text('Обзор', style: AppTextStyles.h18),
              ),
              
              // Блок с друзьями
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: FriendsSection(
                  totalFriends: d.friendsCount,
                  avatarUrls: d.friendAvatars,
                ),
              ),
              
              // Блок с Избранным, адресом и временем работы
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    FavoriteSection(
                      isFavorite: false,
                      listName: 'Кофейни',
                      onToggle: () {}, // TODO: callback
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF0F3F5)),
                    const SizedBox(height: 16),
                    RouteSection(
                      address: d.address,
                      onRouteTap: () {}, // TODO: callback
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF0F3F5)),
                    const SizedBox(height: 16),
                    OpenStatusSection(
                      statusText: 'Откроется через 35 минут',
                    ),
                  ],
                ),
              ),
              
              // Блок особенностей
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: FeaturesSection(
                  features: d.features.map((f) => f.title).toList(),
                  onMoreTap: () => context.read<PointDetailBloc>().add(
                    SwitchPointDetailTab(PointDetailTab.features)),
                ),
              ),
              
              // Блок контактов
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ContactsSection(
                  phone: d.phone ?? '+7 (999) 123-45-67',
                  website: d.website ?? 'example.com',
                  socialButtons: {
                    'telegram': () {}, 
                    'instagram': () {},
                    'vk': () {},
                  },
                ),
              ),
              
              // Блок с фотографиями
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: PhotoGallerySection(
                  imageUrls: d.imageUrls,
                  onAddPhoto: () {}, // TODO: callback
                ),
              ),
              
              // Блок с рейтингом
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: RatingSummarySection(
                  rating: d.rating,
                  totalReviews: d.totalReviews,
                  onRateTap: () {}, // TODO: callback
                ),
              ),
              
              // Блок с отзывами
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ReviewsSection(
                  reviews: d.reviews,
                  totalCount: d.totalReviews,
                  onSeeAll: () => context.read<PointDetailBloc>().add(
                    SwitchPointDetailTab(PointDetailTab.reviews)),
                ),
              ),
            ],
          ),
        );
        
      case PointDetailTab.reviews:
        // Вкладка отзывов
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок секции
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text('Отзывы', style: AppTextStyles.h18),
              ),
              
              // Основное содержимое в карточке
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ReviewsSection(
                  reviews: d.reviews,
                  totalCount: d.totalReviews,
                  showFullReviews: true,
                ),
              ),
            ],
          ),
        );
        
      case PointDetailTab.features:
        // Вкладка с полным списком особенностей
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок секции
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text('Все особенности', style: AppTextStyles.h18),
              ),
              
              // Полный список особенностей с более красивой разметкой
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: d.features.map((feature) => _buildFeatureChip(feature.title)).toList(),
                ),
              ),
            ],
          ),
        );
        
      case PointDetailTab.menu:
        // Вкладка Меню
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок секции
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text('Меню', style: AppTextStyles.h18),
              ),
              
              // Содержимое в карточке
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: FeaturesSection(
                  features: d.features.map((f) => f.title).toList(),
                ),
              ),
            ],
          ),
        );
        
      case PointDetailTab.photos:
        // Вкладка с фотографиями
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок секции
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text('Фотографии', style: AppTextStyles.h18),
              ),
              
              // Содержимое в карточке
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: PhotoGallerySection(
                  imageUrls: d.imageUrls,
                  onAddPhoto: () {}, // TODO: callback
                  showFullGallery: true,
                ),
              ),
            ],
          ),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildFeatureChip(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLightest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(title, style: AppTextStyles.caption14Dark),
    );
  }
}
