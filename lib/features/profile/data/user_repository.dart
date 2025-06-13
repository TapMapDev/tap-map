import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/features/profile/model/user_response_model.dart';

// TODO(tapmap): Упростить репозиторий, убрать абстракцию IUserRepository и
// использовать единый класс репозитория.

abstract class IUserRepository {
  Future<UserModel> getCurrentUser();
  Future<UserModel> getUserByUsername(String username);
  Future<UserModel> getUserById(int userId);
  Future<UserModel> updateUser(UserModel user);
  Future<String> updateAvatar(File imageFile);
  Future<List<UserAvatarModel>> getUserAvatars();
  Future<bool> deleteAvatar(int avatarId);
  Future<PrivacySettings> updatePrivacySettings(
      PrivacySettings privacySettings);
  Future<PrivacySettings> getPrivacySettings();
  Future<void> blockUser(int userId);
  Future<void> unblockUser(int userId);
}

class UserRepository implements IUserRepository {
  final ApiService apiService;

  UserRepository({required this.apiService});

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await apiService.getData('/users/me/');

      // Handle different response formats
      dynamic data;
      if (response['data'] is Map<String, dynamic>) {
        data = response['data'];
      } else if (response['data'] is String) {
        try {
          data = json.decode(response['data']);
        } catch (e) {
          throw Exception('Invalid JSON string: ${response['data']}');
        }
      } else {
        throw Exception('Unexpected response format: ${response['data']}');
      }

      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  @override
  Future<UserModel> getUserByUsername(String username) async {
    try {
      debugPrint('🔄 Making API request for username: $username');
      final response = await apiService.getData('/users/@$username/');
      debugPrint('📥 API Response: $response');

      if (response['statusCode'] == 200) {
        dynamic userData = response['data'];
        // Если userData — строка, проверяем, что это не HTML
        if (userData is String) {
          if (userData.trim().startsWith('<!DOCTYPE html>')) {
            throw Exception('Пользователь не найден или ссылка некорректна');
          }
          userData = json.decode(userData);
        }
        debugPrint('✅ Parsing user data: $userData');
        return UserModel.fromJson(userData);
      } else {
        debugPrint('❌ API Error: ${response['data']}');
        throw Exception('Пользователь не найден или сервер вернул ошибку');
      }
    } catch (e) {
      debugPrint('❌ Repository Error: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel> getUserById(int userId) async {
    try {
      debugPrint('🔄 Making API request for user ID: $userId');
      final response = await apiService.getData('/users/$userId/');
      debugPrint('📥 API Response: $response');

      if (response['statusCode'] == 200) {
        dynamic userData = response['data'];
        if (userData is String) {
          if (userData.trim().startsWith('<!DOCTYPE html>')) {
            throw Exception('Пользователь не найден или ссылка некорректна');
          }
          userData = json.decode(userData);
        }
        debugPrint('✅ Parsing user data: $userData');
        return UserModel.fromJson(userData);
      } else {
        debugPrint('❌ API Error: ${response['data']}');
        throw Exception('Пользователь не найден или сервер вернул ошибку');
      }
    } catch (e) {
      debugPrint('❌ Repository Error: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final body = user.toJson();

      // Удаляем пустые строки, чтобы не вызывать ошибки валидации
      body.removeWhere((key, value) => value is String && value.isEmpty);

      final response = await apiService.patchData('/users/me/', body);

      // Проверяем ошибки
      if (response['statusCode'] >= 400) {
        throw Exception(
            'Server returned error ${response['statusCode']}: ${response['data']}');
      }

      // Handle different response formats
      dynamic data;
      if (response['data'] is Map<String, dynamic>) {
        data = response['data'];
      } else if (response['data'] is String) {
        // If the response is a string, try to parse it as JSON
        try {
          data = json.decode(response['data']);
        } catch (e) {
          throw Exception('Invalid JSON string: ${response['data']}');
        }
      } else {
        throw Exception('Unexpected response format: ${response['data']}');
      }

      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  @override
  Future<String> updateAvatar(File imageFile) async {
    try {
      // Подготавливаем MultipartFile для отправки файла
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      // Получаем токен авторизации из SharedPrefs
      final prefs = getIt.get<SharedPrefsRepository>();
      final authToken = await prefs.getAccessToken();

      if (authToken == null) {
        throw Exception('Access token is null');
      }

      // Отправляем запрос на обновление аватара
      final response = await apiService.dioClient.client.post(
        '/users/me/avatars/',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
          validateStatus: (status) => true,
        ),
      );

      // Проверяем ответ
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        // Извлекаем URL аватара из ответа
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('avatar_url') &&
              responseData['avatar_url'] != null) {
            return responseData['avatar_url'] as String;
          } else if (responseData.containsKey('url') &&
              responseData['url'] != null) {
            return responseData['url'] as String;
          } else if (responseData.containsKey('avatar') &&
              responseData['avatar'] != null) {
            return responseData['avatar'] as String;
          } else if (responseData.containsKey('image') &&
              responseData['image'] != null) {
            return responseData['image'] as String;
          } else {
            throw Exception('Server response does not contain avatar URL');
          }
        } else {
          throw Exception('Invalid response format from server');
        }
      } else {
        throw Exception(
            'Error uploading avatar: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(
            'Failed to update avatar: ${e.response?.data ?? e.message}');
      }
      throw Exception('Failed to update avatar: $e');
    }
  }

  @override
  Future<List<UserAvatarModel>> getUserAvatars() async {
    try {
      // Получаем токен авторизации из SharedPrefs
      final prefs = getIt.get<SharedPrefsRepository>();
      final authToken = await prefs.getAccessToken();

      if (authToken == null) {
        throw Exception('Access token is null');
      }

      // Отправляем запрос на получение списка аватаров
      final response = await apiService.dioClient.client.get(
        '/users/me/avatars/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = response.data;

        // Преобразуем список dynamic в список UserAvatarModel
        return responseData
            .map<UserAvatarModel>((item) =>
                UserAvatarModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            'Error fetching avatars: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(
            'Failed to get avatars: ${e.response?.data ?? e.message}');
      }
      throw Exception('Failed to get avatars: $e');
    }
  }

  @override
  Future<bool> deleteAvatar(int avatarId) async {
    try {
      // Получаем токен авторизации из SharedPrefs
      final prefs = getIt.get<SharedPrefsRepository>();
      final authToken = await prefs.getAccessToken();

      if (authToken == null) {
        throw Exception('Access token is null');
      }

      // Отправляем запрос на удаление аватара
      final response = await apiService.dioClient.client.delete(
        '/users/me/avatars/$avatarId/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
          validateStatus: (status) => true,
        ),
      );

      // Проверяем ответ
      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
            'Error deleting avatar: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(
            'Failed to delete avatar: ${e.response?.data ?? e.message}');
      }
      throw Exception('Failed to delete avatar: $e');
    }
  }

  @override
  Future<PrivacySettings> updatePrivacySettings(
      PrivacySettings privacySettings) async {
    try {
      final body = {
        'is_searchable_by_email': privacySettings.isSearchableByEmail == true,
        'is_searchable_by_phone': privacySettings.isSearchableByPhone == true
      };

      // Добавляем дополнительные поля, если они не null
      if (privacySettings.isShowGeolocationToFriends != null) {
        body['is_show_geolocation_to_friends'] =
            privacySettings.isShowGeolocationToFriends == true;
      }

      if (privacySettings.isPreciseGeolocation != null) {
        body['is_precise_geolocation'] =
            privacySettings.isPreciseGeolocation == true;
      }

      // Отправляем запрос на обновление настроек приватности
      final response = await apiService.patchData('/users/me/privacy/', body);

      // Проверяем ошибки
      if (response['statusCode'] >= 400) {
        throw Exception(
            'Server returned error ${response['statusCode']}: ${response['data']}');
      }

      // Handle different response formats
      dynamic data;
      if (response['data'] is Map<String, dynamic>) {
        data = response['data'];
      } else if (response['data'] is String) {
        // If the response is a string, try to parse it as JSON
        try {
          data = json.decode(response['data']);
        } catch (e) {
          throw Exception('Invalid JSON string: ${response['data']}');
        }
      } else {
        throw Exception('Unexpected response format: ${response['data']}');
      }

      return PrivacySettings.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update privacy settings: $e');
    }
  }

  @override
  Future<PrivacySettings> getPrivacySettings() async {
    try {
      // Отправляем запрос на получение настроек приватности
      final response = await apiService.getData('/users/me/privacy/');

      // Проверяем ошибки
      if (response['statusCode'] >= 400) {
        throw Exception(
            'Server returned error ${response['statusCode']}: ${response['data']}');
      }

      // Handle different response formats
      dynamic data;
      if (response['data'] is Map<String, dynamic>) {
        data = response['data'];
      } else if (response['data'] is String) {
        // If the response is a string, try to parse it as JSON
        try {
          data = json.decode(response['data']);
        } catch (e) {
          throw Exception('Invalid JSON string: ${response['data']}');
        }
      } else {
        throw Exception('Unexpected response format: ${response['data']}');
      }

      return PrivacySettings.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get privacy settings: $e');
    }
  }

  @override
  Future<void> blockUser(int userId) async {
    try {
      await apiService.postData('/users/block/$userId/', {});
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  @override
  Future<void> unblockUser(int userId) async {
    try {
      await apiService.postData('/users/unblock/$userId/', {});
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  /// Поиск пользователей по имени пользователя или email.
  /// Возвращает список найденных пользователей.
  /// TODO(tapmap): уточнить конечную точку API и параметры запроса.
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await apiService.getData(
        '/users/search/',
        queryParams: {'query': query},
      );

      if (response['statusCode'] == 200) {
        final data = response['data'];
        if (data is List) {
          return UserModel.fromJsonList(data);
        } else if (data is Map<String, dynamic> && data['results'] is List) {
          return UserModel.fromJsonList(data['results'] as List);
        }
        return [];
      } else {
        throw Exception('Search request failed: ${response['statusCode']}');
      }
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}
