import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/src/features/userFlow/user_profile/model/user_response_model.dart';

abstract class IUserRepository {
  Future<UserModel> getCurrentUser();
  Future<UserModel> updateUser(UserModel user);
  Future<String> updateAvatar(File imageFile);
  Future<List<UserAvatarModel>> getUserAvatars();
  Future<bool> deleteAvatar(int avatarId);
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
      throw Exception('Failed to get user data: $e');
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
}
