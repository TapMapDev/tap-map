import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';

class DioClient {
  late final Dio _dio;
  bool _isRefreshing = false;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.tap-map.net/api',
        connectTimeout: const Duration(milliseconds: 5000),
        receiveTimeout: const Duration(milliseconds: 3000),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            print('🔄 Starting token refresh process...');
            try {
              final prefs = getIt.get<SharedPrefsRepository>();
              final refreshToken = await prefs.getRefreshToken();
              print(
                  '📝 Current refresh token: ${refreshToken?.substring(0, 10)}...');

              if (refreshToken != null) {
                // Создаем новый Dio для запроса обновления токена
                final tokenDio = Dio(BaseOptions(
                  baseUrl: 'https://api.tap-map.net/api',
                  headers: {'Content-Type': 'application/json'},
                ));

                try {
                  print('🔄 Sending refresh token request...');
                  final response = await tokenDio.post(
                    '/auth/jwt/refresh/',
                    data: {'refresh': refreshToken},
                  );

                  if (response.statusCode == 200) {
                    final newAccessToken = response.data['access'];
                    final newRefreshToken = response.data['refresh'];
                    print('✅ New tokens received');

                    // Сохраняем новые токены
                    await prefs.saveAccessToken(newAccessToken);
                    await prefs.saveRefreshToken(newRefreshToken);
                    print('💾 New tokens saved');

                    // Повторяем исходный запрос с новым токеном
                    error.requestOptions.headers['Authorization'] =
                        'Bearer $newAccessToken';
                    print('🔄 Retrying original request with new token...');
                    final clonedRequest = await _dio.request(
                      error.requestOptions.path,
                      options: Options(
                        method: error.requestOptions.method,
                        headers: error.requestOptions.headers,
                      ),
                      data: error.requestOptions.data,
                      queryParameters: error.requestOptions.queryParameters,
                    );

                    _isRefreshing = false;
                    print('✅ Token refresh completed successfully');
                    return handler.resolve(clonedRequest);
                  }
                } catch (refreshError) {
                  print('❌ Error refreshing token: $refreshError');
                  await prefs.deleteAccessToken();
                  await prefs.deleteRefreshToken();
                  print('🗑️ Tokens deleted due to refresh error');

                  // Перенаправляем на страницу авторизации
                  Navigator.of(getIt
                          .get<GlobalKey<NavigatorState>>()
                          .currentContext!)
                      .pushNamedAndRemoveUntil(
                          '/authorization', (route) => false);
                }
              } else {
                print('❌ No refresh token available');
              }
            } catch (e) {
              print('❌ Error in token refresh flow: $e');
            }
            _isRefreshing = false;
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get client => _dio;
}
