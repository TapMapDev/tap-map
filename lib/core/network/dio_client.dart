import 'package:dio/dio.dart';

class DioClient {
  Dio dio;

  DioClient()
      : dio = Dio(BaseOptions(
          baseUrl: 'https://api.tap-map.net/api',
          connectTimeout: const Duration(milliseconds: 5000),
          receiveTimeout: const Duration(milliseconds: 3000),
          headers: {
            'Content-Type': 'application/json',
          },
        ));

  Dio get client => dio;
}
