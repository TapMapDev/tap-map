import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:talker/talker.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/router/routes.dart';

class DioClient {
  late final Dio _dio;
  bool _isRefreshing = false;
  static final DioClient _singleton = DioClient._internal();
  final talker = Talker();

  factory DioClient() => _singleton;

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.tap-map.net/api',
        receiveTimeout: const Duration(seconds: 30),
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = getIt<SharedPrefsRepository>();
        final token = await prefs.getAccessToken();

        // Добавляем токен, если он есть
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Добавляем Timezone
        try {
          final timezone = await FlutterTimezone.getLocalTimezone();
          options.headers['X-Timezone'] = timezone;
          talker.info('🕒 Timezone: $timezone');
        } catch (_) {
          options.headers['X-Timezone'] = 'UTC';
          talker.info('🕒 X-Timezone fallback: UTC');
        }
        talker.info('📡 ${options.method} ${options.uri}');
        talker.info('📦 Headers: ${options.headers}');
        return handler.next(options);
      },
      onError: (error, handler) async {
        final skipAuthRefresh =
            error.requestOptions.headers['X-Skip-Auth-Refresh'] == 'true';

        if (error.response?.statusCode == 401 &&
            !_isRefreshing &&
            !skipAuthRefresh) {
          _isRefreshing = true;
          try {
            final prefs = getIt<SharedPrefsRepository>();
            final refreshToken = await prefs.getRefreshToken();

            if (refreshToken != null) {
              final tokenDio = Dio(BaseOptions(
                baseUrl: 'https://api.tap-map.net/api',
                headers: {'Content-Type': 'application/json'},
              ));

              final response = await tokenDio.post(
                '/auth/jwt/refresh/',
                data: {'refresh': refreshToken},
              );

              if (response.statusCode == 200) {
                final newAccessToken = response.data['access'];
                final newRefreshToken = response.data['refresh'];

                await prefs.saveAccessToken(newAccessToken);
                await prefs.saveRefreshToken(newRefreshToken);

                error.requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';

                final clonedResponse = await _dio.request(
                  error.requestOptions.path,
                  options: Options(
                    method: error.requestOptions.method,
                    headers: error.requestOptions.headers,
                  ),
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );

                _isRefreshing = false;
                return handler.resolve(clonedResponse);
              }
            }
          } catch (_) {
            final prefs = getIt<SharedPrefsRepository>();
            await prefs.deleteAccessToken();
            await prefs.deleteRefreshToken();

            final context =
                getIt.get<GlobalKey<NavigatorState>>().currentContext;
            if (context != null) {
              context.go(AppRoutes.authorization);
            }
          }

          _isRefreshing = false;
        }

        return handler.next(error);
      },
    ));
  }

  Dio get client => _dio;
}
