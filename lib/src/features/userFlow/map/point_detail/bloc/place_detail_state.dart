import 'package:tap_map/src/features/userFlow/map/point_detail/data/models/place_detail.dart';

/// Возможные вкладки в детальной информации о точке
enum PlaceDetailTab {
  overview,
  photos,
  reviews,
  menu
}

abstract class PlaceDetailState {}

class PlaceDetailInitial extends PlaceDetailState {}

class PlaceDetailLoading extends PlaceDetailState {}

class PlaceDetailLoaded extends PlaceDetailState {
  final PlaceDetail detail;
  final PlaceDetailTab selectedTab;

  PlaceDetailLoaded(this.detail, {this.selectedTab = PlaceDetailTab.overview});
  
  /// Создает копию состояния с новой выбранной вкладкой
  PlaceDetailLoaded copyWith({PlaceDetailTab? selectedTab}) {
    return PlaceDetailLoaded(
      detail,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}

class PlaceDetailError extends PlaceDetailState {
  final String message;

  PlaceDetailError(this.message);
}
