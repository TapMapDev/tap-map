import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/src/features/auth/model/authorization_response_model.dart';

class AuthorizationRepositoryImpl {
  final ApiService apiService;
  final SharedPrefsRepository prefs = getIt.get<SharedPrefsRepository>();

  AuthorizationRepositoryImpl({required this.apiService});

  Future<AuthorizationResponseModel> authorize({
    required String login,
    required String password,
  }) async {
    try {
      final response = await apiService.postData(
        '/auth/token/login/',
        {
          'login': login,
          'password': password,
        },
        useAuth: false,
      );

      final responseModel = AuthorizationResponseModel.fromJson(
        response['data'],
        response['statusCode'],
      );

    if (responseModel.accessToken != null &&
        responseModel.refreshToken != null) {
      await prefs.saveAccessToken(responseModel.accessToken!);
      await prefs.saveRefreshToken(responseModel.refreshToken!);
    }

    return responseModel;
  } on DioException catch (e, stackTrace) {
    debugPrintStack(stackTrace: stackTrace);

    final int statusCode = e.response?.statusCode ?? -1;
    String message = 'Произошла ошибка';

    final data = e.response?.data;
    if (data != null) {
      if (data['detail'] is List) {
        message = data['detail'].join(', ');
      } else if (data['detail'] != null) {
        message = data['detail'].toString();
      }
    }

    return AuthorizationResponseModel(
      accessToken: null,
      refreshToken: null,
      statusCode: statusCode,
      message: message,
    );
  } catch (e, stackTrace) {
    debugPrintStack(stackTrace: stackTrace);
    return AuthorizationResponseModel(
      accessToken: null,
      refreshToken: null,
      statusCode: -1,
      message: 'Неизвестная ошибка: $e',
    );
  }
}

  Future<bool> isAuthorized() async {
    final accessToken = await prefs.getString('access_token');
    final refreshToken = await prefs.getString('refresh_token');
    return accessToken != null && refreshToken != null;
  }

  Future<void> logout() async {
    try {
      final accessToken = await prefs.getString('access_token');
      final refreshToken = await prefs.getString('refresh_token');

      if (accessToken == null || refreshToken == null) {
        debugPrint('Logout aborted: Missing tokens');
        return;
      }

      final response = await apiService.postData(
        '/sessions/logout/',
        {'refresh_token': refreshToken},
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        useAuth: false,
      );

      final statusCode = response['statusCode'] as int?;

      if (statusCode == 200 || statusCode == 204) {
        await prefs.deleteKey('access_token');
        await prefs.deleteKey('refresh_token');
        debugPrint('Logout successful');
      } else {
        debugPrint('Logout failed with status code: $statusCode');
      }
    } catch (e, stackTrace) {
      debugPrint('Logout error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
