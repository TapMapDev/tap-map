import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/src/features/password_reset/password_reset_response_model.dart';

class ResetPasswordRepositoryImpl {
  final ApiService apiService;
  final prefs = getIt.get<SharedPrefsRepository>();
  String? _resetEmail;
  String? _resetUid;
  String? _resetToken;

  ResetPasswordRepositoryImpl({required this.apiService});

  // Метод для обработки глубокой ссылки
  void handleResetPasswordLink(String url) {

    final uidMatch = RegExp(r'uid=([^&]+)').firstMatch(url);
    final tokenMatch = RegExp(r'token=([^&]+)').firstMatch(url);

    if (uidMatch != null && tokenMatch != null) {
      _resetUid = uidMatch.group(1);
      _resetToken = tokenMatch.group(1);
    } else {
      throw Exception('Invalid reset password link');
    }
  }

  Future<PasswordResetModel> sendConfirmationCode({
    required String email,
  }) async {
    try {
      _resetEmail = email;
      final response = await apiService.postData(
          '/auth/users/reset_password/',
          {
            'email': email,
          },
          useAuth: false);

      // Handle empty response
      if (response['data'] == null || response['data'].toString().isEmpty) {
        return PasswordResetModel(
          statusCode: response['statusCode'] ?? 200,
          message: 'Password reset link has been sent to your email',
        );
      }

      if (response['data'] is String) {
        final data = response['data'] as String;
        return PasswordResetModel.fromJson(
            {'message': data}, response['statusCode']);
      } else if (response['data'] is Map) {
        return PasswordResetModel.fromJson(
            response['data'], response['statusCode']);
      } else {
        throw Exception('Unexpected response format: ${response['data']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<PasswordResetModel> setNewPassword({
   required String? uid,
  required String? token,
  required String password,
  required String confirmPassword,
  }) async {
    if (_resetUid == null || _resetToken == null) {
      throw Exception(
          'Reset credentials not found. Please click the link from your email first.');
    }

    final response = await apiService.postData(
        '/auth/users/reset_password_confirm/',
          {
            'uid': uid,
            'token': token,
          'new_password': password,
          'confirm_password': confirmPassword
        },
        useAuth: false);

    final responseModel =
        PasswordResetModel.fromJson(response['data'], response['statusCode']);
    return responseModel;
  }
}
