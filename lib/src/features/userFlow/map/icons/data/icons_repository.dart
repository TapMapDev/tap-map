import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/src/features/userFlow/map/icons/model/icons_response_modal.dart';

// TODO(tapmap): Перейти на единый стиль репозиториев без интерфейса IconsRepository.

abstract class IconsRepository {
  Future<List<IconsResponseModel>> fetchIcons(int styleId);
}

class IconsRepositoryImpl implements IconsRepository {
  final ApiService apiService;

  IconsRepositoryImpl({required this.apiService});

  @override
  Future<List<IconsResponseModel>> fetchIcons(int styleId) async {
    final response = await apiService.getData('/styles/$styleId/icons/');

    if (response.containsKey('statusCode') && response['statusCode'] == 200) {
      final List<dynamic> data = response['data'] ?? [];

      if (data.isEmpty) {
      }

      final icons =
          data.map((item) => IconsResponseModel.fromJson(item)).toList();
      return icons;
    } else if (response['statusCode'] == 401) {
      throw Exception('Ошибка 401: Доступ запрещен. Проверь API-токен.');
    } else {
      throw Exception(
          'Ошибка загрузки иконок: ${response['statusCode'] ?? 'Неизвестный статус'}');   
    }
  }
}
