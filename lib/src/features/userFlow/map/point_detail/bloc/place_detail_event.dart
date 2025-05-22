abstract class PlaceDetailEvent {}

class FetchPlaceDetail extends PlaceDetailEvent {
  final String placeId;

  FetchPlaceDetail(this.placeId);
}
