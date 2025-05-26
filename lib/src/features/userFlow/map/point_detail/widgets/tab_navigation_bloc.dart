import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/bloc/place_detail_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/bloc/place_detail_event.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/bloc/place_detail_state.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';
import 'package:tap_map/ui/theme/app_colors.dart';

/// Компонент навигации между вкладками для детальной информации о точке,
/// интегрированный с BLoC для управления состоянием.
class TabNavigationBloc extends StatelessWidget {
  /// Количество фотографий для отображения в бэйдже
  final int photoCount;

  /// Количество отзывов для отображения в бэйдже
  final int reviewCount;

  const TabNavigationBloc({
    Key? key,
    required this.photoCount,
    required this.reviewCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaceDetailBloc, PlaceDetailState>(
      builder: (context, state) {
        if (state is! PlaceDetailLoaded) return const SizedBox.shrink();
        
        return Container(
          height: 37,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildTab(
                context: context, 
                text: 'Обзор', 
                tab: PlaceDetailTab.overview, 
                selected: state.selectedTab == PlaceDetailTab.overview,
              ),
              _buildTabWithBadge(
                context: context, 
                text: 'Фото', 
                tab: PlaceDetailTab.photos, 
                count: photoCount, 
                selected: state.selectedTab == PlaceDetailTab.photos,
              ),
              _buildTabWithBadge(
                context: context, 
                text: 'Отзывы', 
                tab: PlaceDetailTab.reviews, 
                count: reviewCount, 
                selected: state.selectedTab == PlaceDetailTab.reviews,
              ),
              _buildTab(
                context: context, 
                text: 'Меню', 
                tab: PlaceDetailTab.menu, 
                selected: state.selectedTab == PlaceDetailTab.menu,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Создает простую вкладку без бэйджа
  Widget _buildTab({
    required BuildContext context,
    required String text,
    required PlaceDetailTab tab,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () => _onTabTap(context, tab),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLightest : null,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          text,
          style: selected
              ? AppTextStyles.body16.copyWith(color: AppColors.primary)
              : AppTextStyles.body16Grey,
        ),
      ),
    );
  }

  /// Создает вкладку с бэйджем, показывающим количество
  Widget _buildTabWithBadge({
    required BuildContext context,
    required String text,
    required PlaceDetailTab tab,
    required int count,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () => _onTabTap(context, tab),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLightest : null,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: selected
                  ? AppTextStyles.body16.copyWith(color: AppColors.primary)
                  : AppTextStyles.body16Grey,
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLightest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.badge12Primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Обрабатывает нажатие на вкладку
  void _onTabTap(BuildContext context, PlaceDetailTab tab) {
    context.read<PlaceDetailBloc>().add(SwitchPlaceDetailTab(tab));
  }
}
