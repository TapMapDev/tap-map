

import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/src/features/auth/authorization_response_model.dart';

class AuthorizationRepositoryImpl {
  final ApiService apiService;
  final prefs = getIt.get<SharedPrefsRepository>();
  AuthorizationRepositoryImpl({required this.apiService});

  Future<AuthorizationResponseModel> authorize({
    required String email,
    required String password,
  }) async {
    final response = await apiService.postData(
        '/user/login',
        {
          'email': email,
          'password': password,
        },
        useAuth: false);
    final responseModel = AuthorizationResponseModel.fromJson(
        response['data'], response['statusCode']);
    if (responseModel.accessToken != null &&
        responseModel.refreshToken != null) {
      await prefs.setString('access_token', responseModel.accessToken!);
      await prefs.setString('refresh_token', responseModel.refreshToken!);
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
    await prefs.deleteString('access_token');
    await prefs.deleteString('refresh_token');
  }
}
