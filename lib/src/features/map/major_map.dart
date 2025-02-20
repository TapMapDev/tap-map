import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MajorMap extends StatefulWidget {
  const MajorMap({super.key});

  @override
  State<MajorMap> createState() => _MajorMapState();
}

class _MajorMapState extends State<MajorMap> {
  mp.MapboxMap? mapboxMapController;
  StreamSubscription? userPositionStream;

  @override
  void initState() {
    _setupPositionTracking();
    super.initState();
  }

  @override
  void dispose() {
    userPositionStream?.cancel();
    super.dispose();
  }

  void _onStyleLoadedCallback(StyleLoadedEventData data) async {
    // Добавляем векторный источник данных
    await mapboxMapController?.style.addSource(mp.VectorSource(
      id: "places_source",
      tiles: ["https://map-travel.net/tilesets/data/tiles/{z}/{x}/{y}.pbf"],
      minzoom: 0,
      maxzoom: 20,
    ));

    // Добавляем слой кругов (CircleLayer)
    await mapboxMapController?.style.addLayer(mp.CircleLayer(
      id: "places_circle_layer",
      sourceId: "places_source",
      sourceLayer: "mylayer",
      circleRadius: 3.0, // Размер круга
      circleOpacity: 0.8, // Прозрачность
      circleStrokeWidth: 1.0, // Обводка // Белая обводка
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          mp.MapWidget(
              styleUri: mp.MapboxStyles.MAPBOX_STREETS,
              cameraOptions: mp.CameraOptions(
                center: mp.Point(coordinates: mp.Position(98.360473, 7.886778)),
                zoom: 11.0,
              ),
              onMapCreated: _onMapCreated,
              onStyleLoadedListener: _onStyleLoadedCallback),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _centerOnUserLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

// создание карты
  void _onMapCreated(mp.MapboxMap controller) {
    setState(() {
      mapboxMapController = controller;
    });

    mapboxMapController?.location.updateSettings(
      mp.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ),
    );
  }
// метка геопозиции

  Future<void> _setupPositionTracking() async {
    bool serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    gl.LocationPermission permission = await gl.Geolocator.checkPermission();
    if (permission == gl.LocationPermission.denied) {
      permission = await gl.Geolocator.requestPermission();
      if (permission == gl.LocationPermission.denied ||
          permission == gl.LocationPermission.deniedForever) {
        return;
      }
    }

    gl.Position position = await gl.Geolocator.getCurrentPosition();
    _moveCameraToPosition(position);
  }

  Future<void> _centerOnUserLocation() async {
    gl.LocationPermission permission = await gl.Geolocator.checkPermission();
    if (permission == gl.LocationPermission.denied ||
        permission == gl.LocationPermission.deniedForever) {
      permission = await gl.Geolocator.requestPermission();
      if (permission == gl.LocationPermission.denied) {
        return;
      }
    }

    gl.Position position = await gl.Geolocator.getCurrentPosition();
    _moveCameraToPosition(position);
  }
// центрирование на геопозицию при разрешении пользователя
  void _moveCameraToPosition(gl.Position position) {
    if (mapboxMapController != null) {
      mapboxMapController?.setCamera(mp.CameraOptions(
        zoom: 14,
        center: mp.Point(
          coordinates: mp.Position(position.longitude, position.latitude),
        ),
      ));
    }
  }
// разрешение на геолокацию
}
