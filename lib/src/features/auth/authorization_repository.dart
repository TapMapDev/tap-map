import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/src/features/auth/authorization_response_model.dart';

class AuthorizationRepositoryImpl {
  final ApiService apiService;
  final prefs = getIt.get<SharedPrefsRepository>();
  AuthorizationRepositoryImpl({required this.apiService});

  Future<AuthorizationResponseModel> authorize({
    required String username,
    required String password,
  }) async {
    print('🔄 Starting authorization process...');
    final response = await apiService.postData(
        '/auth/jwt/create/',
        {
          'username': username,
          'password': password,
        },
        useAuth: false);

    print("📝 API Response: $response");

    final responseModel = AuthorizationResponseModel.fromJson(
        response['data'], response['statusCode']);

    if (responseModel.accessToken != null &&
        responseModel.refreshToken != null) {
      print("✅ Tokens received, saving...");
      print(
          "📝 Access Token: ${responseModel.accessToken?.substring(0, 10)}...");
      print(
          "📝 Refresh Token: ${responseModel.refreshToken?.substring(0, 10)}...");

      await prefs.setString('access_token', responseModel.accessToken!);
      await prefs.setString('refresh_token', responseModel.refreshToken!);
      print("💾 Tokens saved successfully");
    } else {
      print("❌ Error: Tokens not received");
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
