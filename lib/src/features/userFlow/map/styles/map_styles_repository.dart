import 'package:tap_map/core/network/api_service.dart';
import 'map_styles_responce_modal.dart';

abstract class MapStyleRepository {
  Future<List<MapStyleResponceModel>> fetchMapStyles();
  List<MapStyleResponceModel> getCachedMapStyles(); // ✅ Добавили метод
}

class MapStyleRepositoryImpl implements MapStyleRepository {
  final ApiService apiService;
  List<MapStyleResponceModel>? _cachedStyles; // ✅ Кешированные стили

  MapStyleRepositoryImpl({required this.apiService});

  @override
  Future<List<MapStyleResponceModel>> fetchMapStyles() async {
    final response = await apiService.getData('/styles');
    if (response['statusCode'] == 200) {
      final List<dynamic> data = response['data'];
      _cachedStyles = data.map((item) => MapStyleResponceModel.fromJson(item)).toList();
      return _cachedStyles!;
    } else {
      throw Exception('Failed to load map styles');
    }
  }

  @override
  List<MapStyleResponceModel> getCachedMapStyles() {
    return _cachedStyles ?? []; // ✅ Возвращаем кэшированные стили
  }
}