import '../models/point_detail.dart';

abstract class PointRepository {
  Future<PointDetail> fetchPointDetail(String id);
}
