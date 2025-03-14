import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:video_player/video_player.dart';

// Глобальная переменная для контроля вывода логов
bool _enableDetailedLogs = false;

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
  mapbox.CameraState? _lastCameraPosition;
  int _frameSkipCounter = 0;
  final int _frameSkipThreshold = 3; // Обновлять каждый 3-й кадр

  @override
  void initState() {
    super.initState();
    if (_enableDetailedLogs) {
      debugPrint('🎬 GifMarkerManager: initState called');
    }
    WidgetsBinding.instance.addObserver(this);
    _initialize();

    // Уменьшаем частоту обновления позиций маркеров для снижения нагрузки
    _updatePositionsTimer =
        Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && !_isDisposed) {
        _updateMarkerPositions();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_enableDetailedLogs) {
      debugPrint('🎬 GifMarkerManager: AppLifecycleState changed to $state');
    }
    if (state == AppLifecycleState.resumed) {
      // Приложение вернулось на передний план
      if (!_isInitialized && mounted && !_isDisposed) {
        if (_enableDetailedLogs) {
          debugPrint('🎬 GifMarkerManager: Reinitializing after resume');
        }
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
      if (_enableDetailedLogs) {
        debugPrint('🎬 GifMarkerManager: Initializing...');
      }

      // Даем карте время загрузиться
      await Future.delayed(const Duration(seconds: 1));

      if (_isDisposed) return;

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

      if (_enableDetailedLogs) {
        debugPrint('🎬 GifMarkerManager: Found ${features.length} features');
      }

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

    if (_enableDetailedLogs) {
      debugPrint('🎬 GifMarkerManager: Searching for video URL in properties');
    }

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
        if (_enableDetailedLogs) {
          debugPrint(
              '🎬 GifMarkerManager: Found URL in root properties: $key = $value');
        }
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
          if (_enableDetailedLogs) {
            debugPrint(
                '🎬 GifMarkerManager: Found URL in nested properties: $key = $value');
          }
          return value;
        }
      }
    }

    // Рекурсивно ищем в любых вложенных объектах
    String? searchInObject(dynamic obj, String path) {
      if (obj is String && (obj.endsWith('.webm') || obj.endsWith('.gif'))) {
        if (_enableDetailedLogs) {
          debugPrint('🎬 GifMarkerManager: Found URL in path $path: $obj');
        }
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

    if (_enableDetailedLogs) {
      debugPrint('🎬 GifMarkerManager: No video URL found in properties');
    }
    return null;
  }

  @override
  void didUpdateWidget(GifMarkerManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_enableDetailedLogs) {
      debugPrint('🎬 GifMarkerManager: didUpdateWidget called');
    }
    if (oldWidget.mapboxMap != widget.mapboxMap) {
      if (_enableDetailedLogs) {
        debugPrint(
            '🎬 GifMarkerManager: MapboxMap instance changed, reinitializing');
      }
      _clearMarkers();
      _isInitialized = false;
      _initialize();
    } else if (!_isInitialized) {
      // Если виджет обновился, но маркеры не инициализированы, попробуем инициализировать
      if (_enableDetailedLogs) {
        debugPrint(
            '🎬 GifMarkerManager: Widget updated but not initialized, trying to initialize');
      }
      _initialize();
    }
  }

  void _clearMarkers() {
    if (_enableDetailedLogs) {
      debugPrint(
          '🎬 GifMarkerManager: Clearing ${_markersById.length} markers');
    }
    for (final markerData in _markersById.values) {
      if (markerData.controller != null) {
        markerData.controller!.dispose();
      }
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
      final isGif = videoUrl.toLowerCase().endsWith('.gif');
      VideoPlayerController? controller;

      // Если это не GIF, используем VideoPlayer
      if (!isGif) {
        // Создаем контроллер видео
        controller = VideoPlayerController.network(videoUrl);

        // Устанавливаем таймаут для инициализации
        bool initialized = false;
        Timer? timeoutTimer;

        timeoutTimer = Timer(const Duration(seconds: 10), () {
          if (!initialized && !_isDisposed) {
            debugPrint(
                '❌ GifMarkerManager: Video initialization timeout for $videoUrl');
            controller!.dispose();
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

        // Настраиваем зацикливание и автоматическое воспроизведение
        controller.setLooping(true);
        controller.setVolume(0.0);

        // Проверяем длительность видео и устанавливаем оптимальную скорость воспроизведения
        if (controller.value.duration.inMilliseconds > 0) {
          // Если видео слишком длинное, можно ускорить его
          if (controller.value.duration.inSeconds > 10) {
            controller.setPlaybackSpeed(1.5);
          }
          if (_enableDetailedLogs) {
            debugPrint(
                '🎬 GifMarkerManager: Video duration: ${controller.value.duration.inSeconds}s');
          }
        }

        // Запускаем воспроизведение
        await controller.play();

        // Добавляем периодическую проверку воспроизведения
        Timer.periodic(const Duration(seconds: 5), (timer) {
          if (_isDisposed ||
              controller == null ||
              !controller.value.isInitialized) {
            timer.cancel();
            return;
          }

          // Если видео остановилось, перезапускаем его
          if (!controller.value.isPlaying) {
            if (_enableDetailedLogs) {
              debugPrint(
                  '🎬 GifMarkerManager: Restarting video playback for $id');
            }
            controller.play();
          }
        });

        if (_isDisposed) {
          controller.dispose();
          return;
        }
      }

      // Добавляем маркер в список
      final screenPoint = await _getScreenPoint(coordinates);

      setState(() {
        _markersById[id] = _MarkerData(
          controller: controller,
          coordinates: [coordinates[0] as double, coordinates[1] as double],
          screenPoint: screenPoint,
          isGif: isGif,
          url: videoUrl,
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
      if (_enableDetailedLogs) {
        debugPrint('❌ GifMarkerManager: Error getting screen point: $e');
      }
      return null;
    }
  }

  // Обновляем позиции всех маркеров при изменении камеры
  Future<void> _updateMarkerPositions() async {
    if (_isDisposed || _markersById.isEmpty) return;

    // Пропускаем некоторые кадры для снижения нагрузки
    _frameSkipCounter++;
    if (_frameSkipCounter < _frameSkipThreshold) {
      return;
    }
    _frameSkipCounter = 0;

    // Проверяем, изменилась ли камера существенно, чтобы избежать лишних обновлений
    final cameraState = await widget.mapboxMap.getCameraState();
    bool cameraChanged = false;

    if (_lastCameraPosition == null) {
      cameraChanged = true;
    } else {
      final zoomDiff = (_lastCameraPosition!.zoom - cameraState.zoom).abs();

      // Безопасно извлекаем координаты с проверкой на null
      final lastLng = _lastCameraPosition!.center.coordinates[0];
      final lastLat = _lastCameraPosition!.center.coordinates[1];
      final currentLng = cameraState.center.coordinates[0];
      final currentLat = cameraState.center.coordinates[1];

      // Проверяем, что координаты не null перед вычислением разницы
      final lngDiff = (lastLng != null && currentLng != null)
          ? (lastLng - currentLng).abs()
          : 0.001; // Если null, считаем что изменение существенное

      final latDiff = (lastLat != null && currentLat != null)
          ? (lastLat - currentLat).abs()
          : 0.001; // Если null, считаем что изменение существенное

      cameraChanged = zoomDiff > 0.1 || lngDiff > 0.0001 || latDiff > 0.0001;
    }

    _lastCameraPosition = cameraState;

    // Если камера не изменилась существенно, пропускаем обновление
    if (!cameraChanged) return;

    final updatedMarkers = <String, _MarkerData>{};

    for (final entry in _markersById.entries) {
      final id = entry.key;
      final markerData = entry.value;

      final screenPoint = await _getScreenPoint(
          [markerData.coordinates[0], markerData.coordinates[1]]);

      // Проверяем, изменилась ли позиция маркера существенно
      bool positionChanged = true;

      if (markerData.screenPoint != null && screenPoint != null) {
        final dxDiff = (markerData.screenPoint!.dx - screenPoint.dx).abs();
        final dyDiff = (markerData.screenPoint!.dy - screenPoint.dy).abs();
        positionChanged = dxDiff > 1 || dyDiff > 1;
      }

      // Если позиция не изменилась существенно, сохраняем старую позицию
      if (!positionChanged) {
        updatedMarkers[id] = markerData;
        continue;
      }

      updatedMarkers[id] = _MarkerData(
        controller: markerData.controller,
        coordinates: markerData.coordinates,
        screenPoint: screenPoint,
        isGif: markerData.isGif,
        url: markerData.url,
      );
    }

    if (mounted && !_isDisposed) {
      setState(() {
        _markersById.clear();
        _markersById.addAll(updatedMarkers);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final entry in _markersById.entries)
          if (entry.value.screenPoint != null)
            Positioned(
              left: entry.value.screenPoint!.dx - 18, // Центрируем маркер
              top: entry.value.screenPoint!.dy - 18, // Центрируем маркер
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: RepaintBoundary(
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: entry.value.isGif
                        ? Image.network(
                            entry.value.url,
                            fit: BoxFit.cover,
                            gaplessPlayback:
                                true, // Предотвращает мерцание при обновлении
                            cacheWidth: 120, // Оптимизация кэширования
                            cacheHeight: 120,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                  '❌ GifMarkerManager: Error loading GIF: $error');
                              // Если GIF не загрузился, пробуем использовать VideoPlayer как запасной вариант
                              if (entry.value.controller != null) {
                                return AspectRatio(
                                  aspectRatio: 1.0,
                                  child: VideoPlayer(entry.value.controller!),
                                );
                              }
                              return const Center(
                                child: Icon(Icons.error, color: Colors.red),
                              );
                            },
                          )
                        : AspectRatio(
                            aspectRatio: 1.0,
                            child: VideoPlayer(entry.value.controller!),
                          ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _MarkerData {
  final VideoPlayerController? controller;
  final List<double> coordinates;
  final Offset? screenPoint;
  final bool isGif;
  final String url;

  _MarkerData({
    this.controller,
    required this.coordinates,
    this.screenPoint,
    this.isGif = false,
    required this.url,
  });
}