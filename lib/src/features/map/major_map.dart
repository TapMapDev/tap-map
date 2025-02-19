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
      circleRadius: 6.0, // Размер круга
      circleOpacity: 0.8, // Прозрачность
      circleStrokeWidth: 1.0, // Обводка // Белая обводка
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: mp.MapWidget(
          styleUri: mp.MapboxStyles.MAPBOX_STREETS,
          cameraOptions: mp.CameraOptions(
            center: mp.Point(coordinates: mp.Position(98.360473, 7.886778)),
            zoom: 11.0,
          ),
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoadedCallback),
    );
  }

  void _onMapCreated(mp.MapboxMap controller) {
    setState(() {
      mapboxMapController = controller;
    });

    // Включаем отображение местоположения
    mapboxMapController?.location.updateSettings(
      mp.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ),
    );
  }

  Future<void> _setupPositionTracking() async {
    bool serviceEnabled;
    gl.LocationPermission permission;

    serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await gl.Geolocator.checkPermission();
    if (permission == gl.LocationPermission.denied) {
      permission = await gl.Geolocator.requestPermission();
      if (permission == gl.LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == gl.LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    gl.LocationSettings locationSettings = const gl.LocationSettings(
      accuracy: gl.LocationAccuracy.high,
      distanceFilter: 100,
    );

    userPositionStream?.cancel();
    userPositionStream =
        gl.Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((gl.Position? position) {
      if (position != null && mapboxMapController != null) {
        mapboxMapController?.setCamera(mp.CameraOptions(
          zoom: 12,
          center: mp.Point(
            coordinates: mp.Position(
              position.latitude,
              position.longitude,
            ),
          ),
        ));
      }
    });
  }
}
