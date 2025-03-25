import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:video_player/video_player.dart';

// Глобальная переменная для контроля вывода логов
// bool _enableDetailedLogs = true;

// Глобальный кэш для видео контроллеров
class VideoControllerCache {
  static final Map<String, VideoPlayerController> _cache = {};
  static final Map<String, DateTime> _lastUsed = {};
  static final Map<String, int> _usageCount = {};
  static const int _maxCacheSize = 10;

  static VideoPlayerController? getController(String url) {
    if (_cache.containsKey(url)) {
      _lastUsed[url] = DateTime.now();
      _usageCount[url] = (_usageCount[url] ?? 0) + 1;
      return _cache[url];
    }
    return null;
  }

  static Future<VideoPlayerController> createController(String url) async {
    // Проверяем, есть ли контроллер в кэше
    if (_cache.containsKey(url)) {
      _lastUsed[url] = DateTime.now();
      _usageCount[url] = (_usageCount[url] ?? 0) + 1;
      return _cache[url]!;
    }

    // Если кэш переполнен, удаляем наименее используемые контроллеры
    if (_cache.length >= _maxCacheSize) {
      _cleanCache();
    }

    // Создаем новый контроллер
    final controller = VideoPlayerController.network(
      url,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );

    _cache[url] = controller;
    _lastUsed[url] = DateTime.now();
    _usageCount[url] = 1;

    // Инициализируем контроллер
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.setPlaybackSpeed(1.0);
    } catch (e) {
      debugPrint('❌ VideoControllerCache: Error initializing controller: $e');
      _cache.remove(url);
      _lastUsed.remove(url);
      _usageCount.remove(url);
      rethrow;
    }

    return controller;
  }

  static void _cleanCache() {
    if (_cache.length < _maxCacheSize) return;

    final urls = _cache.keys.toList();
    urls.sort((a, b) {
      final countCompare = (_usageCount[a] ?? 0).compareTo(_usageCount[b] ?? 0);
      if (countCompare != 0) return countCompare;
      return (_lastUsed[a] ?? DateTime.now())
          .compareTo(_lastUsed[b] ?? DateTime.now());
    });

    final toRemove = urls.take(urls.length - _maxCacheSize + 1).toList();
    for (final url in toRemove) {
      final controller = _cache[url];
      if (controller != null) {
        controller.dispose();
      }
      _cache.remove(url);
      _lastUsed.remove(url);
      _usageCount.remove(url);
      debugPrint(
          '🗑️ VideoControllerCache: Removed controller for $url from cache');
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
    _usageCount.clear();
    debugPrint('🧹 VideoControllerCache: Cleared all controllers');
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
  mapbox.CameraState? _lastCameraState;
  int _initializationAttempts = 0;
  static const int _maxInitializationAttempts = 3;
  Timer? _styleCheckTimer;
  Timer? _videoRotationTimer;
  final bool _isSystemUnderLoad = false;
  final Set<String> _processedFeatures = {};
  Timer? _featuresCheckTimer;
  int _lastFeaturesCount = 0;
  int _stableFeaturesCount = 0;
  static const int _maxStableChecks = 3;
  static const Duration _checkInterval = Duration(milliseconds: 1000);
  static const Duration _maxCheckDuration = Duration(seconds: 15);
  static const int _minFeatureCount = 100;
  static const int _maxFeatureCount = 1000;
  static const double _maxFeatureChangePercent = 0.1;
  DateTime? _checkStartTime;

  static const int _maxSimultaneousVideos = 5;
  final List<String> _activeVideoMarkers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startStyleCheck();
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
            _startFeaturesCheck();
          }
        }
      } catch (e) {
        debugPrint('❌ Error checking style: $e');
      }
    });
  }

  Future<void> _ensureMapLoaded() async {
    while (!_isStyleLoaded) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _startFeaturesCheck() {
    _featuresCheckTimer?.cancel();
    _checkStartTime = DateTime.now();
    _featuresCheckTimer = Timer.periodic(_checkInterval, (_) {
      _checkFeaturesStability();
    });
  }

  Future<void> _checkFeaturesStability() async {
    if (_isDisposed || _isInitialized) {
      _featuresCheckTimer?.cancel();
      return;
    }

    // Проверяем таймаут
    if (_checkStartTime != null &&
        DateTime.now().difference(_checkStartTime!) > _maxCheckDuration) {
      debugPrint('⚠️ Features check timeout reached');
      _featuresCheckTimer?.cancel();
      _scheduleInitialization();
      return;
    }

    try {
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

      final currentFeaturesCount = features.length;
      debugPrint('📊 Current features count: $currentFeaturesCount');

      // Проверяем, что количество фич находится в разумных пределах
      if (currentFeaturesCount >= _minFeatureCount &&
          currentFeaturesCount <= _maxFeatureCount) {
        if (_lastFeaturesCount == 0) {
          _lastFeaturesCount = currentFeaturesCount;
          _stableFeaturesCount = 0;
          debugPrint('🔄 First features count: $currentFeaturesCount');
          return;
        }

        // Проверяем, не слишком ли большое изменение
        final changePercent =
            (currentFeaturesCount - _lastFeaturesCount).abs() /
                _lastFeaturesCount;
        if (changePercent <= _maxFeatureChangePercent) {
          _stableFeaturesCount++;
          debugPrint(
              '✅ Features count stable: $_stableFeaturesCount/$_maxStableChecks (change: ${(changePercent * 100).toStringAsFixed(1)}%)');

          if (_stableFeaturesCount >= _maxStableChecks) {
            _featuresCheckTimer?.cancel();
            _scheduleInitialization();
          }
        } else {
          _stableFeaturesCount = 0;
          debugPrint(
              '📈 Features count changed significantly: $_lastFeaturesCount -> $currentFeaturesCount (${(changePercent * 100).toStringAsFixed(1)}%)');
        }
      } else {
        debugPrint(
            '⚠️ Features count out of range: $currentFeaturesCount (expected: $_minFeatureCount - $_maxFeatureCount)');
        _stableFeaturesCount = 0;
      }

      _lastFeaturesCount = currentFeaturesCount;
    } catch (e) {
      debugPrint('❌ Error checking features stability: $e');
      _featuresCheckTimer?.cancel();
      _scheduleInitialization();
    }
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
      await _ensureMapLoaded();

      _initializationAttempts++;
      debugPrint(
          '🔄 Starting marker initialization (attempt $_initializationAttempts)');

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
        debugPrint('ℹ️ No features found to initialize');
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

        if (isOnScreen) {
          visibleMarkers.add(id);
        }

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

      // Запускаем воспроизведение только для видимых маркеров
      for (final id in visibleMarkers) {
        if (_markersById.containsKey(id)) {
          final markerData = _markersById[id]!;
          if (markerData.controller != null &&
              markerData.controller!.value.isInitialized &&
              _activeVideoMarkers.length < _maxSimultaneousVideos) {
            await markerData.controller!.play();
            _activeVideoMarkers.add(id);
          }
        }
      }

      debugPrint('✅ Marker initialization completed successfully');
    } catch (e) {
      debugPrint('❌ Error during marker initialization: $e');
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
    }
    _markersById.clear();
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

  void _startVideoRotationTimer() {
    _videoRotationTimer?.cancel();
    _videoRotationTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && !_isDisposed && _isInitialized) {
        _rotateActiveVideos();
      }
    });
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
    final nestedProperties = properties['properties'] as Map<dynamic, dynamic>?;
    final keys = [
      'marker_type',
      'markerType',
      'marker_url',
      'markerUrl',
      'video_url',
      'videoUrl',
      'url'
    ];

    for (final key in keys) {
      final value = properties[key]?.toString();
      if (value != null && value.endsWith('.webm')) {
        return value;
      }
    }

    if (nestedProperties != null) {
      for (final key in keys) {
        final value = nestedProperties[key]?.toString();
        if (value != null && value.endsWith('.webm')) {
          return value;
        }
      }
    }

    return null;
  }

  void reinitialize() {
    if (_isDisposed) return;
    _clearMarkers();
    _isInitialized = false;
    _isInitializing = false;
    _initializationAttempts = 0;
    _processedFeatures.clear();
    _lastFeaturesCount = 0;
    _stableFeaturesCount = 0;
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

  Future<void> _ensureMapReady() async {
    // Ждем загрузки стиля
    while (!_isStyleLoaded) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Ждем стабилизации фич
    while (_lastFeaturesCount < _minFeatureCount ||
        _lastFeaturesCount > _maxFeatureCount) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Дополнительная задержка для полной стабилизации
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _createVideoMarker(
      String id, List coordinates, String videoUrl) async {
    if (_isDisposed) return;

    try {
      // Ждем полной готовности карты
      await _ensureMapReady();

      setState(() {
        _markersById[id] = _MarkerData(
          controller: null,
          coordinates: [coordinates[0] as double, coordinates[1] as double],
          url: videoUrl,
          isInitialized: false,
        );
      });

      try {
        final controller = VideoControllerCache.getController(videoUrl);
        final finalController =
            controller ?? await VideoControllerCache.createController(videoUrl);

        if (mounted && !_isDisposed && _markersById.containsKey(id)) {
          setState(() {
            _markersById[id] = _MarkerData(
              controller: finalController,
              coordinates: [coordinates[0] as double, coordinates[1] as double],
              url: videoUrl,
              isInitialized: true,
            );
          });
        }
      } catch (e) {
        if (_markersById.containsKey(id)) {
          _markersById.remove(id);
        }
        return;
      }
    } catch (e) {
      debugPrint('❌ VideoMarkerManager: Error creating marker $id: $e');
    }
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

class _MarkerWidget extends StatefulWidget {
  final mapbox.MapboxMap mapboxMap;
  final _MarkerData markerData;

  const _MarkerWidget({
    super.key,
    required this.mapboxMap,
    required this.markerData,
  });

  @override
  State<_MarkerWidget> createState() => _MarkerWidgetState();
}

class _MarkerWidgetState extends State<_MarkerWidget>
    with SingleTickerProviderStateMixin {
  Offset? _screenPoint;
  Offset? _targetScreenPoint;
  Offset? _lastScreenPoint;
  bool _isVisible = false;
  late AnimationController _animationController;
  bool _videoStarted = false;
  Timer? _videoCheckTimer;
  int _restartAttempts = 0;
  static const int _maxRestartAttempts = 5;
  static const double _smoothingFactor =
      0.1; // Уменьшенный коэффициент сглаживания
  static const double _maxPositionDelta =
      50.0; // Максимальное допустимое изменение позиции

  bool get _isSystemUnderLoad {
    final parentState = VideoMarkerManager.globalKey.currentState;
    if (parentState != null) {
      return parentState._isSystemUnderLoad;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: false);

    _animationController.addListener(_updatePosition);
    _updatePosition();
    _checkAndStartVideo();
    _startVideoCheckTimer();
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
        debugPrint(
            '🔄 _MarkerWidget: Force restarting video (attempt $_restartAttempts)');
        controller.play().catchError((error) {
          debugPrint('❌ _MarkerWidget: Error restarting video: $error');
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
          debugPrint('❌ _MarkerWidget: Error playing video: $error');
        });
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(_MarkerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markerData.coordinates != widget.markerData.coordinates) {
      _updatePosition();
    }

    _checkAndStartVideo();

    if (oldWidget.markerData.controller != widget.markerData.controller) {
      _startVideoCheckTimer();
    }
  }

  void _updatePosition() {
    widget.mapboxMap
        .pixelForCoordinate(
      mapbox.Point(
        coordinates: mapbox.Position(
          widget.markerData.coordinates[0],
          widget.markerData.coordinates[1],
        ),
      ),
    )
        .then((screenCoordinate) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        final isOnScreen = screenCoordinate.x >= -30 &&
            screenCoordinate.x <= size.width + 30 &&
            screenCoordinate.y >= -30 &&
            screenCoordinate.y <= size.height + 30;

        final newTargetPoint = Offset(screenCoordinate.x, screenCoordinate.y);

        // Проверяем, не слишком ли резкое изменение позиции
        if (_targetScreenPoint != null) {
          final delta = (newTargetPoint - _targetScreenPoint!).distance;
          if (delta > _maxPositionDelta) {
            // Если изменение слишком резкое, игнорируем его
            return;
          }
        }

        setState(() {
          _targetScreenPoint = newTargetPoint;
          _isVisible = isOnScreen;
          (widget.markerData).isVisible = isOnScreen;
        });

        // Если это первое обновление позиции, устанавливаем текущую позицию
        _screenPoint ??= _targetScreenPoint;
      }
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    if (_screenPoint == null || !_isVisible) {
      return const SizedBox.shrink();
    }

    _checkAndStartVideo();

    const markerSize = 25.0;
    const halfSize = markerSize / 2;

    // Плавно обновляем позицию маркера с уменьшенным коэффициентом сглаживания
    if (_targetScreenPoint != null && _screenPoint != _targetScreenPoint) {
      _screenPoint = Offset.lerp(
        _screenPoint!,
        _targetScreenPoint!,
        _smoothingFactor,
      );
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      left: _screenPoint!.dx - halfSize,
      top: _screenPoint!.dy - halfSize,
      child: RepaintBoundary(
        child: Container(
          width: markerSize,
          height: markerSize,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: widget.markerData.controller != null &&
                    widget.markerData.controller!.value.isInitialized
                ? AspectRatio(
                    aspectRatio:
                        widget.markerData.controller!.value.aspectRatio,
                    child: VideoPlayer(widget.markerData.controller!),
                  )
                : const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _MarkerData {
  final VideoPlayerController? controller;
  final List<double> coordinates;
  final String url;
  final bool isInitialized;
  bool isVisible = false;

  _MarkerData({
    this.controller,
    required this.coordinates,
    required this.url,
    this.isInitialized = false,
  });
}
