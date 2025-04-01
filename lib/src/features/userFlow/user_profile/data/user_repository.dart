import 'dart:convert';

import 'package:talker/talker.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/src/features/userFlow/user_profile/model/user_response_model.dart';

abstract class IUserRepository {
  Future<UserModel> getCurrentUser();
  Future<UserModel> updateUser(UserModel user);
}

class UserRepository implements IUserRepository {
  final ApiService apiService;
  final Talker talker = Talker();

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

      // Логируем информацию о стиле карты
      if (user.selectedMapStyle != null) {
        talker.info(
            'Original selectedMapStyle: id=${user.selectedMapStyle!.id}, name=${user.selectedMapStyle!.name}, url=${user.selectedMapStyle!.styleUrl}');
      } else {
        talker.info('Original selectedMapStyle is null');
      }

      // Удаляем пустые строки, чтобы не вызывать ошибки валидации
      body.removeWhere((key, value) => value is String && value.isEmpty);

      // Проверяем, какой тип данных для selected_map_style
      if (body.containsKey('selected_map_style')) {
        talker.info(
            'selected_map_style before sending: ${body['selected_map_style']} (${body['selected_map_style'].runtimeType})');
      } else {
        talker.info('selected_map_style is not in body');
      }

      // Обработка вложенных объектов больше не нужна, так как мы используем только ID
      // if (body['selected_map_style'] != null &&
      //     body['selected_map_style'] is Map) {
      //   final mapStyle = body['selected_map_style'] as Map<String, dynamic>;
      //   mapStyle.removeWhere((key, value) => value is String && value.isEmpty);

      //   // Если все поля пустые, удаляем весь объект
      //   if (mapStyle.isEmpty) {
      //     body.remove('selected_map_style');
      //   }
      // }

      talker.info('Sending PATCH with cleaned data: $body');
      final response = await apiService.patchData('/users/me/', body);

      // Проверяем ошибки
      if (response['statusCode'] >= 400) {
        talker.error('Server returned error: ${response['statusCode']}');
        talker.error('Error response data: ${response['data']}');
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
      talker.error('Failed to update user data: $e');
      throw Exception('Failed to update user data: $e');
    }
  }
}
