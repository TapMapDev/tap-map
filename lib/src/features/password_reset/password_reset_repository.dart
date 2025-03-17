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

      print('Reset password response: ${response['data']}'); // Debug log

      // Handle empty response
      if (response['data'] == null || response['data'].toString().isEmpty) {
        return PasswordResetModel(
          statusCode: response['statusCode'] ?? 200,
          message: 'Password reset instructions have been sent to your email',
        );
      }

      if (response['data'] is String) {
        final data = response['data'] as String;
        print('Response data: $data'); // Debug log

        // Extract uid and token from the response URL or message
        final uidMatch = RegExp(r'uid=([^&]+)').firstMatch(data);
        final tokenMatch = RegExp(r'token=([^&]+)').firstMatch(data);

        if (uidMatch != null && tokenMatch != null) {
          _resetUid = uidMatch.group(1);
          _resetToken = tokenMatch.group(1);
          print('Extracted uid: $_resetUid, token: $_resetToken'); // Debug log
        }

        return PasswordResetModel.fromJson(
            {'message': data}, response['statusCode']);
      } else if (response['data'] is Map) {
        return PasswordResetModel.fromJson(
            response['data'], response['statusCode']);
      } else {
        throw Exception('Unexpected response format: ${response['data']}');
      }
    } catch (e) {
      print('Error in sendConfirmationCode: $e'); // Debug log
      rethrow;
    }
  }

  // Future<PasswordResetModel> confirmCode({
  //   required String email,
  //   required String code,
  // }) async {
  //   final response = await apiService.postData(
  //       '/user/verify_confirmation_code',
  //       {
  //         'email': email,
  //         'code': code,
  //       },
  //       useAuth: false);
  //   final responseModel =
  //       PasswordResetModel.fromJson(response['data'], response['statusCode']);
  //   return responseModel;
  // }

  Future<PasswordResetModel> setNewPassword({
    required String newPassword,
    required String confrimPassword,
  }) async {
    if (_resetUid == null || _resetToken == null) {
      throw Exception(
          'Reset credentials not found. Please request password reset first.');
    }

    final response = await apiService.postData(
        '/auth/users/reset_password_confirm/',
        {
          'uid': _resetUid,
          'token': _resetToken,
          'new_password': newPassword,
          'confirm_password': confrimPassword
        },
        useAuth: false);

    final responseModel =
        PasswordResetModel.fromJson(response['data'], response['statusCode']);
    return responseModel;
  }
}
