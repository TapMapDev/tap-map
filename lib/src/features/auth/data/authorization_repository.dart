import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:tap_map/core/config/auth_config.dart';
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

      final statusCode = response['statusCode'] as int;
      final data = response['data'];

      if (statusCode == 200 || statusCode == 201) {
        final responseModel = AuthorizationResponseModel.fromJson(
          data,
          statusCode,
        );

        if (responseModel.accessToken != null &&
            responseModel.refreshToken != null) {
          await prefs.saveAccessToken(responseModel.accessToken!);
          await prefs.saveRefreshToken(responseModel.refreshToken!);
        }

        return responseModel;
      } else {
        String message = 'Ошибка авторизации';
        if (data != null) {
          if (data['detail'] is List) {
            message = (data['detail'] as List).join(', ');
          } else if (data['detail'] != null) {
            message = data['detail'].toString();
          } else if (data['message'] != null) {
            message = data['message'].toString();
          }
        }

        return AuthorizationResponseModel(
          statusCode: statusCode,
          accessToken: null,
          refreshToken: null,
          message: message,
        );
      }
    } on DioException catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);

      final int statusCode = e.response?.statusCode ?? -1;
      String message = 'Произошла ошибка';

      final data = e.response?.data;
      if (data != null) {
        if (data['detail'] is List) {
          message = (data['detail'] as List).join(', ');
        } else if (data['detail'] != null) {
          message = data['detail'].toString();
        } else if (data['message'] != null) {
          message = data['message'].toString();
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

  Future<void> initialize() async {
    final refreshToken = await prefs.getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token');

    try {
      // Попробуй обновить токены
      final response = await apiService.postData(
        '/auth/token/refresh/',
        {'refresh_token': refreshToken},
        useAuth: false,
      );

      final newAccessToken = response['data']['access'];
      final newRefreshToken = response['data']['refresh'];

      if (newAccessToken != null && newRefreshToken != null) {
        await prefs.saveAccessToken(newAccessToken);
        await prefs.saveRefreshToken(newRefreshToken);

        // Зарегистрировать FCM токен
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          // Отправить fcmToken на сервер
        }
      } else {
        throw Exception('Invalid token response');
      }
    } catch (e) {
      await logout();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      final accessToken = await prefs.getString('access_token');
      final refreshToken = await prefs.getString('refresh_token');
      final deviceTokenId = await prefs.getString('device_token_id');

      if (accessToken == null || refreshToken == null) {
        return;
      }

      // Деактивируем FCM токен, если есть device_token_id
      if (deviceTokenId != null) {
        try {
          await deactivateFcmToken(deviceTokenId);
          await prefs.deleteKey('device_token_id');
          debugPrint('✅ Device token ID deleted from local storage');
        } catch (e) {
          debugPrint('⚠️ Failed to deactivate FCM token: $e');
        }
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
        debugPrint('✅ Logout successful');
      } else {
        debugPrint('⚠️ Logout failed with status code: $statusCode');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Logout error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deactivateFcmToken(String tokenId) async {
    try {
      final accessToken = await prefs.getString('access_token');

      if (accessToken == null) {
        debugPrint('No access token. Skipping FCM token deactivation.');
        return;
      }
      final response = await apiService.postData(
        '/users/me/device_tokens/$tokenId/deactivate/',
        null,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        useAuth: false,
      );
      final statusCode = response['statusCode'] as int?;

      if (statusCode == 200 || statusCode == 204) {
        debugPrint('✅ FCM token deactivated successfully');
      } else {
        debugPrint('⚠️ FCM token deactivation failed with status code: $statusCode');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error deactivating FCM token: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Авторизация через Google
  Future<AuthorizationResponseModel> signInWithGoogle() async {
    try {
      // Вызов Google SDK для авторизации с клиентским ID из конфигурации
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: AuthConfig.googleClientId,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        return AuthorizationResponseModel(
          statusCode: 400,
          message: 'Авторизация через Google отменена пользователем',
          accessToken: null,
          refreshToken: null,
        );
      }
      
      // Получение токена авторизации
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Формирование userData для API
      final Map<String, dynamic> userData = {
        'id': googleUser.id,
        'email': googleUser.email,
        'first_name': googleUser.displayName?.split(' ').first ?? '',
        'last_name': googleUser.displayName != null && googleUser.displayName!.split(' ').length > 1
            ? googleUser.displayName!.split(' ').last 
            : '',
      };
      
      // Вызов API для Google авторизации
      return await authorizeWithGoogle(googleAuth.accessToken!, userData);
    } catch (e, stackTrace) {
      debugPrint('❌ Google sign in error: $e');
      debugPrintStack(stackTrace: stackTrace);
      
      return AuthorizationResponseModel(
        accessToken: null,
        refreshToken: null,
        statusCode: -1,
        message: 'Ошибка авторизации через Google: $e',
      );
    }
  }
  
  /// Авторизация через Facebook
  Future<AuthorizationResponseModel> signInWithFacebook() async {
    try {
      // Вызов Facebook SDK для авторизации
      final LoginResult result = await FacebookAuth.instance.login(permissions: ['email', 'public_profile']);
      
      if (result.status != LoginStatus.success) {
        return AuthorizationResponseModel(
          statusCode: 400,
          message: 'Авторизация через Facebook не удалась: ${result.status}',
          accessToken: null,
          refreshToken: null,
        );
      }
      
      // Получение данных пользователя
      final userData = await FacebookAuth.instance.getUserData(fields: 'id,email,first_name,last_name');
      
      // Вызов API для Facebook авторизации
      return await authorizeWithFacebook(result.accessToken!.token, userData);
    } catch (e, stackTrace) {
      debugPrint('❌ Facebook sign in error: $e');
      debugPrintStack(stackTrace: stackTrace);
      
      return AuthorizationResponseModel(
        accessToken: null,
        refreshToken: null,
        statusCode: -1,
        message: 'Ошибка авторизации через Facebook: $e',
      );
    }
  }
  
  /// Отправка токена и данных Google на сервер
  Future<AuthorizationResponseModel> authorizeWithGoogle(
      String accessToken, Map<String, dynamic> userData) async {
    try {
      final response = await apiService.postData(
        '/auth/google/',
        {
          'access_token': accessToken,
          'user_data': userData,
        },
        useAuth: false,
      );
      
      return _processAuthResponse(response);
    } on DioException catch (e, stackTrace) {
      return _handleDioError(e, stackTrace, 'Google');
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      return AuthorizationResponseModel(
        accessToken: null,
        refreshToken: null,
        statusCode: -1,
        message: 'Неизвестная ошибка при авторизации через Google: $e',
      );
    }
  }
  
  /// Отправка токена и данных Facebook на сервер
  Future<AuthorizationResponseModel> authorizeWithFacebook(
      String accessToken, Map<String, dynamic> userData) async {
    try {
      final response = await apiService.postData(
        '/auth/facebook/',
        {
          'access_token': accessToken,
          'user_data': userData,
        },
        useAuth: false,
      );
      
      return _processAuthResponse(response);
    } on DioException catch (e, stackTrace) {
      return _handleDioError(e, stackTrace, 'Facebook');
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      return AuthorizationResponseModel(
        accessToken: null,
        refreshToken: null,
        statusCode: -1,
        message: 'Неизвестная ошибка при авторизации через Facebook: $e',
      );
    }
  }
  
  /// Обработка ответа API от социальных сетей
  AuthorizationResponseModel _processAuthResponse(Map<String, dynamic> response) {
    final statusCode = response['statusCode'] as int;
    final data = response['data'];
    
    if (statusCode == 200 || statusCode == 201) {
      final responseModel = AuthorizationResponseModel.fromJson(
        data,
        statusCode,
      );
      
      if (responseModel.accessToken != null &&
          responseModel.refreshToken != null) {
        prefs.saveAccessToken(responseModel.accessToken!);
        prefs.saveRefreshToken(responseModel.refreshToken!);
      }
      
      return responseModel;
    } else {
      String message = 'Ошибка авторизации';
      if (data != null) {
        if (data['detail'] is List) {
          message = (data['detail'] as List).join(', ');
        } else if (data['detail'] != null) {
          message = data['detail'].toString();
        } else if (data['message'] != null) {
          message = data['message'].toString();
        }
      }
      
      return AuthorizationResponseModel(
        statusCode: statusCode,
        accessToken: null,
        refreshToken: null,
        message: message,
      );
    }
  }
  
  /// Обработка ошибок Dio
  AuthorizationResponseModel _handleDioError(DioException e, StackTrace stackTrace, String provider) {
    debugPrintStack(stackTrace: stackTrace);
    
    final int statusCode = e.response?.statusCode ?? -1;
    String message = 'Произошла ошибка при авторизации через $provider';
    
    final data = e.response?.data;
    if (data != null) {
      if (data['detail'] is List) {
        message = (data['detail'] as List).join(', ');
      } else if (data['detail'] != null) {
        message = data['detail'].toString();
      } else if (data['message'] != null) {
        message = data['message'].toString();
      }
    }
    
    return AuthorizationResponseModel(
      accessToken: null,
      refreshToken: null,
      statusCode: statusCode,
      message: message,
    );
  }
}
