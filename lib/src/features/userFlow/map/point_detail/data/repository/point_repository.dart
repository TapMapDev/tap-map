import '../models/place_detail.dart';

abstract class PointRepository {
  Future<PlaceDetail> fetchPlaceDetail(String id);
}
