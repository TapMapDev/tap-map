import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;

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
    // _setupPositionTracking();
  }

  @override
  void dispose() {
    userPositionStream?.cancel();
    super.dispose();
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
      ),
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
    _addCustomTileSet();
  }

  Future<void> _addCustomTileSet() async {
    if (mapboxMapController == null) return;

    // Добавляем источник с Mapbox tileset
    await mapboxMapController!.style.addSource(
      mp.VectorSource(
        id: "custom_tileset",
        url: "mapbox://map23travel.09pa574p", // Ваш tileset из Mapbox
      ),
    );

    await mapboxMapController!.style.addLayer(
      mp.FillLayer(
        id: "custom_layer",
        sourceId: "custom_tileset",
        sourceLayer:
            "second", // Название слоя из Mapbox, укажите правильное имя слоя
        fillColor: Colors.blue.value,
        fillOpacity: 0.5,
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

    gl.LocationSettings locationSettings = gl.LocationSettings(
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
