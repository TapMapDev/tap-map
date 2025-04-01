import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/router/routes.dart';

class DioClient {
  late final Dio _dio;
  bool _isRefreshing = false;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.tap-map.net/api',
        receiveTimeout: const Duration(seconds: 30),
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          // Проверяем наличие заголовка, запрещающего обновление токена для некритичных запросов
          final skipAuthRefresh =
              error.requestOptions.headers['X-Skip-Auth-Refresh'] == 'true';

          if (error.response?.statusCode == 401 &&
              !_isRefreshing &&
              !skipAuthRefresh) {
            _isRefreshing = true;
            try {
              final prefs = getIt.get<SharedPrefsRepository>();
              final refreshToken = await prefs.getRefreshToken();

              if (refreshToken != null) {
                // Создаем новый Dio для запроса обновления токена
                final tokenDio = Dio(BaseOptions(
                  baseUrl: 'https://api.tap-map.net/api',
                  headers: {'Content-Type': 'application/json'},
                ));

                try {
                  final response = await tokenDio.post(
                    '/auth/jwt/refresh/',
                    data: {'refresh': refreshToken},
                  );

                  if (response.statusCode == 200) {
                    final newAccessToken = response.data['access'];
                    final newRefreshToken = response.data['refresh'];

                    // Сохраняем новые токены, используя правильные методы
                    await prefs.saveAccessToken(newAccessToken);
                    await prefs.saveRefreshToken(newRefreshToken);

                    // Повторяем исходный запрос с новым токеном
                    error.requestOptions.headers['Authorization'] =
                        'Bearer $newAccessToken';
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
                    return handler.resolve(clonedRequest);
                  }
                } catch (refreshError) {
                  await prefs.deleteAccessToken();
                  await prefs.deleteRefreshToken();


                  // Перенаправляем на страницу авторизации используя GoRouter
                  final context =
                      getIt.get<GlobalKey<NavigatorState>>().currentContext;
                  if (context != null) {
                    context.go(AppRoutes.authorization);
                  }
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
