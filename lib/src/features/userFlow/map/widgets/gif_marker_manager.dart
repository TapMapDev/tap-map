import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:video_player/video_player.dart';

class GifMarkerManager extends StatefulWidget {
  final mapbox.MapboxMap mapboxMap;

  const GifMarkerManager({
    super.key,
    required this.mapboxMap,
  });

  @override
  State<GifMarkerManager> createState() => _GifMarkerManagerState();
}

class _GifMarkerManagerState extends State<GifMarkerManager>
    with WidgetsBindingObserver {
  final Map<String, _MarkerData> _markersById = {};
  bool _isDisposed = false;
  bool _isInitialized = false;
  Timer? _updatePositionsTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('🎬 GifMarkerManager: initState called');
    WidgetsBinding.instance.addObserver(this);
    _initialize();

    // Обновляем позиции маркеров при изменении камеры
    _updatePositionsTimer =
        Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && !_isDisposed) {
        _updateMarkerPositions();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('🎬 GifMarkerManager: AppLifecycleState changed to $state');
    if (state == AppLifecycleState.resumed) {
      // Приложение вернулось на передний план
      if (!_isInitialized && mounted && !_isDisposed) {
        debugPrint('🎬 GifMarkerManager: Reinitializing after resume');
        reinitialize();
      }
    }
  }

  // Публичный метод для принудительной переинициализации
  void reinitialize() {
    if (_isDisposed) return;
    _clearMarkers();
    _isInitialized = false;
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isDisposed || _isInitialized) return;

    try {
      debugPrint('🎬 GifMarkerManager: Initializing...');

      // Даем карте время загрузиться
      await Future.delayed(const Duration(seconds: 1));

      if (_isDisposed) return;

      // Создаем тестовый маркер с фиксированным URL
      debugPrint('🎬 GifMarkerManager: Creating test marker');
      await _createTestMarker();

      // Проверяем наличие слоя
      final layers = await widget.mapboxMap.style.getStyleLayers();
      final layerExists =
          layers.any((layer) => layer?.id == "places_symbol_layer");

      if (!layerExists) {
        debugPrint('❌ GifMarkerManager: places_symbol_layer not found');
        return;
      }

      // Получаем точки
      final features = await widget.mapboxMap.queryRenderedFeatures(
        mapbox.RenderedQueryGeometry(
          type: mapbox.Type.SCREEN_BOX,
          value: jsonEncode({
            "min": {"x": 0, "y": 0},
            "max": {"x": 10000, "y": 10000}
          }),
        ),
        mapbox.RenderedQueryOptions(
          layerIds: ["places_symbol_layer"],
          filter: null,
        ),
      );

      debugPrint('🎬 GifMarkerManager: Found ${features.length} features');

      if (features.isEmpty || _isDisposed) return;

      // Обрабатываем каждую точку
      for (final feature in features) {
        if (feature == null || _isDisposed) continue;

        final properties =
            feature.queriedFeature.feature as Map<dynamic, dynamic>;
        final id = properties['id']?.toString();

        if (id == null) continue;
        if (_markersById.containsKey(id)) continue;

        // Ищем URL видео
        String? videoUrl = _findVideoUrl(properties);

        if (videoUrl == null) continue;

        // Получаем координаты
        final geometry = properties['geometry'] as Map<dynamic, dynamic>?;
        if (geometry == null) continue;

        final coordinates = geometry['coordinates'] as List?;
        if (coordinates == null || coordinates.length < 2) continue;

        // Создаем маркер
        await _createVideoMarker(id, coordinates, videoUrl);
      }

      _isInitialized = true;
      debugPrint(
          '✅ GifMarkerManager: Initialization complete with ${_markersById.length} markers');
    } catch (e) {
      debugPrint('❌ GifMarkerManager: Error initializing: $e');
    }
  }

  String? _findVideoUrl(Map<dynamic, dynamic> properties) {
    // Проверяем все возможные места, где может быть URL видео
    final nestedProperties = properties['properties'] as Map<dynamic, dynamic>?;

    debugPrint('🎬 GifMarkerManager: Searching for video URL in properties');

    // Проверяем корневые свойства
    for (final key in [
      'marker_type',
      'markerType',
      'marker_url',
      'markerUrl',
      'video_url',
      'videoUrl',
      'url'
    ]) {
      final value = properties[key]?.toString();
      if (value != null &&
          (value.endsWith('.webm') || value.endsWith('.gif'))) {
        debugPrint(
            '🎬 GifMarkerManager: Found URL in root properties: $key = $value');
        return value;
      }
    }

    // Проверяем вложенные свойства
    if (nestedProperties != null) {
      for (final key in [
        'marker_type',
        'markerType',
        'marker_url',
        'markerUrl',
        'video_url',
        'videoUrl',
        'url'
      ]) {
        final value = nestedProperties[key]?.toString();
        if (value != null &&
            (value.endsWith('.webm') || value.endsWith('.gif'))) {
          debugPrint(
              '🎬 GifMarkerManager: Found URL in nested properties: $key = $value');
          return value;
        }
      }
    }

    // Рекурсивно ищем в любых вложенных объектах
    String? searchInObject(dynamic obj, String path) {
      if (obj is String && (obj.endsWith('.webm') || obj.endsWith('.gif'))) {
        debugPrint('🎬 GifMarkerManager: Found URL in path $path: $obj');
        return obj;
      } else if (obj is Map) {
        for (final entry in obj.entries) {
          final result = searchInObject(entry.value, '$path.${entry.key}');
          if (result != null) return result;
        }
      } else if (obj is List) {
        for (var i = 0; i < obj.length; i++) {
          final result = searchInObject(obj[i], '$path[$i]');
          if (result != null) return result;
        }
      }
      return null;
    }

    final result = searchInObject(properties, 'root');
    if (result != null) {
      return result;
    }

    debugPrint('🎬 GifMarkerManager: No video URL found in properties');
    return null;
  }

  @override
  void didUpdateWidget(GifMarkerManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('🎬 GifMarkerManager: didUpdateWidget called');
    if (oldWidget.mapboxMap != widget.mapboxMap) {
      debugPrint(
          '🎬 GifMarkerManager: MapboxMap instance changed, reinitializing');
      _clearMarkers();
      _isInitialized = false;
      _initialize();
    } else if (!_isInitialized) {
      // Если виджет обновился, но маркеры не инициализированы, попробуем инициализировать
      debugPrint(
          '🎬 GifMarkerManager: Widget updated but not initialized, trying to initialize');
      _initialize();
    }
  }

  void _clearMarkers() {
    debugPrint('🎬 GifMarkerManager: Clearing ${_markersById.length} markers');
    for (final markerData in _markersById.values) {
      markerData.controller.dispose();
    }
    _markersById.clear();
  }

  @override
  void dispose() {
    debugPrint('🎬 GifMarkerManager: dispose called');
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _updatePositionsTimer?.cancel();
    _clearMarkers();
    super.dispose();
  }

  Future<void> _createVideoMarker(
      String id, List coordinates, String videoUrl) async {
    if (_isDisposed) return;

    debugPrint(
        '🎬 GifMarkerManager ✅: Creating marker $id with URL: $videoUrl');

    try {
      // Создаем контроллер видео
      final controller = VideoPlayerController.network(videoUrl);

      // Устанавливаем таймаут для инициализации
      bool initialized = false;
      Timer? timeoutTimer;

      timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (!initialized && !_isDisposed) {
          debugPrint(
              '❌ GifMarkerManager: Video initialization timeout for $videoUrl');
          controller.dispose();
        }
      });

      try {
        await controller.initialize();
        initialized = true;
        timeoutTimer.cancel();
      } catch (e) {
        debugPrint('❌ GifMarkerManager: Failed to initialize video: $e');
        controller.dispose();
        return;
      }

      if (_isDisposed) {
        controller.dispose();
        return;
      }

      controller.setLooping(true);
      controller.setVolume(0.0);
      await controller.play();

      if (_isDisposed) {
        controller.dispose();
        return;
      }

      // Добавляем маркер в список
      final screenPoint = await _getScreenPoint(coordinates);

      setState(() {
        _markersById[id] = _MarkerData(
          controller: controller,
          coordinates: [coordinates[0] as double, coordinates[1] as double],
          screenPoint: screenPoint,
        );
      });

      debugPrint('✅ GifMarkerManager: Successfully created marker $id');
    } catch (e) {
      debugPrint('❌ GifMarkerManager: Error creating marker: $e');
    }
  }

  // Получаем координаты на экране для заданных географических координат
  Future<Offset?> _getScreenPoint(List coordinates) async {
    try {
      final point = mapbox.Point(
        coordinates: mapbox.Position(
          coordinates[0] as double,
          coordinates[1] as double,
        ),
      );

      final screenCoordinate = await widget.mapboxMap.pixelForCoordinate(point);
      return Offset(screenCoordinate.x, screenCoordinate.y);
    } catch (e) {
      debugPrint('❌ GifMarkerManager: Error getting screen point: $e');
      return null;
    }
  }

  // Обновляем позиции всех маркеров при изменении камеры
  Future<void> _updateMarkerPositions() async {
    if (_isDisposed || _markersById.isEmpty) return;

    final updatedMarkers = <String, _MarkerData>{};

    for (final entry in _markersById.entries) {
      final id = entry.key;
      final markerData = entry.value;

      final screenPoint = await _getScreenPoint(
          [markerData.coordinates[0], markerData.coordinates[1]]);

      updatedMarkers[id] = _MarkerData(
        controller: markerData.controller,
        coordinates: markerData.coordinates,
        screenPoint: screenPoint,
      );
    }

    if (mounted && !_isDisposed) {
      setState(() {
        _markersById.clear();
        _markersById.addAll(updatedMarkers);
      });
    }
  }

  // Создаем тестовый маркер с фиксированным URL
  Future<void> _createTestMarker() async {
    if (_isDisposed) return;

    // Тестовый URL для GIF/WebM
    const testUrl =
        'https://media.giphy.com/media/3o7TKSjRrfIPjeiVyM/giphy.gif';

    // Центр карты
    final cameraPosition = await widget.mapboxMap.getCameraState();
    final coordinates = [
      cameraPosition.center.coordinates[0],
      cameraPosition.center.coordinates[1]
    ];

    debugPrint(
        '🎬 GifMarkerManager: Creating test marker at $coordinates with URL: $testUrl');

    await _createVideoMarker('test_marker', coordinates, testUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final entry in _markersById.entries)
          if (entry.value.screenPoint != null)
            Positioned(
              left: entry.value.screenPoint!.dx - 30, // Центрируем маркер
              top: entry.value.screenPoint!.dy - 30, // Центрируем маркер
              child: SizedBox(
                width: 60,
                height: 60,
                child: VideoPlayer(entry.value.controller),
              ),
            ),
      ],
    );
  }
}

class _MarkerData {
  final VideoPlayerController controller;
  final List<double> coordinates;
  final Offset? screenPoint;

  _MarkerData({
    required this.controller,
    required this.coordinates,
    this.screenPoint,
  });
}
