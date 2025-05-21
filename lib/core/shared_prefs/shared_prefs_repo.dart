import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker/talker.dart';
import 'package:tap_map/core/di/di.dart';

class SharedPrefsRepository {
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenKey = 'access_token';
  static const String _mapStyleKey = 'selected_map_style';
  static const String _mapStyleIdKey = 'selected_map_style_id';
  static const String _deviceTokenIdKey = 'device_token_id';
  final Talker talker = getIt.get<Talker>();

  static const String _iconsCacheKey = 'icons_cache_map';

  /// Получаем текущую карту иконок из SharedPreferences
  Future<Map<String, String>> _getIconsCacheMap() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_iconsCacheKey);
    if (jsonString == null) {
      return {};
    }
    final Map<String, dynamic> decoded = json.decode(jsonString);
    return decoded.map((key, value) => MapEntry(key, value as String));
  }

  Future<void> _saveIconsCacheMap(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(map);
    await prefs.setString(_iconsCacheKey, jsonString);
  }

  /// Сохраняем (или обновляем) иконку в кэше
  Future<void> saveIconBytes(String iconName, Uint8List bytes) async {
    // Преобразуем байты в base64
    final base64Data = base64Encode(bytes);

    // Получаем текущую карту иконок
    final cacheMap = await _getIconsCacheMap();
    // Обновляем запись
    cacheMap[iconName] = base64Data;
    // Сохраняем карту обратно
    await _saveIconsCacheMap(cacheMap);
  }

  /// Получаем иконку (как байты) по имени из кэша (если есть)
  Future<Uint8List?> getIconBytes(String iconName) async {
    final cacheMap = await _getIconsCacheMap();
    final base64Data = cacheMap[iconName];
    if (base64Data == null) {
      return null; // Нет в кэше
    }
    return base64Decode(base64Data);
  }

  /// Удаляем иконку из кэша
  Future<void> removeIcon(String iconName) async {
    final cacheMap = await _getIconsCacheMap();
    if (cacheMap.containsKey(iconName)) {
      cacheMap.remove(iconName);
      await _saveIconsCacheMap(cacheMap);
    }
  }

  /// Полная очистка кэша иконок
  Future<void> clearIconsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_iconsCacheKey);
  }

  // ✅ Универсальный метод для сохранения строки
  Future<void> setString(String key, String value) async {
    try {
      talker.info('Saving string with key: $key, value: $value');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      talker.info('Saved string with key: $key');
    } catch (e) {
      talker.error('Error saving string with key: $key, exception: $e');
      throw Exception('Error saving string with key: $key, exception: $e');
    }
  }

  // ✅ Универсальный метод для получения строки
  Future<String?> getString(String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final result = prefs.getString(key);
      talker.info('Received string for key: $key: $result');
      return result;
    } catch (e) {
      talker.error('Error fetching string with key: $key, exception: $e');
      throw Exception('Error fetching string with key: $key, exception: $e');
    }
  }

  // ✅ Универсальный метод для удаления ключа
  Future<void> deleteKey(String key) async {
    try {
      talker.info('Deleting key: $key');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      talker.info('Deleted key: $key');
    } catch (e) {
      talker.error('Error deleting key: $key, exception: $e');
      throw Exception('Error deleting key: $key, exception: $e');
    }
  }

  // // ✅ Методы для refresh_token
  Future<void> saveRefreshToken(String token) =>
      setString(_refreshTokenKey, token);
  Future<String?> getRefreshToken() => getString(_refreshTokenKey);
  Future<void> deleteRefreshToken() => deleteKey(_refreshTokenKey);

  // ✅ Методы для access_token
  Future<void> saveAccessToken(String token) =>
      setString(_accessTokenKey, token);
  Future<String?> getAccessToken() => getString(_accessTokenKey);
  Future<void> deleteAccessToken() => deleteKey(_accessTokenKey);

  // ✅ Очистка всех данных
  Future<void> clear() async {
    try {
      talker.info('Clearing all data from SharedPreferences');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      talker.info('All data cleared from SharedPreferences');
    } catch (e) {
      talker.error('Error in clear, exception: $e');
      throw Exception('Error in clear, exception: $e');
    }
  }

  Future<void> saveMapStyle(String styleUri) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mapStyleKey, styleUri);
    } catch (e) {
      throw Exception('Ошибка сохранения стиля карты: $e');
    }
  }

  /// ✅ Получение сохранённого стиля карты
  Future<String?> getSavedMapStyle() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(_mapStyleKey);
    } catch (e) {
      throw Exception('Ошибка загрузки сохранённого стиля карты: $e');
    }
  }

  Future<void> saveMapStyleId(int styleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mapStyleIdKey, styleId);
  }

  Future<int?> getMapStyleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_mapStyleIdKey);
  }

  /// Сохраняем шрифт пользователя
  Future<void> saveSelectedFont(String fontName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFontName', fontName);
  }

  /// Получаем сохранённый шрифт
  Future<String?> getSelectedFont() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedFontName');
  }

  // Методы для device_token_id
  Future<void> saveDeviceTokenId(String tokenId) async {
    try {
      talker.info('Saving device token ID: $tokenId');
      await setString(_deviceTokenIdKey, tokenId);
      talker.info('Device token ID saved successfully');
    } catch (e) {
      talker.error('Error saving device token ID: $e');
      rethrow;
    }
  }

  Future<String?> getDeviceTokenId() async {
    try {
      final tokenId = await getString(_deviceTokenIdKey);
      talker.info(
          'Retrieved device token ID: ${tokenId != null ? 'exists' : 'null'}');
      return tokenId;
    } catch (e) {
      talker.error('Error getting device token ID: $e');
      rethrow;
    }
  }

  Future<void> deleteDeviceTokenId() async {
    try {
      talker.info('Deleting device token ID');
      await deleteKey(_deviceTokenIdKey);
      talker.info('Device token ID deleted successfully');
    } catch (e) {
      talker.error('Error deleting device token ID: $e');
      rethrow;
    }
  }
}
