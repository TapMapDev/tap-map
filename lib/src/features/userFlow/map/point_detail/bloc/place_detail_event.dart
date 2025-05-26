abstract class PlaceDetailEvent {}

class FetchPlaceDetail extends PlaceDetailEvent {
  final String placeId;

  FetchPlaceDetail(this.placeId);
}

/// Событие для переключения между вкладками в детальной информации о точке
class SwitchPlaceDetailTab extends PlaceDetailEvent {
  final PlaceDetailTab tab;

  SwitchPlaceDetailTab(this.tab);
}
