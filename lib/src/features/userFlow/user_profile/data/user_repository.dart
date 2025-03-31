import 'dart:convert';

import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/src/features/userFlow/user_profile/model/user_response_model.dart';

abstract class IUserRepository {
  Future<UserModel> getCurrentUser();
  Future<UserModel> updateUser(UserModel user);
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
      final response = await apiService.postData('/users/me/', body);

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
}
