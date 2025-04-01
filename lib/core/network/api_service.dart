import 'package:dio/dio.dart';
import 'package:talker/talker.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/network/dio_client.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';

class ApiService {
  final DioClient dioClient;
  final Talker talker = Talker();

  ApiService(this.dioClient);

  Future<Map<String, String?>> _getAuthTokens() async {
    final prefs = getIt.get<SharedPrefsRepository>();
    return {
      'access_token': await prefs.getString('access_token'),
      'refresh_token': await prefs.getString('refresh_token'),
    };
  }

  Future<Map<String, dynamic>> getData(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final tokens = await _getAuthTokens();
      final mergedHeaders = {
        ...?headers,
        'Authorization': 'Bearer ${tokens['access_token']}',
      };

      talker.info('GET $path');
      final response = await dioClient.client.get(
        path,
        queryParameters: queryParams,
        options: Options(headers: mergedHeaders),
      );

      return {
        'data': response.data,
        'statusCode': response.statusCode,
        'statusMessage': response.statusMessage,
      };
    } on DioException catch (e) {
      talker.error('GET error: $e');
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> postData(
    String path,
    dynamic data, {
    bool useAuth = true,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final mergedHeaders = await _buildHeaders(useAuth, headers);
      talker.info('POST $path with data: $data');

      final response = await dioClient.client.post(
        path,
        data: data,
        options: Options(
          headers: mergedHeaders,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      return {
        'data': response.data,
        'statusCode': response.statusCode,
        'statusMessage': response.statusMessage,
      };
    } on DioException catch (e) {
      talker.error('POST error: $e');
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> patchData(
    String path,
    dynamic data, {
    bool useAuth = true,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final mergedHeaders = await _buildHeaders(useAuth, headers);
      talker.info('PATCH $path with data: $data');

      final response = await dioClient.client.patch(
        path,
        data: data,
        options: Options(
          headers: mergedHeaders,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      return {
        'data': response.data,
        'statusCode': response.statusCode,
        'statusMessage': response.statusMessage,
      };
    } on DioException catch (e) {
      talker.error('PATCH error: $e');
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> _buildHeaders(
    bool useAuth,
    Map<String, dynamic>? headers,
  ) async {
    if (!useAuth) return headers ?? {};

    final tokens = await _getAuthTokens();
    return {
      ...?headers,
      'Authorization': 'Bearer ${tokens['access_token']}',
    };
  }

  Map<String, dynamic> _handleDioError(DioException e) {
    return {
      'data': e.response?.data,
      'statusCode': e.response?.statusCode ?? 500,
      'statusMessage': e.response?.statusMessage ?? 'Unknown Error',
    };
  }

  Future<bool> refreshTokens() async {
    final prefs = getIt.get<SharedPrefsRepository>();
    final refreshToken = await prefs.getRefreshToken();

    if (refreshToken == null) {
      talker.error('Refresh token is null');
      return false;
    }

    try {
      final response = await dioClient.client.post(
        '/auth/jwt/refresh/',
        data: {'refresh': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        await prefs.setString('access_token', response.data['access']);
        await prefs.saveRefreshToken(response.data['refresh']);
        return true;
      } else {
        talker.error('Failed to refresh tokens: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      talker.error('Error refreshing tokens: $e');
      return false;
    }
  }
}