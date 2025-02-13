import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker/talker.dart';
import 'package:tap_map/core/di/di.dart';

class SharedPrefsRepository {
  // Метод для получения строки по ключу
  Future<String?> getString(String key) async {
    try {
      getIt.get<Talker>().info("Fetching string for key: $key");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final result = prefs.getString(key);
      getIt.get<Talker>().info("Received string for key: $key: $result");
      return result;
    } catch (e) {
      getIt
          .get<Talker>()
          .error("Error in getString with key: $key, exception: $e");
      throw Exception("Error in getString with key: $key, exception: $e");
    }
  }

  // Метод для сохранения строки по ключу
  Future<void> setString(String key, String value) async {
    try {
      getIt.get<Talker>().info("Saving string with key: $key, value: $value");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      getIt.get<Talker>().info("Saved string with key: $key, value: $value");
    } catch (e) {
      getIt.get<Talker>().error(
          "Error in setString with key: $key, value: $value, exception: $e");
      throw Exception(
          "Error in setString with key: $key, value: $value, exception: $e");
    }
  }

  // Метод для удаления строки по ключу
  Future<void> deleteString(String key) async {
    try {
      getIt.get<Talker>().info("Deleting string for key: $key");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      getIt.get<Talker>().info("Deleted string for key: $key");
    } catch (e) {
      getIt
          .get<Talker>()
          .error("Error in deleteString with key: $key, exception: $e");
      throw Exception("Error in deleteString with key: $key, exception: $e");
    }
  }

  // Метод для получения целого числа по ключу
  Future<int?> getInt(String key) async {
    try {
      getIt.get<Talker>().info("Fetching int for key: $key");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final result = prefs.getInt(key);
      getIt.get<Talker>().info("Received int for key: $key: $result");
      return result;
    } catch (e) {
      getIt
          .get<Talker>()
          .error("Error in getInt with key: $key, exception: $e");
      throw Exception("Error in getInt with key: $key, exception: $e");
    }
  }

  // Метод для сохранения целого числа по ключу
  Future<void> setInt(String key, int value) async {
    try {
      getIt.get<Talker>().info("Saving int with key: $key, value: $value");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
      getIt.get<Talker>().info("Saved int with key: $key, value: $value");
    } catch (e) {
      getIt.get<Talker>().error(
          "Error in setInt with key: $key, value: $value, exception: $e");
      throw Exception(
          "Error in setInt with key: $key, value: $value, exception: $e");
    }
  }

  // Метод для получения логического значения по ключу
  Future<bool?> getBool(String key) async {
    try {
      getIt.get<Talker>().info("Fetching bool for key: $key");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final result = prefs.getBool(key);
      getIt.get<Talker>().info("Received bool for key: $key: $result");
      return result;
    } catch (e) {
      getIt
          .get<Talker>()
          .error("Error in getBool with key: $key, exception: $e");
      throw Exception("Error in getBool with key: $key, exception: $e");
    }
  }

  // Метод для сохранения логического значения по ключу
  Future<void> setBool(String key, bool value) async {
    try {
      getIt.get<Talker>().info("Saving bool with key: $key, value: $value");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      getIt.get<Talker>().info("Saved bool with key: $key, value: $value");
    } catch (e) {
      getIt.get<Talker>().error(
          "Error in setBool with key: $key, value: $value, exception: $e");
      throw Exception(
          "Error in setBool with key: $key, value: $value, exception: $e");
    }
  }

  // Метод для получения значения типа double по ключу
  Future<double?> getDouble(String key) async {
    try {
      getIt.get<Talker>().info("Fetching double for key: $key");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final result = prefs.getDouble(key);
      getIt.get<Talker>().info("Received double for key: $key: $result");
      return result;
    } catch (e) {
      getIt
          .get<Talker>()
          .error("Error in getDouble with key: $key, exception: $e");
      throw Exception("Error in getDouble with key: $key, exception: $e");
    }
  }

  // Метод для сохранения значения типа double по ключу
  Future<void> setDouble(String key, double value) async {
    try {
      getIt.get<Talker>().info("Saving double with key: $key, value: $value");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(key, value);
      getIt.get<Talker>().info("Saved double with key: $key, value: $value");
    } catch (e) {
      getIt.get<Talker>().error(
          "Error in setDouble with key: $key, value: $value, exception: $e");
      throw Exception(
          "Error in setDouble with key: $key, value: $value, exception: $e");
    }
  }

  // Метод для получения списка строк по ключу
  Future<List<String>?> getStringList(String key) async {
    try {
      getIt.get<Talker>().info("Fetching string list for key: $key");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final result = prefs.getStringList(key);
      getIt.get<Talker>().info("Received string list for key: $key: $result");
      return result;
    } catch (e) {
      getIt
          .get<Talker>()
          .error("Error in getStringList with key: $key, exception: $e");
      throw Exception("Error in getStringList with key: $key, exception: $e");
    }
  }

  // Метод для сохранения списка строк по ключу
  Future<void> setStringList(String key, List<String> value) async {
    try {
      getIt
          .get<Talker>()
          .info("Saving string list with key: $key, value: $value");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, value);
      getIt
          .get<Talker>()
          .info("Saved string list with key: $key, value: $value");
    } catch (e) {
      getIt.get<Talker>().error(
          "Error in setStringList with key: $key, value: $value, exception: $e");
      throw Exception(
          "Error in setStringList with key: $key, value: $value, exception: $e");
    }
  }

  // Метод для удаления значения по ключу
  Future<void> deleteKey(String key) async {
    try {
      getIt.get<Talker>().info("Deleting key: $key");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      getIt.get<Talker>().info("Deleted key: $key");
    } catch (e) {
      getIt
          .get<Talker>()
          .error("Error in deleteKey with key: $key, exception: $e");
      throw Exception("Error in deleteKey with key: $key, exception: $e");
    }
  }

  // Метод для очистки всех данных из SharedPreferences
  Future<void> clear() async {
    try {
      getIt.get<Talker>().info("Clearing all data from SharedPreferences");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      getIt.get<Talker>().info("All data cleared from SharedPreferences");
    } catch (e) {
      getIt.get<Talker>().error("Error in clear, exception: $e");
      throw Exception("Error in clear, exception: $e");
    }
  }
}
