import 'package:dio/dio.dart';

class DioClient {
  Dio dio;

  DioClient()
      : dio = Dio(BaseOptions(
          // baseUrl: 'http://srv674948.hstgr.cloud:80/api/v1/',
          baseUrl: 'https://api.tap-map.net/api',
          connectTimeout: const Duration(milliseconds: 5000),
          receiveTimeout: const Duration(milliseconds: 3000),
          headers: {
            'Content-Type': 'application/json',
          },
        ));

  Dio get client => dio;
}
