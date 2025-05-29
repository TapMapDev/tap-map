import 'package:tap_map/core/network/api_service.dart';
import '../models/point_detail.dart';
import 'point_repository.dart';

class PointRepositoryImpl implements PointRepository {
  final ApiService apiService;

  PointRepositoryImpl({required this.apiService});

  @override
  Future<PointDetail> fetchPointDetail(String id) async {
    final response = await apiService.getData(
      '/points/$id/',
      // при необходимости queryParams: { ... }
    );

    if (response['statusCode'] != 200) {
      throw Exception(
        'Failed to load place detail: ${response['statusMessage']}',
      );
    }

    final data = response['data'] as Map<String, dynamic>;
    return PointDetail.fromJson(data);
  }
}
