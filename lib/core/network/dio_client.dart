import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:synchronized/synchronized.dart';
import 'package:talker/talker.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/router/routes.dart';

class DioClient {
  final String _baseUrl = dotenv.env['API_BASE_URL']!;
  final Dio _dio;
  final Talker _talker = Talker();
  final Lock _refreshTokenLock = Lock();
  static final DioClient _instance = DioClient._internal();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  factory DioClient() => _instance;

  DioClient._internal()
      : _dio = Dio(BaseOptions(
          baseUrl: dotenv.env['API_BASE_URL']!,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Добавляем access token из SharedPrefs
        final prefs = getIt<SharedPrefsRepository>();
        final accessToken = await prefs.getAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }

        // Добавляем Timezone
        try {
          final tz = await FlutterTimezone.getLocalTimezone();
          options.headers['X-Timezone'] = tz;
          _talker.info('🕒 Timezone: $tz');
        } catch (_) {
          options.headers['X-Timezone'] = 'UTC';
          _talker.info('🕒 X-Timezone fallback: UTC');
        }

        _talker.info('📡 ${options.method} ${options.uri}');
        _talker.info('📦 Headers: ${options.headers}');
        return handler.next(options);
      },
      onError: (error, handler) async {
        final shouldSkip =
            error.requestOptions.headers['X-Skip-Auth-Refresh'] == true;

        // Авто‑рефреш только при 401 и если явно не запрещено
        if (error.response?.statusCode == 401 && !shouldSkip) {
          try {
            // Блокируем все остальные попытки пока идёт рефреш
            await _refreshTokenLock.synchronized(() async {
              final prefs = getIt<SharedPrefsRepository>();
              final refreshToken = await prefs.getRefreshToken();
              if (refreshToken == null) {
                throw Exception('Нет refresh token');
              }

              // Делаем запрос на обновление токена
              final tokenDio = Dio(BaseOptions(
                baseUrl: _baseUrl,
                headers: {'Content-Type': 'application/json'},
              ));
              final resp = await tokenDio.post(
                '/auth/jwt/refresh/',
                data: {'refresh': refreshToken},
              );

              if (resp.statusCode == 200) {
                final newAccess = resp.data['access'] as String;
                final newRefresh = resp.data['refresh'] as String;
                await prefs.saveAccessToken(newAccess);
                await prefs.saveRefreshToken(newRefresh);
              } else {
                throw Exception(
                    'Refresh failed: ${resp.statusCode} ${resp.data}');
              }
            });

            // Повторяем оригинальный запрос с новым access token
            final options = error.requestOptions;
            final retryResponse = await _dio.request(
              options.path,
              options: Options(
                method: options.method,
                headers: options.headers,
                contentType: options.contentType,
                responseType: options.responseType,
                followRedirects: options.followRedirects,
                validateStatus: options.validateStatus,
                receiveDataWhenStatusError: options.receiveDataWhenStatusError,
                extra: options.extra,
              ),
              data: options.data,
              queryParameters: options.queryParameters,
            );
            return handler.resolve(retryResponse);
          } catch (e) {
            // При неудаче очистим токены и отправим на логин
            final prefs = getIt<SharedPrefsRepository>();
            await prefs.deleteAccessToken();
            await prefs.deleteRefreshToken();

            final context =
                getIt.get<GlobalKey<NavigatorState>>().currentContext;
            if (context != null) {
              context.go(AppRoutes.authorization);
            }
            return handler.next(error);
          }
        }

        return handler.next(error);
      },
    ));
  }

  Dio get client => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(
      path,
      queryParameters: queryParameters,
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }

  Future<void> registerFcmToken(String fcmToken) async {
    try {
      final prefs = getIt<SharedPrefsRepository>();
      final refreshToken = await prefs.getRefreshToken();

      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      String deviceType;
      String deviceIdentifier;

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceType = 'android';
        deviceIdentifier = androidInfo.id;
        _talker.info('📱 Android device info: $androidInfo');
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceType = 'ios';
        deviceIdentifier = iosInfo.identifierForVendor ?? 'unknown';
        _talker.info('📱 iOS device info: $iosInfo');
      } else {
        throw Exception('Unsupported platform');
      }

      _talker.info('📱 Device type: $deviceType');
      _talker.info('📱 Device identifier: $deviceIdentifier');
      _talker.info('🔑 FCM token: $fcmToken');

      final response = await _dio.post(
        '/users/me/device_tokens/',
        data: {
          'token': fcmToken,
          'device_type': deviceType,
          'device_identifier': deviceIdentifier,
          'refresh_token': refreshToken,
        },
      );

      _talker.info('📡 Response status: ${response.statusCode}');
      _talker.info('📡 Response data: ${response.data}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to register FCM token: ${response.statusCode}');
      }

      _talker.info('✅ FCM token registered successfully');
    } catch (e) {
      _talker.error('❌ Failed to register FCM token: $e');
      rethrow;
    }
  }
}
