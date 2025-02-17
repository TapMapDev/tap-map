import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/src/features/registration/registration_response_model.dart';

abstract class RegistrationRepository {
  Future<RegistrationResponseModel> register(
      {required String email,
      required String password1,
      required String password2, 
      required String username,
      });
}

class RegistrationRepositoryImpl implements RegistrationRepository {
  final ApiService apiService;
  final prefs = getIt.get<SharedPrefsRepository>();
  RegistrationRepositoryImpl({required this.apiService});
  @override
  Future<RegistrationResponseModel> register(
      {required String username,
      required String email,
      required String password1,
      required String password2}) async {
    print(username);
    print(email);
    print(password1);
    print(password2);
    final response = await apiService.postData(
        '/auth/registration/',
        {'username': username,
          'email': email,
          'password1': password1,
          'password2': password2,
        },
        useAuth: false);
    final responseModel = RegistrationResponseModel.fromJson(
        response['data'], response['statusCode']);
    if (responseModel.accessToken != null &&
        responseModel.refreshToken != null) {
      await prefs.setString('access_token', responseModel.accessToken!);
      await prefs.setString('refresh_token', responseModel.refreshToken!);
    }
    return responseModel;
  }
}
