import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:video_player/video_player.dart';

// Глобальная переменная для контроля вывода логов
bool _enableDetailedLogs = false;

// Кэш для GIF-изображений
class GifCache {
  static final Map<String, ui.Codec> _cache = {};

  static Future<ui.Codec> getGif(String url) async {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }

    final bytes = await _loadGifBytes(url);
    if (bytes == null) {
      throw Exception('Failed to load GIF from $url');
    }

    final codec = await ui.instantiateImageCodec(bytes);
    _cache[url] = codec;
    return codec;
  }

  static Future<Uint8List?> _loadGifBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error loading GIF bytes: $e');
      return null;
    }
  }

  static void clear() {
    _cache.clear();
  }
}

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

      // Устанавливаем нормальную скорость воспроизведения
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
    // Если кэш не переполнен, ничего не делаем
    if (_cache.length < _maxCacheSize) return;

    // Сортируем URL по времени последнего использования и количеству использований
    final urls = _cache.keys.toList();
    urls.sort((a, b) {
      // Сначала сортируем по количеству использований (меньше - удаляем первыми)
      final countCompare = (_usageCount[a] ?? 0).compareTo(_usageCount[b] ?? 0);
      if (countCompare != 0) return countCompare;

      // Затем по времени последнего использования (старые - удаляем первыми)
      return (_lastUsed[a] ?? DateTime.now())
          .compareTo(_lastUsed[b] ?? DateTime.now());
    });

    // Удаляем наименее используемые контроллеры
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
    // Помечаем контроллер как неиспользуемый, но не удаляем его
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

// Виджет для отображения зацикленных GIF
class LoopingGifWidget extends StatefulWidget {
  final String url;
  final BoxFit fit;

  const LoopingGifWidget({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });

  @override
  State<LoopingGifWidget> createState() => _LoopingGifWidgetState();
}

class _LoopingGifWidgetState extends State<LoopingGifWidget>
    with SingleTickerProviderStateMixin {
  ui.Codec? _codec;
  ui.FrameInfo? _frameInfo;
  late AnimationController _controller;
  int _currentFrame = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addListener(_updateFrame);
    _loadGif();
  }

  Future<void> _loadGif() async {
    try {
      _isLoading = true;
      if (mounted) setState(() {});

      final codec = await GifCache.getGif(widget.url);
      if (!mounted) return;

      _codec = codec;
      _frameInfo = await codec.getNextFrame();
      _isLoading = false;
      _hasError = false;

      // Настраиваем контроллер анимации для правильного времени кадра
      if (_frameInfo != null) {
        _controller.duration = _frameInfo!.duration;
        _controller.repeat();
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Error loading GIF: $e');
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      if (mounted) setState(() {});
    }
  }

  void _updateFrame() async {
    if (_codec == null || !mounted) return;

    try {
      _frameInfo = await _codec!.getNextFrame();
      _currentFrame = (_currentFrame + 1) % _codec!.frameCount;

      if (_frameInfo != null) {
        _controller.duration = _frameInfo!.duration;
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Error updating GIF frame: $e');
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateFrame);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError || _frameInfo == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 10),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      );
    }

    return RawImage(
      image: _frameInfo!.image,
      fit: widget.fit,
    );
  }
}

class GifMarkerManager extends StatefulWidget {
  final mapbox.MapboxMap mapboxMap;

  // Глобальный ключ для доступа к состоянию из родительского виджета
  static final GlobalKey<_GifMarkerManagerState> globalKey =
      GlobalKey<_GifMarkerManagerState>();

  // Статический метод для обновления маркеров из любого места в приложении
  static void updateMarkers() {
    final state = globalKey.currentState;
    if (state != null && !state._isDisposed) {
      state.reinitialize();
    }
  }

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
  bool _isInitializing = false;
  Timer? _updateTimer;
  mapbox.CameraState? _lastCameraState;
  int _initializationAttempts = 0;
  static const int _maxInitializationAttempts = 3;
  Timer? _styleCheckTimer;
  Timer? _videoRotationTimer;
  final bool _isSystemUnderLoad = false;

  static const int _maxSimultaneousVideos = 5;
  final List<String> _activeVideoMarkers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleInitialization();
    });
    _startVideoRotationTimer();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer?.cancel();
    _styleCheckTimer?.cancel();
    _videoRotationTimer?.cancel();
    _clearMarkers();
    GifCache.clear();
    VideoControllerCache.clear();
    super.dispose();
  }

  void _clearMarkers() {
    for (final markerData in _markersById.values) {
      if (!markerData.isGif && markerData.url.isNotEmpty) {
        VideoControllerCache.releaseController(markerData.url);
      }
    }
    _markersById.clear();
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

      for (final feature in features) {
        if (feature == null || _isDisposed) continue;

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

        await _createVideoMarker(id, coordinates, videoUrl);
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

    final videoMarkers = _markersById.entries
        .where((entry) => !entry.value.isGif)
        .map((entry) => entry.key)
        .toList();

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

  void _checkAndRestartAllVideos() {
    if (!mounted || _isDisposed || !_isInitialized) return;

    _activeVideoMarkers.clear();
    final visibleMarkers = _markersById.keys
        .where((id) => _markersById[id]!.isVisible)
        .take(_maxSimultaneousVideos)
        .toList();

    for (int i = 0; i < visibleMarkers.length; i++) {
      final id = visibleMarkers[i];
      final markerData = _markersById[id];

      if (markerData == null ||
          markerData.isGif ||
          markerData.controller == null) continue;

      Future.delayed(Duration(milliseconds: 200 * i), () {
        if (!mounted || _isDisposed || !_markersById.containsKey(id)) return;

        final controller = markerData.controller;
        if (controller == null || !controller.value.isInitialized) return;

        if (!controller.value.isPlaying) {
          controller.play();
          _activeVideoMarkers.add(id);
        } else {
          _activeVideoMarkers.add(id);
        }
      });
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
      if (value != null &&
          (value.endsWith('.webm') || value.endsWith('.gif'))) {
        return value;
      }
    }

    if (nestedProperties != null) {
      for (final key in keys) {
        final value = nestedProperties[key]?.toString();
        if (value != null &&
            (value.endsWith('.webm') || value.endsWith('.gif'))) {
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

  Future<void> _createVideoMarker(
      String id, List coordinates, String videoUrl) async {
    if (_isDisposed) return;

    try {
      final isGif = videoUrl.toLowerCase().endsWith('.gif');
      VideoPlayerController? controller;

      if (isGif) {
        try {
          final response = await http.head(Uri.parse(videoUrl));
          if (response.statusCode != 200) return;

          setState(() {
            _markersById[id] = _MarkerData(
              controller: null,
              coordinates: [coordinates[0] as double, coordinates[1] as double],
              isGif: true,
              url: videoUrl,
              isInitialized: true,
            );
          });
        } catch (e) {
          return;
        }
      } else {
        setState(() {
          _markersById[id] = _MarkerData(
            controller: null,
            coordinates: [coordinates[0] as double, coordinates[1] as double],
            isGif: isGif,
            url: videoUrl,
            isInitialized: false,
          );
        });

        await Future.delayed(const Duration(milliseconds: 500));

        try {
          controller = VideoControllerCache.getController(videoUrl);

          controller ??= await VideoControllerCache.createController(videoUrl);

          if (mounted && !_isDisposed && _markersById.containsKey(id)) {
            setState(() {
              _markersById[id] = _MarkerData(
                controller: controller,
                coordinates: [
                  coordinates[0] as double,
                  coordinates[1] as double
                ],
                isGif: isGif,
                url: videoUrl,
                isInitialized: true,
              );
            });

            Future.delayed(const Duration(milliseconds: 800), () {
              if (!_isDisposed &&
                  controller != null &&
                  controller.value.isInitialized &&
                  mounted &&
                  _markersById.containsKey(id)) {
                if (_activeVideoMarkers.length < _maxSimultaneousVideos) {
                  controller.play().then((_) {
                    _activeVideoMarkers.add(id);
                  });
                }
              }
            });
          }
        } catch (e) {
          if (_markersById.containsKey(id)) {
            _markersById.remove(id);
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('❌ GifMarkerManager: Error creating marker $id: $e');
    }
  }
}

// Выделяем маркер в отдельный StatefulWidget для лучшего управления жизненным циклом
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
  bool _isVisible = false;
  late AnimationController _animationController;
  bool _videoStarted = false;
  Timer? _videoCheckTimer;
  int _restartAttempts = 0;
  static const int _maxRestartAttempts = 5;

  // Флаг для отслеживания высокой нагрузки на систему
  bool get _isSystemUnderLoad {
    // Получаем доступ к родительскому состоянию через GlobalKey
    final parentState = GifMarkerManager.globalKey.currentState;
    if (parentState != null) {
      return parentState._isSystemUnderLoad;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();

    // Создаем контроллер анимации для обновления позиции в каждом кадре
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: false);

    // Добавляем слушатель для обновления позиции в каждом кадре анимации
    _animationController.addListener(_updatePosition);

    // Инициализируем позицию
    _updatePosition();

    // Проверяем и запускаем видео, если это необходимо
    _checkAndStartVideo();

    // Запускаем периодическую проверку видео
    _startVideoCheckTimer();
  }

  void _startVideoCheckTimer() {
    _videoCheckTimer?.cancel();

    // Проверяем видео каждые 3 секунды
    _videoCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _forceRestartVideoIfNeeded();
    });
  }

  void _forceRestartVideoIfNeeded() {
    if (!mounted || widget.markerData.isGif) return;

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
      // Сбрасываем счетчик попыток, если видео воспроизводится
      _restartAttempts = 0;
    }
  }

  void _checkAndStartVideo() {
    if (!mounted || widget.markerData.isGif || _videoStarted) return;

    final controller = widget.markerData.controller;
    if (controller == null) return;

    if (!_videoStarted && controller.value.isInitialized) {
      _videoStarted = true;
      // Добавляем небольшую задержку перед запуском видео
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
    // Обновляем позицию если координаты изменились
    if (oldWidget.markerData.coordinates != widget.markerData.coordinates) {
      _updatePosition();
    }

    // Проверяем и запускаем видео при обновлении виджета
    _checkAndStartVideo();

    // Если контроллер изменился, перезапускаем таймер проверки
    if (oldWidget.markerData.controller != widget.markerData.controller) {
      _startVideoCheckTimer();
    }
  }

  void _updatePosition() {
    // Используем метод pixelForCoordinate для преобразования геокоординат в экранные
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
        // Проверяем, находится ли точка в пределах экрана
        final size = MediaQuery.of(context).size;
        final isOnScreen = screenCoordinate.x >= -30 &&
            screenCoordinate.x <= size.width + 30 &&
            screenCoordinate.y >= -30 &&
            screenCoordinate.y <= size.height + 30;

        setState(() {
          _screenPoint = Offset(screenCoordinate.x, screenCoordinate.y);
          _isVisible = isOnScreen;

          // Обновляем видимость в данных маркера
          (widget.markerData).isVisible = isOnScreen;
        });
      }
    }).catchError((_) {
      // Игнорируем ошибки
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_screenPoint == null || !_isVisible) {
      return const SizedBox.shrink();
    }

    // Проверяем и запускаем видео при построении виджета
    _checkAndStartVideo();

    // Стандартный размер маркера
    const markerSize = 30.0;
    const halfSize = markerSize / 2;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 0),
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
            child: widget.markerData.isGif
                ? LoopingGifWidget(url: widget.markerData.url)
                : widget.markerData.controller != null &&
                        widget.markerData.controller!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio:
                            widget.markerData.controller!.value.aspectRatio,
                        child: VideoPlayer(widget.markerData.controller!),
                      )
                    : const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
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
  final bool isGif;
  final String url;
  final bool isInitialized;
  bool isVisible = false;

  _MarkerData({
    this.controller,
    required this.coordinates,
    this.isGif = false,
    required this.url,
    this.isInitialized = false,
  });
}
