import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
import 'package:tap_map/src/features/userFlow/map/widgets/location_service.dart';

class GeoLocationButton extends StatelessWidget {
  final mp.MapboxMap? mapboxMapController;

  const GeoLocationButton({super.key, required this.mapboxMapController});

  Future<void> _centerOnUserLocation(BuildContext context) async {
    if (mapboxMapController == null) {
      debugPrint("❌ Ошибка: Контроллер карты не инициализирован.");
      return;
    }

    final position = await LocationService.getUserPosition();
    if (position != null) {
      debugPrint("📍 Центрируем карту на позиции: ${position.latitude}, ${position.longitude}");
      _moveCameraToPosition(position);
    } else {
      debugPrint("❌ Не удалось получить текущую позицию.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось получить геопозицию')),
      );
    }
  }

  void _moveCameraToPosition(gl.Position position) async {
    if (mapboxMapController == null) return;

    try {
      await mapboxMapController?.setCamera(
        mp.CameraOptions(
          zoom: 14,
          center: mp.Point(
            coordinates: mp.Position(position.longitude, position.latitude),
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Ошибка обновления камеры: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _centerOnUserLocation(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.my_location, // Изменил иконку для центрирования
          color: Colors.black,
          size: 20,
        ),
      ),
    );
  }
}