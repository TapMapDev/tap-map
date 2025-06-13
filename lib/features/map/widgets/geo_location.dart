import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
import 'package:tap_map/features/map/widgets/location_service.dart';

class GeoLocationButton extends StatelessWidget {
  final mp.MapboxMap? mapboxMapController;

  const GeoLocationButton({super.key, required this.mapboxMapController});

  Future<void> _centerOnUserLocation(BuildContext context) async {
    if (mapboxMapController == null) {
      return;
    }

    final position = await LocationService.getUserPosition();
    if (position != null) {
      _moveCameraToPosition(position);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось получить геопозицию')),
      );
    }
  }

  void _moveCameraToPosition(gl.Position position) async {
    if (mapboxMapController == null) return;

    await mapboxMapController?.setCamera(
      mp.CameraOptions(
        zoom: 14,
        center: mp.Point(
          coordinates: mp.Position(position.longitude, position.latitude),
        ),
      ),
    );
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
          Icons.my_location,
          color: Colors.black,
          size: 20,
        ),
      ),
    );
  }
}
