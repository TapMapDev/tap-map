import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/features/password_reset/model/password_reset_response_model.dart';

class ResetPasswordRepositoryImpl {
  final ApiService apiService;
  final prefs = getIt.get<SharedPrefsRepository>();
  String? _resetEmail;
  String? _resetUid;
  String? _resetToken;

  ResetPasswordRepositoryImpl({required this.apiService});

  // Метод для обработки глубокой ссылки
  void handleResetPasswordLink(String url) {
    print('🔗 Processing reset password link: $url');

    final uidMatch = RegExp(r'uid=([^&]+)').firstMatch(url);
    final tokenMatch = RegExp(r'token=([^&]+)').firstMatch(url);

    print('🔍 Found matches:');
    print('UID match: ${uidMatch?.group(1)}');
    print('Token match: ${tokenMatch?.group(1)}');

    if (uidMatch != null && tokenMatch != null) {
      _resetUid = uidMatch.group(1);
      _resetToken = tokenMatch.group(1);

      // Декодируем токен, так как он может содержать URL-encoded символы
      _resetToken = Uri.decodeComponent(_resetToken!);

      print('✅ Extracted values:');
      print('UID: $_resetUid');
      print('Token: $_resetToken');
    } else {
      print('❌ Invalid reset password link: required parameters not found');
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
          message:
              'Линк для сброса пароля отправлен ​​на вашу электронную почты.',
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
    required String newPassword,
  }) async {
    try {
      print('🔄 Отправка запроса на сброс пароля:');
      print('UID: $uid');
      print('Token: $token');
      print('Password length: ${newPassword.length}');

      // Проверяем, что uid и token не null
      if (uid == null || token == null) {
        print('❌ UID или Token равны null');
        throw Exception('UID и Token обязательны для сброса пароля');
      }

      final requestData = {
        'uid': uid,
        'token': token,
        'new_password': newPassword,
      };
      print('📤 Request data: $requestData');

      final response = await apiService.postData(
          '/auth/users/reset_password_confirm/', requestData,
          useAuth: false);

      print('📥 Response status: ${response['statusCode']}');
      print('📥 Response data: ${response['data']}');

      // Успешный ответ без контента (204)
      if (response['statusCode'] == 204) {
        return PasswordResetModel(
          statusCode: 204,
          message: 'Пароль успешно изменен!',
        );
      }

      // Обработка пустого ответа
      if (response['data'] == null || response['data'].toString().isEmpty) {
        return PasswordResetModel(
          statusCode: response['statusCode'] ?? 200,
          message: 'Пароль успешно изменен!',
        );
      }

      // Обработка строкового ответа
      if (response['data'] is String) {
        final data = response['data'] as String;
        return PasswordResetModel.fromJson(
            {'message': data}, response['statusCode']);
      }

      // Обработка JSON ответа
      if (response['data'] is Map) {
        return PasswordResetModel.fromJson(
            response['data'], response['statusCode']);
      }

      // Неожиданный формат ответа
      throw Exception('Unexpected response format: ${response['data']}');
    } catch (e) {
      print('❌ Error in setNewPassword: $e');
      rethrow;
    }
  }
}
