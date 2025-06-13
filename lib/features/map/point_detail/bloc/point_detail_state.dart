import 'package:tap_map/features/map/point_detail/data/models/point_detail.dart';

/// Перечисление для вкладок в детальной информации о точке
enum PointDetailTab {
  overview,  // Обзор
  photos,    // Фото
  reviews,   // Отзывы
  menu,      // Меню
  features   // Особенности
}

abstract class PointDetailState {}

class PointDetailInitial extends PointDetailState {}

class PointDetailLoading extends PointDetailState {}

class PointDetailLoaded extends PointDetailState {
  final PointDetail detail;
  final PointDetailTab selectedTab;

  PointDetailLoaded(this.detail, {this.selectedTab = PointDetailTab.overview});
  
  /// Создаёт копию состояния с новым значением selectedTab
  PointDetailLoaded copyWith({PointDetailTab? selectedTab}) {
    return PointDetailLoaded(
      detail,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}

class PointDetailError extends PointDetailState {
  final String message;

  PointDetailError(this.message);
}
