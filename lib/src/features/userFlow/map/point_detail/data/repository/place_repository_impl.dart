import 'package:tap_map/core/network/api_service.dart';
import '../models/place_detail.dart';
import 'place_repository.dart';

class PlaceRepositoryImpl implements PlaceRepository {
  final ApiService apiService;

  PlaceRepositoryImpl({required this.apiService});

  @override
  Future<PlaceDetail> fetchPlaceDetail(String id) async {
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
    print(data);
    return PlaceDetail.fromJson(data);
  }
}
