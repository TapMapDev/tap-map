import '../models/place_detail.dart';

abstract class PlaceRepository {
  Future<PlaceDetail> fetchPlaceDetail(String id);
}
