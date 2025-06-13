import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Конфигурация авторизации через социальные сети
class AuthConfig {
  /// Получить Client ID для Google авторизации
  static String get googleClientId => 
      dotenv.env['GOOGLE_CLIENT_ID'] ?? '';

  /// Получить Client Secret для Google авторизации
  static String get googleClientSecret => 
      dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';
      
  /// Получить Web Client ID для Google авторизации на Android
  static String get googleWebClientId => 
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

  /// Получить App ID для Facebook авторизации
  static String get facebookAppId => 
      dotenv.env['FACEBOOK_APP_ID'] ?? '';

  /// Получить Client Token для Facebook авторизации
  static String get facebookClientToken => 
      dotenv.env['FACEBOOK_CLIENT_TOKEN'] ?? '';
}
