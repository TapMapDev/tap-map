import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/src/features/auth/model/authorization_response_model.dart';

class AuthorizationRepositoryImpl {
  final ApiService apiService;
  final prefs = getIt.get<SharedPrefsRepository>();
  AuthorizationRepositoryImpl({required this.apiService});

  Future<AuthorizationResponseModel> authorize({
    required String login,
    required String password,
  }) async {
    final response = await apiService.postData(
        '/auth/token/login/',
        {
          'login': login,
          'password': password,
        },
        useAuth: false);

    final responseModel = AuthorizationResponseModel.fromJson(
        response['data'], response['statusCode']);

    if (responseModel.accessToken != null &&
        responseModel.refreshToken != null) {
      await prefs.saveAccessToken(responseModel.accessToken!);
      await prefs.saveRefreshToken(responseModel.refreshToken!);
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
    try {
      // 1. Делаем POST-запрос на логаут
      //    Тело запроса не требуется, можем передавать пустой объект {} или null
      final response = await apiService.postData(
        '/api/users/sessions/logout/',
        {},
        useAuth: true, // передаём заголовок Authorization
      );

      final statusCode = response['statusCode'] as int?;

      // 2. Проверяем ответ
      if (statusCode != null && (statusCode == 200 || statusCode == 204)) {
        // Успешно логаут
        // Можно вывести лог, если нужно
      } else {
        // Сервер вернул ошибку
        // Можно кинуть Exception, чтобы поймать в Bloc, но чаще логаут
        // делается принудительно (не важно, что вернул сервер).
        // throw Exception('Ошибка логаута: ${response['data']}');
      }
    } catch (e) {
      // 3. Обработка любых ошибок Dio/сети
      //    Мы всё равно чистим локальные токены,
      //    потому что клиент всё равно «забывает» локальную сессию
      // print('Ошибка: $e'); // или throw
    }

    // 4. В любом случае чистим локальные токены
    await prefs.deleteKey('access_token');
    await prefs.deleteKey('refresh_token');
  }
}
