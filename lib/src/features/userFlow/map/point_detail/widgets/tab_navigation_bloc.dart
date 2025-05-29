import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/bloc/point_detail_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/bloc/point_detail_event.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/bloc/point_detail_state.dart';
import 'package:tap_map/ui/theme/app_text_styles.dart';
import 'package:tap_map/ui/theme/app_colors.dart';

/// Компонент навигации между вкладками для детальной информации о точке,
/// интегрированный с BLoC для управления состоянием.
class TabNavigationBloc extends StatefulWidget {
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
  State<TabNavigationBloc> createState() => _TabNavigationBlocState();
}

class _TabNavigationBlocState extends State<TabNavigationBloc> {
  // Контроллер для анимации прокрутки к выбранному табу
  final ScrollController _scrollController = ScrollController();
  
  // Map для хранения глобальных ключей для каждого таба
  final Map<PointDetailTab, GlobalKey> _tabKeys = {
    PointDetailTab.overview: GlobalKey(),
    PointDetailTab.photos: GlobalKey(),
    PointDetailTab.reviews: GlobalKey(),
    PointDetailTab.menu: GlobalKey(),
    PointDetailTab.features: GlobalKey(),
  };
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Прокрутка к выбранному табу с анимацией
  void _scrollToSelectedTab(PointDetailTab selectedTab) {
    final key = _tabKeys[selectedTab];
    if (key?.currentContext != null) {
      final RenderBox box = key!.currentContext!.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      
      // Вычисляем позицию для центрирования таба
      final centerPosition = position.dx - MediaQuery.of(context).size.width / 2 + box.size.width / 2;
      
      // Анимированная прокрутка к табу
      _scrollController.animateTo(
        centerPosition.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PointDetailBloc, PointDetailState>(
      listenWhen: (previous, current) {
        // Слушаем только изменения выбранного таба
        if (previous is PointDetailLoaded && current is PointDetailLoaded) {
          return previous.selectedTab != current.selectedTab;
        }
        return false;
      },
      listener: (context, state) {
        if (state is PointDetailLoaded) {
          // Прокручиваем к выбранному табу при его изменении
          _scrollToSelectedTab(state.selectedTab);
        }
      },
      builder: (context, state) {
        if (state is! PointDetailLoaded) return const SizedBox.shrink();

        return Container(
          height: 45,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildTab(
                context: context,
                key: _tabKeys[PointDetailTab.overview]!,
                text: 'Обзор', 
                tab: PointDetailTab.overview, 
                selected: state.selectedTab == PointDetailTab.overview,
              ),
              _buildTabWithBadge(
                context: context,
                key: _tabKeys[PointDetailTab.photos]!,
                text: 'Фото', 
                tab: PointDetailTab.photos, 
                count: widget.photoCount, 
                selected: state.selectedTab == PointDetailTab.photos,
              ),
              _buildTabWithBadge(
                context: context,
                key: _tabKeys[PointDetailTab.reviews]!,
                text: 'Отзывы', 
                tab: PointDetailTab.reviews, 
                count: widget.reviewCount, 
                selected: state.selectedTab == PointDetailTab.reviews,
              ),
              _buildTab(
                context: context,
                key: _tabKeys[PointDetailTab.menu]!,
                text: 'Меню', 
                tab: PointDetailTab.menu, 
                selected: state.selectedTab == PointDetailTab.menu,
              ),
              _buildTab(
                context: context,
                key: _tabKeys[PointDetailTab.features]!,
                text: 'Особенности', 
                tab: PointDetailTab.features, 
                selected: state.selectedTab == PointDetailTab.features,
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
    required GlobalKey key,
    required String text,
    required PointDetailTab tab,
    required bool selected,
  }) {
    return AnimatedContainer(
      key: key,
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.tabBgActive : Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        boxShadow: selected ? [
          BoxShadow(
            color: AppColors.green.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ] : null,
      ),
      child: GestureDetector(
        onTap: () => _onTabTap(context, tab),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
            color: selected ? AppColors.tabTextActive : AppColors.tabTextInactive,
            height: 1.25,
          ),
          child: Text(text),
        ),
      ),
    );
  }

  /// Создает вкладку с бэйджем, показывающим количество
  Widget _buildTabWithBadge({
    required BuildContext context,
    required GlobalKey key,
    required String text,
    required PointDetailTab tab,
    required int count,
    required bool selected,
  }) {
    return AnimatedContainer(
      key: key,
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.tabBgActive : Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        boxShadow: selected ? [
          BoxShadow(
            color: AppColors.green.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ] : null,
      ),
      child: GestureDetector(
        onTap: () => _onTabTap(context, tab),
        child: Row(
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                color: selected ? AppColors.tabTextActive : AppColors.tabTextInactive,
                height: 1.25,
              ),
              child: Text(text),
            ),
            const SizedBox(width: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected 
                    ? AppColors.tabBadgeBg
                    : AppColors.tabBgActive,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.43,
                  color: selected 
                      ? AppColors.tabBadgeText
                      : AppColors.tabTextActive,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Обрабатывает нажатие на вкладку
  void _onTabTap(BuildContext context, PointDetailTab tab) {
    context.read<PointDetailBloc>().add(SwitchPointDetailTab(tab));
  }
}
