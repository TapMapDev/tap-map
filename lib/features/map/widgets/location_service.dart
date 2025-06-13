import 'package:geolocator/geolocator.dart' as gl;

class LocationService {
  static Future<gl.Position?> getUserPosition() async {
    // Проверка доступности сервиса геолокации
    if (!await gl.Geolocator.isLocationServiceEnabled()) return null;

    // Проверка и запрос разрешений
    gl.LocationPermission permission = await gl.Geolocator.checkPermission();
    if (permission == gl.LocationPermission.denied) {
      permission = await gl.Geolocator.requestPermission();
      if (permission == gl.LocationPermission.denied ||
          permission == gl.LocationPermission.deniedForever) {
        return null;
      }
    }

    // Получение текущей позиции
    return await gl.Geolocator.getCurrentPosition();
  }
}
