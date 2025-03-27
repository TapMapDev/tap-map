import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:video_player/video_player.dart';

// Глобальный кэш для видео контроллеров
class VideoControllerCache {
  static final Map<String, VideoPlayerController> _cache = {};
  static final Map<String, DateTime> _lastUsed = {};
  static const int _maxCacheSize = 10;

  static VideoPlayerController? getController(String url) {
    if (_cache.containsKey(url)) {
      _lastUsed[url] = DateTime.now();
      return _cache[url];
    }
    return null;
  }

  static Future<VideoPlayerController> createController(String url) async {
    if (_cache.containsKey(url)) {
      _lastUsed[url] = DateTime.now();
      return _cache[url]!;
    }

    if (_cache.length >= _maxCacheSize) {
      _cleanCache();
    }

    final controller = VideoPlayerController.network(
      url,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );

    _cache[url] = controller;
    _lastUsed[url] = DateTime.now();

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.setPlaybackSpeed(1.0);
    } catch (e) {
      _cache.remove(url);
      _lastUsed.remove(url);
      rethrow;
    }

    return controller;
  }

  static void _cleanCache() {
    if (_cache.length < _maxCacheSize) return;

    final urls = _cache.keys.toList();
    urls.sort((a, b) => (_lastUsed[a] ?? DateTime.now())
        .compareTo(_lastUsed[b] ?? DateTime.now()));

    final toRemove = urls.take(urls.length - _maxCacheSize + 1).toList();
    for (final url in toRemove) {
      final controller = _cache[url];
      if (controller != null) {
        controller.dispose();
      }
      _cache.remove(url);
      _lastUsed.remove(url);
    }
  }

  static void releaseController(String url) {
    _lastUsed[url] = DateTime.now().subtract(const Duration(hours: 1));
  }

  static void clear() {
    for (final controller in _cache.values) {
      controller.dispose();
    }
    _cache.clear();
    _lastUsed.clear();
  }
}

class _MarkerData {
  final String id;
   mapbox.Point coordinates;
  final double zoom;
  final String url;

  VideoPlayerController? controller;
  final ValueNotifier<bool> isVisibleNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<Offset?> positionNotifier = ValueNotifier<Offset?>(null);

  bool get isVisible => isVisibleNotifier.value;
  set isVisible(bool value) {
    if (isVisibleNotifier.value != value) {
      isVisibleNotifier.value = value;
    }
  }

  _MarkerData({
    required this.id,
    required this.coordinates,
    required this.zoom,
    required this.url,
    this.controller,
    bool isVisible = false,
  }) {
    isVisibleNotifier.value = isVisible;
  }

  void dispose() {
    isVisibleNotifier.dispose();
    positionNotifier.dispose();
  }
}

class _MarkerWidget extends StatefulWidget {
  final _MarkerData markerData;
  final mapbox.MapboxMap mapboxMap;

  const _MarkerWidget({
    super.key,
    required this.markerData,
    required this.mapboxMap,
  });

  @override
  State<_MarkerWidget> createState() => _MarkerWidgetState();
}

class _MarkerWidgetState extends State<_MarkerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _videoStarted = false;
  Timer? _videoCheckTimer;
  Timer? _positionUpdateTimer;
  int _restartAttempts = 0;
  static const int _maxRestartAttempts = 5;
  static const double _smoothingFactor = 0.1;
  static const double _maxPositionDelta = 50.0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: false);

    _startVideoCheckTimer();
    _startPositionUpdateTimer();
  }

  void _startPositionUpdateTimer() {
    _positionUpdateTimer?.cancel();
    _positionUpdateTimer =
        Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updatePosition();
    });
  }

  void _startVideoCheckTimer() {
    _videoCheckTimer?.cancel();
    _videoCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _forceRestartVideoIfNeeded();
    });
  }

  void _forceRestartVideoIfNeeded() {
    if (!mounted) return;

    final controller = widget.markerData.controller;
    if (controller == null) return;

    if (controller.value.isInitialized && !controller.value.isPlaying) {
      if (_restartAttempts < _maxRestartAttempts) {
        _restartAttempts++;
        controller.play().catchError((error) {
          // Ошибка воспроизведения видео
        });
      }
    } else if (controller.value.isPlaying) {
      _restartAttempts = 0;
    }
  }

  void _checkAndStartVideo() {
    if (!mounted || _videoStarted) return;

    final controller = widget.markerData.controller;
    if (controller == null) return;

    if (!_videoStarted && controller.value.isInitialized) {
      _videoStarted = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        controller.play().catchError((error) {
          // Ошибка воспроизведения видео
        });
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoCheckTimer?.cancel();
    _positionUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(_MarkerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndStartVideo();

    if (oldWidget.markerData.controller != widget.markerData.controller) {
      _startVideoCheckTimer();
    }
  }

  void _updatePosition() {
    widget.mapboxMap
        .pixelForCoordinate(
      widget.markerData.coordinates,
    )
        .then((screenCoordinate) {
      if (!mounted) return;

      final newTargetPoint = Offset(screenCoordinate.x, screenCoordinate.y);
      final currentPosition = widget.markerData.positionNotifier.value;

      // Проверяем, не слишком ли резкое изменение позиции
      if (currentPosition != null) {
        final delta = (newTargetPoint - currentPosition).distance;
        if (delta > _maxPositionDelta) {
          // Если изменение слишком резкое, игнорируем его
          return;
        }
      }

      // Применяем сглаживание
      final newPosition = currentPosition == null
          ? newTargetPoint
          : Offset.lerp(currentPosition, newTargetPoint, _smoothingFactor);

      if (newPosition != currentPosition) {
        widget.markerData.positionNotifier.value = newPosition;
      }

      // Проверяем видимость
      if (newPosition != null) {
        final size = MediaQuery.of(context).size;
        final isOnScreen = newPosition.dx >= -30 &&
            newPosition.dx <= size.width + 30 &&
            newPosition.dy >= -30 &&
            newPosition.dy <= size.height + 30;

        if (widget.markerData.isVisible != isOnScreen) {
          widget.markerData.isVisible = isOnScreen;
        }
      }
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset?>(
      valueListenable: widget.markerData.positionNotifier,
      builder: (context, position, child) {
        if (position == null) {
          return const SizedBox.shrink();
        }

        _checkAndStartVideo();

        return ValueListenableBuilder<bool>(
          valueListenable: widget.markerData.isVisibleNotifier,
          builder: (context, isVisible, child) {
            if (!isVisible) {
              return const SizedBox.shrink();
            }

            const markerSize = 25.0;
            const halfSize = markerSize / 2;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              left: position.dx - halfSize,
              top: position.dy - halfSize,
              child: RepaintBoundary(
                child: SizedBox(
                  width: markerSize,
                  height: markerSize,
                  child: widget.markerData.controller != null
                      ? VideoPlayer(widget.markerData.controller!)
                      : const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class VideoMarkerManager extends StatefulWidget {
  final mapbox.MapboxMap mapboxMap;

  static final GlobalKey<_VideoMarkerManagerState> globalKey =
      GlobalKey<_VideoMarkerManagerState>();

  static void updateMarkers() {
    final state = globalKey.currentState;
    if (state != null && !state._isDisposed) {
      state.reinitialize();
    }
  }

  const VideoMarkerManager({
    super.key,
    required this.mapboxMap,
  });

  @override
  State<VideoMarkerManager> createState() => _VideoMarkerManagerState();
}

class _VideoMarkerManagerState extends State<VideoMarkerManager>
    with WidgetsBindingObserver {
  final Map<String, _MarkerData> _markersById = {};
  bool _isDisposed = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isStyleLoaded = false;
  Timer? _updateTimer;
  Timer? _featuresCheckTimer;
  mapbox.CameraState? _lastCameraState;
  int _initializationAttempts = 0;
  static const int _maxInitializationAttempts = 3;
  Timer? _styleCheckTimer;
  Timer? _videoRotationTimer;
  final Set<String> _processedFeatures = {};
  static const int _maxSimultaneousVideos = 5;
  final List<String> _activeVideoMarkers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startStyleCheck();
    _startFeaturesCheck();
  }

  void _startStyleCheck() {
    _styleCheckTimer?.cancel();
    _styleCheckTimer =
        Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (_isDisposed) return;

      try {
        final styleURI = await widget.mapboxMap.style.getStyleURI();
        if (styleURI.isNotEmpty) {
          final layers = await widget.mapboxMap.style.getStyleLayers();
          if (layers.isNotEmpty) {
            _isStyleLoaded = true;
            _styleCheckTimer?.cancel();
            _scheduleInitialization();
          }
        }
      } catch (e) {
        // Ошибка проверки стиля
      }
    });
  }

  void _startFeaturesCheck() {
    _featuresCheckTimer?.cancel();
    _featuresCheckTimer =
        Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && !_isDisposed && _isInitialized) {
        _checkVisibleFeatures();
      }
    });
  }

  Future<void> _checkVisibleFeatures() async {
    if (!mounted || _isDisposed || !_isInitialized) return;

    try {
      final cameraState = await widget.mapboxMap.getCameraState();
      final size = MediaQuery.of(context).size;
      final features = await widget.mapboxMap.queryRenderedFeatures(
        mapbox.RenderedQueryGeometry(
          type: mapbox.Type.SCREEN_BOX,
          value: jsonEncode({
            "min": {"x": 0, "y": 0},
            "max": {"x": size.width, "y": size.height}
          }),
        ),
        mapbox.RenderedQueryOptions(
          layerIds: ["places_symbol_layer"],
          filter: null,
        ),
      );

      if (features.isEmpty) return;

      final visibleFeatureIds = <String>{};
      for (final feature in features) {
        if (feature == null) continue;
        final properties =
            feature.queriedFeature.feature as Map<dynamic, dynamic>;
        final id = properties['id']?.toString();
        if (id != null) {
          visibleFeatureIds.add(id);
        }
      }

      bool visibilityChanged = false;

      // Обновляем видимость существующих маркеров
      for (final entry in _markersById.entries) {
        final wasVisible = entry.value.isVisible;
        entry.value.isVisible = visibleFeatureIds.contains(entry.key);
        if (wasVisible != entry.value.isVisible) {
          visibilityChanged = true;
        }
      }

      final markersToRemove = _markersById.keys
          .where((id) => !visibleFeatureIds.contains(id))
          .toList();

      // Удаляем маркеры, которые больше не видны
      for (final id in markersToRemove) {
        final markerData = _markersById[id];
        if (markerData != null) {
          if (markerData.url.isNotEmpty) {
            VideoControllerCache.releaseController(markerData.url);
          }
          _markersById.remove(id);
          _activeVideoMarkers.remove(id);
          visibilityChanged = true;
        }
      }

      final newMarkersToCreate = <Map<String, dynamic>>[];

      // Добавляем новые маркеры
      for (final feature in features) {
        if (feature == null) continue;

        final properties =
            feature.queriedFeature.feature as Map<dynamic, dynamic>;
        final id = properties['id']?.toString();
        if (id == null || _markersById.containsKey(id)) continue;

        final videoUrl = _findVideoUrl(properties);
        if (videoUrl == null) continue;

        final geometry = properties['geometry'] as Map<dynamic, dynamic>?;
        if (geometry == null) continue;

        final coordinates = geometry['coordinates'] as List?;
        if (coordinates == null || coordinates.length < 2) continue;

        newMarkersToCreate.add({
          'id': id,
          'coordinates': coordinates,
          'videoUrl': videoUrl,
        });
        visibilityChanged = true;
      }

      if (newMarkersToCreate.isNotEmpty) {
        final futures = <Future<void>>[];
        for (final markerData in newMarkersToCreate) {
          futures.add(_createVideoMarker(
            markerData['id'],
            markerData['coordinates'],
            markerData['videoUrl'],
          ));
        }

        await Future.wait(futures);
      }

      if (visibilityChanged) {
        setState(() {});
        _updateActiveVideos();
      }
    } catch (e) {
      // Ошибка проверки видимых фич
    }
  }

  Future<void> _ensureMapReady() async {
    // Ждем загрузки стиля
    while (!_isStyleLoaded) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Простая задержка для стабилизации
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _scheduleInitialization() {
    if (_isInitializing || _isInitialized || _isDisposed) return;
    _isInitializing = true;
    Future.delayed(Duration(seconds: 1 + _initializationAttempts), () {
      if (mounted && !_isDisposed && !_isInitialized) {
        _initialize();
      }
    });
  }

  Future<void> _initialize() async {
    if (_isDisposed || _isInitialized) {
      _isInitializing = false;
      return;
    }

    try {
      await _ensureMapReady();

      _initializationAttempts++;

      final styleURI = await widget.mapboxMap.style.getStyleURI();
      if (styleURI.isEmpty) {
        _isInitializing = false;
        if (_initializationAttempts < _maxInitializationAttempts) {
          _scheduleInitialization();
        }
        return;
      }

      final layers = await widget.mapboxMap.style.getStyleLayers();
      final layerExists =
          layers.any((layer) => layer?.id == "places_symbol_layer");

      if (!layerExists) {
        _isInitializing = false;
        if (_initializationAttempts < _maxInitializationAttempts) {
          _scheduleInitialization();
        }
        return;
      }

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

      if (features.isEmpty) {
        _isInitializing = false;
        if (_initializationAttempts < _maxInitializationAttempts) {
          _scheduleInitialization();
        }
        return;
      }

      if (_isDisposed) {
        _isInitializing = false;
        return;
      }

      final futures = <Future<void>>[];
      final visibleMarkers = <String>[];
      int batchCount = 0;
      const maxBatchSize = 5;
      const batchDelay = Duration(milliseconds: 200);

      for (final feature in features) {
        if (feature == null || _isDisposed) continue;

        final properties =
            feature.queriedFeature.feature as Map<dynamic, dynamic>;
        final id = properties['id']?.toString();
        if (id == null ||
            _markersById.containsKey(id) ||
            _processedFeatures.contains(id)) continue;

        final videoUrl = _findVideoUrl(properties);
        if (videoUrl == null) continue;

        final geometry = properties['geometry'] as Map<dynamic, dynamic>?;
        if (geometry == null) continue;

        final coordinates = geometry['coordinates'] as List?;
        if (coordinates == null || coordinates.length < 2) continue;

        _processedFeatures.add(id);

        final screenCoordinate = await widget.mapboxMap.pixelForCoordinate(
          mapbox.Point(
            coordinates: mapbox.Position(
              coordinates[0] as double,
              coordinates[1] as double,
            ),
          ),
        );

        final size = MediaQuery.of(context).size;
        final isOnScreen = screenCoordinate.x >= -30 &&
            screenCoordinate.x <= size.width + 30 &&
            screenCoordinate.y >= -30 &&
            screenCoordinate.y <= size.height + 30;

        visibleMarkers.add(id);

        futures.add(_createVideoMarker(id, coordinates, videoUrl));
        batchCount++;

        // Обрабатываем маркеры пакетами
        if (batchCount >= maxBatchSize) {
          await Future.wait(futures);
          futures.clear();
          batchCount = 0;
          await Future.delayed(batchDelay);
        }
      }

      // Обрабатываем оставшиеся маркеры
      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

      _startUpdateTimer();
      _isInitialized = true;
      _isInitializing = false;
    } catch (e) {
      _isInitializing = false;
      if (_initializationAttempts < _maxInitializationAttempts) {
        _scheduleInitialization();
      }
    }
  }

  void _clearMarkers() {
    for (final markerData in _markersById.values) {
      if (markerData.url.isNotEmpty) {
        VideoControllerCache.releaseController(markerData.url);
      }
      markerData.dispose();
    }
    _markersById.clear();
    _activeVideoMarkers.clear();
  }

  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (mounted && !_isDisposed) {
        _updateMarkerPositions();
      }
    });
  }

  Future<void> _updateMarkerPositions() async {
    if (!mounted || _isDisposed || _markersById.isEmpty) return;

    final cameraState = await widget.mapboxMap.getCameraState();
    bool cameraChanged = _lastCameraState == null;

    if (!cameraChanged) {
      cameraChanged = _lastCameraState!.zoom != cameraState.zoom ||
          _lastCameraState!.bearing != cameraState.bearing ||
          _lastCameraState!.pitch != cameraState.pitch;

      if (!cameraChanged) {
        final lastLng = _lastCameraState!.center.coordinates[0];
        final lastLat = _lastCameraState!.center.coordinates[1];
        final currentLng = cameraState.center.coordinates[0];
        final currentLat = cameraState.center.coordinates[1];

        if (lastLng != null &&
            currentLng != null &&
            lastLat != null &&
            currentLat != null) {
          cameraChanged = (lastLng - currentLng).abs() > 0.0000001 ||
              (lastLat - currentLat).abs() > 0.0000001;
        }
      }
    }

    _lastCameraState = cameraState;
    if (cameraChanged) {
      setState(() {});
    }
  }

  void _rotateActiveVideos() {
    if (_markersById.isEmpty) return;

    final videoMarkers = _markersById.keys.toList();

    if (videoMarkers.isEmpty) return;

    for (final id in _activeVideoMarkers.toList()) {
      if (!_markersById.containsKey(id)) {
        _activeVideoMarkers.remove(id);
        continue;
      }

      final markerData = _markersById[id]!;
      if (!markerData.isVisible ||
          markerData.controller == null ||
          !markerData.controller!.value.isInitialized) {
        markerData.controller?.pause();
        _activeVideoMarkers.remove(id);
      }
    }

    final visibleInactiveMarkers = videoMarkers
        .where((id) =>
            !_activeVideoMarkers.contains(id) &&
            _markersById[id]!.isVisible &&
            _markersById[id]!.controller != null &&
            _markersById[id]!.controller!.value.isInitialized)
        .toList();

    while (_activeVideoMarkers.length < _maxSimultaneousVideos &&
        visibleInactiveMarkers.isNotEmpty) {
      final id = visibleInactiveMarkers.removeAt(0);
      final controller = _markersById[id]!.controller;

      if (controller != null && controller.value.isInitialized) {
        Future.delayed(Duration(milliseconds: 300 * _activeVideoMarkers.length),
            () {
          if (!mounted || _isDisposed || !_markersById.containsKey(id)) return;
          controller.play().then((_) {
            if (mounted && !_isDisposed && _markersById.containsKey(id)) {
              _activeVideoMarkers.add(id);
            }
          });
        });
      }
    }
  }

  String? _findVideoUrl(Map<dynamic, dynamic> properties) {
    // Проверяем основные свойства
    final markerType = properties['marker_type']?.toString();
    if (markerType != null && markerType.endsWith('.webm')) {
      return markerType;
    }

    // Проверяем вложенные свойства, если они есть
    final nestedProperties = properties['properties'] as Map<dynamic, dynamic>?;
    if (nestedProperties != null) {
      final nestedMarkerType = nestedProperties['marker_type']?.toString();
      if (nestedMarkerType != null && nestedMarkerType.endsWith('.webm')) {
        return nestedMarkerType;
      }
    }

    return null;
  }

Future<void> _createVideoMarker(
    String id,
    List coordinates,
    String videoUrl,
) async {
  if (_isDisposed) return;

  try {
    await _ensureMapReady();

    // Смотрим, есть ли уже такой MarkerData
    final existingMarker = _markersById[id];

    // Формируем новые координаты
    final point = mapbox.Point(
      coordinates: mapbox.Position(
        coordinates[0] as double,
        coordinates[1] as double,
      ),
    );

    if (existingMarker != null) {
      // 1. _MarkerData уже существует — обновим поля

      // Обновим координаты
      existingMarker.coordinates = point;
      // Сделаем маркер видимым
      existingMarker.isVisible = true;

      // 2. Обновим контроллер
      final existingController =
          VideoControllerCache.getController(videoUrl) ?? existingMarker.controller;

      if (existingController != null) {
        existingMarker.controller = existingController;
      } else {
        existingMarker.controller =
            await VideoControllerCache.createController(videoUrl);
      }
      if (existingMarker.controller != null &&
          !_activeVideoMarkers.contains(id) &&
          _activeVideoMarkers.length < _maxSimultaneousVideos) {
        await existingMarker.controller!.play();
        _activeVideoMarkers.add(id);
      }
      return;
    }

    // 4. Если маркер не существует, создаём его:
    final initialController =
        VideoControllerCache.getController(videoUrl) ??
            await VideoControllerCache.createController(videoUrl);

    final newMarker = _MarkerData(
      id: id,
      coordinates: point,
      zoom: 15.0,
      url: videoUrl,
      controller: initialController,
      isVisible: true,
    );

    setState(() {
      _markersById[id] = newMarker;
    });

    // 5. Автоматически запускаем видео, если не превышен лимит
    if (_activeVideoMarkers.length < _maxSimultaneousVideos) {
      try {
        await initialController.play();
        _activeVideoMarkers.add(id);
      } catch (e) {
        // Ошибка при воспроизведении видео
      }
    }
  } catch (e) {
    }
  }

  void _updateActiveVideos() {
    // Останавливаем видео для маркеров, которые перестали быть видимыми
    for (final id in _activeVideoMarkers.toList()) {
      if (!_markersById.containsKey(id) || !_markersById[id]!.isVisible) {
        final markerData = _markersById[id];
        if (markerData != null && markerData.controller != null) {
          markerData.controller!.pause().catchError((_) {});
        }
        _activeVideoMarkers.remove(id);
      }
    }

    // Находим видимые маркеры, которые не активны
    final visibleInactiveMarkers = _markersById.entries
        .where((entry) =>
            entry.value.isVisible &&
            entry.value.controller != null &&
            entry.value.controller!.value.isInitialized &&
            !_activeVideoMarkers.contains(entry.key))
        .map((entry) => entry.key)
        .toList();

    // Запускаем видео для новых маркеров, если не превышен лимит
    for (final id in visibleInactiveMarkers) {
      if (_activeVideoMarkers.length >= _maxSimultaneousVideos) break;

      final markerData = _markersById[id]!;
      if (markerData.controller != null &&
          markerData.controller!.value.isInitialized) {
        markerData.controller!.play().then((_) {
          if (mounted && !_isDisposed && markerData.isVisible) {
            _activeVideoMarkers.add(id);
          }
        }).catchError((error) {
          // Ошибка воспроизведения видео для маркера
        });
      }
    }
  }

  void reinitialize() {
    if (_isDisposed) return;
    _clearMarkers();
    _isInitialized = false;
    _isInitializing = false;
    _initializationAttempts = 0;
    _processedFeatures.clear();
    _scheduleInitialization();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _buildCachedMarkers(),
    );
  }

  List<Widget> _buildCachedMarkers() {
    final markers = <Widget>[];
    for (final entry in _markersById.entries) {
      markers.add(
        _MarkerWidget(
          key: ValueKey('marker_${entry.key}'),
          mapboxMap: widget.mapboxMap,
          markerData: entry.value,
        ),
      );
    }
    return markers;
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer?.cancel();
    _styleCheckTimer?.cancel();
    _videoRotationTimer?.cancel();
    _featuresCheckTimer?.cancel();
    _clearMarkers();
    VideoControllerCache.clear();
    super.dispose();
  }
}
