import 'package:flutter/foundation.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/src/features/auth/authorization_response_model.dart';

class AuthorizationRepositoryImpl {
  final ApiService apiService;
  final prefs = getIt.get<SharedPrefsRepository>();
  AuthorizationRepositoryImpl({required this.apiService});

  Future<AuthorizationResponseModel> authorize({
    required String login,
    required String password,
  }) async {
    final response = await apiService.postData(
        '/auth/token/login/',
        {
          'login': login,
          'password': password,
        },
        useAuth: false);

    final responseModel = AuthorizationResponseModel.fromJson(
        response['data'], response['statusCode']);

    if (responseModel.accessToken != null &&
        responseModel.refreshToken != null) {
      await prefs.saveAccessToken(responseModel.accessToken!);
      await prefs.saveRefreshToken(responseModel.refreshToken!);
      debugPrint("🔑 Токены сохранены при авторизации");
    }

    return responseModel;
  }

  Future<bool> isAuthorized() async {
    final accessToken = await prefs.getString('access_token');
    final refreshToken = await prefs.getString('refresh_token');

    if (accessToken == null || refreshToken == null) {
      return false;
    }
    return true;
  }

  Future<void> logout() async {
    await prefs.deleteKey('access_token');
    await prefs.deleteKey('refresh_token');
  }
}
