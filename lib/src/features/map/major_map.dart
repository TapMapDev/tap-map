import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MajorMap extends StatefulWidget {
  const MajorMap({super.key});

  @override
  State<MajorMap> createState() => _MajorMapState();
}

class _MajorMapState extends State<MajorMap> {
  MapboxMap? mapboxMap;
  final Random _random = Random();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildMap(),
    );
  }

  Widget _buildMap() {
    return MapWidget(
      key: const ValueKey("mapWidget"),
      styleUri: MapboxStyles.MAPBOX_STREETS,
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(98.360473, 7.886778)),
        zoom: 11.0,
      ),
      onMapCreated: (controller) {
        mapboxMap = controller;
        _initializeMap();
      },
    );
  }

  /// 🚀 Инициализация карты
  void _initializeMap() {
    _addVectorTileSource();
    _addCustomMarkers(); // 🔥 Добавляем 30 точек
  }

  /// 📌 Добавляем 30 кастомных меток
  Future<void> _addCustomMarkers() async {
    if (mapboxMap == null) return;

    final annotationManager = await mapboxMap!.annotations.createPointAnnotationManager();

    try {
      ByteData byteData = await rootBundle.load('assets/png/location_pin.png');
      Uint8List imageData = byteData.buffer.asUint8List();

      var options = <PointAnnotationOptions>[];
      for (var i = 0; i < 30; i++) {
        options.add(PointAnnotationOptions(
          geometry: Point.fromJson(_createRandomPhuketPoint().toJson()),
          image: imageData,
        ));
      }

      annotationManager.createMulti(options);
      debugPrint("✅ 30 меток успешно добавлены на Пхукет!");
    } catch (e) {
      debugPrint("❌ Ошибка загрузки иконки: $e");
    }
  }

  /// 📌 Генерация случайной точки на острове Пхукет
  Point _createRandomPhuketPoint() {
    double lat = 7.80 + _random.nextDouble() * (8.20 - 7.80);
    double lon = 98.25 + _random.nextDouble() * (98.50 - 98.25);
    return Point(coordinates: Position(lon, lat));
  }

  /// 🗺️ Добавляем source и слои
  Future<void> _addVectorTileSource() async {
    const sourceId = "custom-tileset-source";
    const tilesetUrl =
        'https://map-travel.net/tilesets/data/tiles/{z}/{x}/{y}.pbf';

    await _checkTileAvailability();

    mapboxMap?.style
        .addSource(VectorSource(
      id: sourceId,
      tiles: [tilesetUrl],
      minzoom: 0,
      maxzoom: 22,
    ))
        .then((_) {
      _addLayers(sourceId);
    }).catchError((error) {
      debugPrint('❌ Ошибка добавления source: $error');
    });
  }

  /// 📌 Добавляем слои на карту
  void _addLayers(String sourceId) {
    final layers = [
      'contour',
      'transportation',
      'water',
      'landcover',
      'landuse',
      'poi'
    ];

    for (var layer in layers) {
      _addLayer(sourceId, layer);
    }
  }

  void _addLayer(String sourceId, String layerName) {
    try {
      mapboxMap?.style.addLayer(LineLayer(
        id: 'debug-line-$layerName',
        sourceId: sourceId,
        sourceLayer: layerName,
        lineColor: Colors.blue.value,
        lineWidth: 2.0,
      ));
    } catch (e) {
      debugPrint('❌ Ошибка добавления слоя $layerName: $e');
    }
  }

  /// 🔍 Проверяем доступность тайлов
  Future<void> _checkTileAvailability() async {
    final testTiles = [
      'https://map-travel.net/tilesets/data/tiles/11/1586/978.pbf',
      'https://map-travel.net/tilesets/data/tiles/10/793/489.pbf'
    ];

    for (var tileUrl in testTiles) {
      try {
        final response = await http.get(Uri.parse(tileUrl));
        debugPrint(
            '🌐 Проверка тайла: $tileUrl | Статус: ${response.statusCode}');
      } catch (e) {
        debugPrint('❌ Ошибка загрузки тайла $tileUrl: $e');
      }
    }
  }
}