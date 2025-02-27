import 'package:dio/dio.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.tap-map.net/api',
        connectTimeout: const Duration(milliseconds: 5000),
        receiveTimeout: const Duration(milliseconds: 3000),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // ✅ Интерцептор обработки 401 и обновления токенов
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        if (error.response?.statusCode == 401) {
          final apiService = getIt.get<ApiService>();
          final prefs = getIt.get<SharedPrefsRepository>();

          // ⏳ Попытка обновления токена
          try {
            await apiService.refreshTokens();
            final newAccessToken = await prefs.getAccessToken();

            if (newAccessToken == null) {
              return handler.next(error);
            }

            // 🔄 Повтор запроса с новым токеном
            error.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            final response = await _dio.request(
              error.requestOptions.path,
              options: Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              ),
              data: error.requestOptions.data,
              queryParameters: error.requestOptions.queryParameters,
            );

            return handler.resolve(response);
          } catch (e) {
            return handler
                .next(error); // Продолжаем ошибку 401, если токен не обновился
          }
        }

        return handler.next(error);
      },
    ));
  }

  Dio get client => _dio;
}
