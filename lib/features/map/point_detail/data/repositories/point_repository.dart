import '../models/point_detail.dart';

// TODO(tapmap): Упростить PointRepository, убрать абстракцию и оставить
// единственный класс с реализацией.

abstract class PointRepository {
  Future<PointDetail> fetchPointDetail(String id);
}
