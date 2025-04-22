import 'package:flutter/foundation.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/src/features/userFlow/map/icons/model/icons_response_modal.dart';

abstract class IconsRepository {
  Future<List<IconsResponseModel>> fetchIcons(int styleId);
}

class IconsRepositoryImpl implements IconsRepository {
  final ApiService apiService;

  IconsRepositoryImpl({required this.apiService});

  @override
  Future<List<IconsResponseModel>> fetchIcons(int styleId) async {
    debugPrint('🔄 Запрашиваем иконки для стиля $styleId');
    final response = await apiService.getData('/styles/$styleId/icons/');
    debugPrint('📦 Получен ответ от API: ${response.toString()}');

    if (response.containsKey('statusCode') && response['statusCode'] == 200) {
      final List<dynamic> data = response['data'] ?? [];
      debugPrint('📦 Количество иконок в ответе: ${data.length}');

      if (data.isEmpty) {
        debugPrint('⚠️ Получен пустой список иконок от API');
      }

      final icons =
          data.map((item) => IconsResponseModel.fromJson(item)).toList();
      debugPrint(
          '📦 Загруженные иконки: ${icons.map((e) => e.name).join(', ')}');
      return icons;
    } else if (response['statusCode'] == 401) {
      debugPrint('❌ Ошибка 401: Доступ запрещен. Проверь API-токен.');
      throw Exception('Ошибка 401: Доступ запрещен. Проверь API-токен.');
    } else {
      debugPrint(
          '❌ Ошибка загрузки иконок: ${response['statusCode'] ?? "Неизвестный статус"}');
      throw Exception(
          'Ошибка загрузки иконок: ${response['statusCode'] ?? "Неизвестный статус"}');
    }
  }
}
