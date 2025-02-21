import 'package:tap_map/core/network/api_service.dart';
import 'map_styles_responce_modal.dart';

abstract class MapStyleRepository {
  Future<List<MapStyleResponceModel>> fetchMapStyles();
}

class MapStyleRepositoryImpl implements MapStyleRepository {
  final ApiService apiService;
  MapStyleRepositoryImpl({required this.apiService});

  Future<List<MapStyleResponceModel>> fetchMapStyles() async {
    final response = await apiService.getData('/styles');
    if (response['statusCode'] == 200) {
      final List<dynamic> data = response['data'];
      return data.map((item) => MapStyleResponceModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load map styles');
    }
  }
}
