import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
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
  static const int _maxCacheSize = 30;

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

// Кэш изображений для видео
class VideoFrameCache {
  static final Map<String, Uint8List> _cache = {};
  static final Map<String, DateTime> _lastUpdate = {};
  static const Duration _cacheTimeout = Duration(milliseconds: 100);

  static bool shouldUpdate(String url) {
    if (!_lastUpdate.containsKey(url)) return true;
    return DateTime.now().difference(_lastUpdate[url]!) > _cacheTimeout;
  }

  static void setFrame(String url, Uint8List bytes) {
    _cache[url] = bytes;
    _lastUpdate[url] = DateTime.now();
  }

  static Uint8List? getFrame(String url) {
    return _cache[url];
  }

  static void clear() {
    _cache.clear();
    _lastUpdate.clear();
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

// Виджет для захвата кадра видео
class _VideoFrameWidget extends StatelessWidget {
  final VideoPlayerController controller;
  final GlobalKey frameKey;

  const _VideoFrameWidget({
    required this.controller,
    required this.frameKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: frameKey,
      child: SizedBox(
        width: 64,
        height: 64,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}

class GifMarkerManager extends StatefulWidget {
  final mapbox.MapboxMap mapboxMap;

  static final GlobalKey<_GifMarkerManagerState> globalKey =
      GlobalKey<_GifMarkerManagerState>();

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
  final Set<String> _activeAnnotationIds = {};
  OverlayEntry? _captureOverlay;
  bool _isDisposed = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  Timer? _updateTimer;
  int _initializationAttempts = 0;
  static const int _maxInitializationAttempts = 3;
  Timer? _styleCheckTimer;
  Timer? _videoRotationTimer;
  mapbox.PointAnnotationManager? _pointAnnotationManager;

  static const int _maxSimultaneousVideos = 5;
  final List<String> _activeVideoMarkers = [];

  // Для захвата кадра из VideoPlayer
  final GlobalKey _videoFrameKey = GlobalKey();
  OverlayEntry? _videoFrameOverlay;

  // Кэш для хеш-значений последних кадров
  final Map<String, int> _lastFrameHashes = {};

  // Для отслеживания кадров GIF-анимации
  final Map<String, int> _gifFrameIndices = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePointAnnotationManager();
  }

  @override
  void dispose() {
    _captureOverlay?.remove();
    _videoFrameOverlay?.remove();
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer?.cancel();
    _styleCheckTimer?.cancel();
    _videoRotationTimer?.cancel();
    _clearMarkers();
    GifCache.clear();
    VideoControllerCache.clear();
    VideoFrameCache.clear();
    super.dispose();
  }

  Future<void> _initializePointAnnotationManager() async {
    if (_isDisposed) {
      debugPrint('❌ Cannot initialize: manager is disposed');
      return;
    }

    try {
      debugPrint('🔄 Initializing PointAnnotationManager');
      final annotationManager = widget.mapboxMap.annotations;

      _pointAnnotationManager =
          await annotationManager.createPointAnnotationManager();
      if (_pointAnnotationManager == null) {
        debugPrint('❌ Failed to create point annotation manager');
        return;
      }

      debugPrint('✅ PointAnnotationManager initialized successfully');
      _scheduleInitialization();
      _startVideoRotationTimer();
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing PointAnnotationManager: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _clearMarkers() {
    for (final markerData in _markersById.values) {
      if (!markerData.isGif && markerData.url.isNotEmpty) {
        VideoControllerCache.releaseController(markerData.url);
      }
      if (markerData.annotation != null &&
          _activeAnnotationIds.contains(markerData.annotation!.id)) {
        try {
          _pointAnnotationManager?.delete(markerData.annotation!);
        } catch (e) {
          debugPrint('Warning: Could not delete annotation during cleanup: $e');
        }
      }
    }
    _markersById.clear();
    _activeAnnotationIds.clear();
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
    _updateTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted && !_isDisposed) {
        _updateMarkers();
      }
    });
  }

  Future<void> _updateMarkers() async {
    if (!mounted || _isDisposed || _markersById.isEmpty) return;

    for (final entry in _markersById.entries) {
      if (entry.value.isGif) {
        _updateGifMarkerImage(entry.key);
      } else if (_activeVideoMarkers.contains(entry.key)) {
        _updateVideoMarkerImage(entry.key);
      }
    }
  }

  Future<void> _updateVideoMarkerImage(String id) async {
    if (!_markersById.containsKey(id)) return;

    final markerData = _markersById[id]!;
    if (markerData.isGif ||
        markerData.controller == null ||
        !markerData.controller!.value.isInitialized) return;

    try {
      final videoValue = markerData.controller!.value;

      // Проверяем состояние видео
      if (videoValue.hasError) {
        debugPrint(
            '❌ Video has error for marker $id: ${videoValue.errorDescription}');
        return;
      }

      // Если видео закончилось, перематываем в начало
      if (videoValue.position >= videoValue.duration) {
        debugPrint('🔄 Seeking video to start for marker $id');
        await markerData.controller!.seekTo(Duration.zero);
      }

      // Проверяем, что видео проигрывается
      if (!videoValue.isPlaying) {
        debugPrint('▶️ Starting playback for marker $id');
        await markerData.controller!.play();
      }

      // Захватываем кадр
      debugPrint('📸 Capturing frame for marker $id');
      final imageBytes = await _captureVideoFrame(markerData.controller!);
      if (imageBytes == null || imageBytes.isEmpty) {
        debugPrint('❌ Failed to capture frame for marker $id');
        return;
      }

      debugPrint(
          '✅ Frame captured for marker $id, size: ${imageBytes.length} bytes');

      // Создаем точку для маркера
      final point = mapbox.Point(
        coordinates: mapbox.Position(
          markerData.coordinates[0],
          markerData.coordinates[1],
        ),
      );

      try {
        // Создаем опции для маркера
        final options = mapbox.PointAnnotationOptions(
          geometry: point,
          image: imageBytes,
          iconSize: 0.5,
        );

        // Создаем новый маркер
        final newAnnotation = await _pointAnnotationManager?.create(options);
        if (newAnnotation != null && mounted) {
          // Удаляем старый маркер, если он существует
          if (markerData.annotation != null &&
              _activeAnnotationIds.contains(markerData.annotation!.id)) {
            try {
              await _pointAnnotationManager?.delete(markerData.annotation!);
              _activeAnnotationIds.remove(markerData.annotation!.id);
              debugPrint('🗑️ Deleted old annotation for marker $id');
            } catch (e) {
              debugPrint('⚠️ Failed to delete old annotation: $e');
            }
          }

          // Добавляем новый маркер
          _activeAnnotationIds.add(newAnnotation.id);
          _markersById[id] = markerData.copyWith(annotation: newAnnotation);
          debugPrint('✅ Updated marker $id with new annotation');
        } else {
          debugPrint('❌ Failed to create new annotation for marker $id');
        }
      } catch (e) {
        debugPrint('❌ Error updating annotation for marker $id: $e');
      }
    } catch (e) {
      debugPrint('❌ Error updating video marker image for $id: $e');
    }
  }

  Future<void> _updateGifMarkerImage(String id) async {
    if (!_markersById.containsKey(id)) return;

    final markerData = _markersById[id]!;
    if (!markerData.isGif) return;

    try {
      final codec = await GifCache.getGif(markerData.url);
      final frameInfo = await codec.getNextFrame();

      final image = await _convertFrameToBytes(frameInfo.image);
      if (image != null) {
        final point = mapbox.Point(
          coordinates: mapbox.Position(
            markerData.coordinates[0],
            markerData.coordinates[1],
          ),
        );

        final options = mapbox.PointAnnotationOptions(
          geometry: point,
          image: image,
          iconSize: 1.0,
        );

        try {
          // Создаем новую аннотацию
          final newAnnotation = await _pointAnnotationManager?.create(options);
          if (newAnnotation != null) {
            // Если старая аннотация существует и активна, удаляем её
            if (markerData.annotation != null &&
                _activeAnnotationIds.contains(markerData.annotation!.id)) {
              try {
                await _pointAnnotationManager?.delete(markerData.annotation!);
                _activeAnnotationIds.remove(markerData.annotation!.id);
              } catch (e) {
                debugPrint('Warning: Could not delete old annotation: $e');
              }
            }

            // Добавляем новую аннотацию в список активных
            _activeAnnotationIds.add(newAnnotation.id);

            // Обновляем данные маркера
            _markersById[id] = markerData.copyWith(annotation: newAnnotation);
          }
        } catch (e) {
          debugPrint('❌ Error updating annotation: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating GIF marker image: $e');
    }
  }

  Future<Uint8List?> _convertFrameToBytes(ui.Image image) async {
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ Error converting frame to bytes: $e');
      return null;
    }
  }

  Future<Uint8List?> _createPlaceholderImage() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(60.0, 60.0);

      // Draw background
      final paint = Paint()
        ..color = Colors.black.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, paint);

      // Draw border
      paint
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(rect, paint);

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ Error creating placeholder image: $e');
      return null;
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

    // Включаем все видео, не ограничивая количество одновременных видео
    final videoMarkers = _markersById.entries
        .where((entry) => !entry.value.isGif && entry.value.isVisible)
        .map((entry) => entry.key)
        .toList();

    // Добавляем все видимые видео в список активных
    for (final id in videoMarkers) {
      if (!_activeVideoMarkers.contains(id)) {
        final controller = _markersById[id]?.controller;
        if (controller != null &&
            controller.value.isInitialized &&
            !controller.value.isPlaying) {
          controller.play();
          _activeVideoMarkers.add(id);
        }
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
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _createVideoMarker(
      String id, List coordinates, String videoUrl) async {
    if (_isDisposed || _pointAnnotationManager == null) {
      debugPrint(
          '❌ Cannot create marker: manager is disposed or not initialized');
      return;
    }

    try {
      debugPrint('🎥 Creating marker $id with URL: $videoUrl');
      final isGif = videoUrl.toLowerCase().endsWith('.gif');
      VideoPlayerController? controller;

      final point = mapbox.Point(
        coordinates: mapbox.Position(
          coordinates[0] as double,
          coordinates[1] as double,
        ),
      );

      debugPrint(
          '📍 Creating point annotation at coordinates: ${coordinates[0]}, ${coordinates[1]}');

      // Create initial marker with a placeholder image
      final placeholderImage = await _createPlaceholderImage();
      if (placeholderImage == null) {
        debugPrint('❌ Failed to create placeholder image for marker $id');
        return;
      }

      final options = mapbox.PointAnnotationOptions(
        geometry: point,
        image: placeholderImage,
        iconSize: 0.5,
      );

      final annotation = await _pointAnnotationManager!.create(options);
      _activeAnnotationIds.add(annotation.id);

      if (isGif) {
        try {
          debugPrint('🖼️ Initializing GIF marker $id');
          final response = await http.head(Uri.parse(videoUrl));
          if (response.statusCode != 200) {
            debugPrint('❌ Failed to verify GIF URL: ${response.statusCode}');
            await _pointAnnotationManager?.delete(annotation);
            return;
          }

          _markersById[id] = _MarkerData(
            controller: null,
            coordinates: [coordinates[0] as double, coordinates[1] as double],
            isGif: true,
            url: videoUrl,
            isInitialized: true,
            annotation: annotation,
          );
          _markersById[id]!.isVisible = true;

          _updateGifMarkerImage(id);
          debugPrint('✅ GIF marker $id initialized successfully');
        } catch (e) {
          debugPrint('❌ Error creating GIF marker $id: $e');
          await _pointAnnotationManager?.delete(annotation);
          return;
        }
      } else {
        debugPrint('🎬 Initializing video marker $id');
        _markersById[id] = _MarkerData(
          controller: null,
          coordinates: [coordinates[0] as double, coordinates[1] as double],
          isGif: isGif,
          url: videoUrl,
          isInitialized: false,
          annotation: annotation,
        );

        try {
          debugPrint('🔄 Getting video controller for $id');
          controller = VideoControllerCache.getController(videoUrl);

          if (controller == null) {
            debugPrint('📱 Creating new video controller for $id');
            try {
              controller =
                  await VideoControllerCache.createController(videoUrl);

              // Проверяем, что контроллер создан и инициализирован
              if (!controller.value.isInitialized) {
                debugPrint('❌ Controller initialization failed for $id');
                if (_markersById.containsKey(id)) {
                  await _pointAnnotationManager?.delete(annotation);
                  _markersById.remove(id);
                }
                return;
              }

              // Настраиваем контроллер с явными параметрами
              debugPrint('⚙️ Configuring video controller for $id');
              await controller.setLooping(true);
              await controller.setVolume(0.0);
              await controller.setPlaybackSpeed(1.0);

              // Логируем размер видео
              final videoSize = controller.value.size;
              debugPrint(
                  '📐 Video size for $id: ${videoSize.width.toInt()}x${videoSize.height.toInt()}');
            } catch (e) {
              debugPrint('❌ Error creating video controller for $id: $e');
              if (_markersById.containsKey(id)) {
                await _pointAnnotationManager?.delete(annotation);
                _markersById.remove(id);
              }
              return;
            }
          } else {
            debugPrint('♻️ Reusing cached controller for $id');
          }

          if (!_isDisposed && controller.value.isInitialized) {
            debugPrint('✅ Video controller initialized for $id');
            _markersById[id] = _MarkerData(
              controller: controller,
              coordinates: [coordinates[0] as double, coordinates[1] as double],
              isGif: isGif,
              url: videoUrl,
              isInitialized: true,
              annotation: annotation,
            );
            _markersById[id]!.isVisible = true;

            // Сразу запускаем видео без задержки
            if (!controller.value.isPlaying) {
              debugPrint('▶️ Starting video playback for marker $id');
              await controller.play();
            } else {
              debugPrint('⏯️ Video already playing for marker $id');
            }
            _activeVideoMarkers.add(id);

            // Сразу обновляем изображение маркера с кадром из видео
            debugPrint('🔄 Updating initial marker image for $id');
            await _updateVideoMarkerImage(id);
            debugPrint('▶️ Started playing video for marker $id');
          } else {
            debugPrint('❌ Controller not properly initialized for $id');
            if (_markersById.containsKey(id)) {
              await _pointAnnotationManager?.delete(annotation);
              _markersById.remove(id);
            }
          }
        } catch (e) {
          debugPrint('❌ Error creating video marker $id: $e');
          if (_markersById.containsKey(id)) {
            await _pointAnnotationManager?.delete(annotation);
            _markersById.remove(id);
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _createVideoMarker for $id: $e');
    }
  }

  Future<Uint8List?> _captureVideoFrame(
      VideoPlayerController controller) async {
    if (!mounted || _isDisposed) return null;

    try {
      if (!controller.value.isInitialized ||
          controller.value.size.width == 0 ||
          controller.value.size.height == 0) {
        return _createDummyFrame();
      }

      final completer = Completer<Uint8List?>();
      _videoFrameOverlay?.remove();
      _videoFrameOverlay = OverlayEntry(
        builder: (context) {
          return Positioned(
            left: -9999, // Выносим за пределы экрана
            top: -9999,
            width: 64, // Фиксированный размер
            height: 64,
            child: Opacity(
              opacity: 0.01, // Почти невидимый
              child: Material(
                type: MaterialType.transparency,
                child: RepaintBoundary(
                  key: _videoFrameKey,
                  child: Container(
                    width: 64,
                    height: 64,
                    color: Colors.black,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      Overlay.of(context).insert(_videoFrameOverlay!);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!mounted || _isDisposed) {
            completer.complete(null);
            return;
          }

          try {
            final boundary = _videoFrameKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
            if (boundary == null) {
              debugPrint('❌ RepaintBoundary not found');
              completer.complete(_createDummyFrame());
              return;
            }

            boundary.toImage(pixelRatio: 1.0).then((image) {
              image.toByteData(format: ui.ImageByteFormat.png).then((byteData) {
                final bytes = byteData?.buffer.asUint8List();
                completer.complete(bytes);
              }).catchError((e) {
                debugPrint('❌ Error converting image to bytes: $e');
                completer.complete(_createDummyFrame());
              });
            }).catchError((e) {
              debugPrint('❌ Error capturing image: $e');
              completer.complete(_createDummyFrame());
            });
          } catch (e) {
            debugPrint('❌ Error in frame capture: $e');
            completer.complete(_createDummyFrame());
          }
        });
      });

      final result = await completer.future.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {
          debugPrint('⚠️ Frame capture timed out, using dummy frame');
          return _createDummyFrame();
        },
      );

      _videoFrameOverlay?.remove();
      _videoFrameOverlay = null;

      return result;
    } catch (e) {
      debugPrint('❌ Error in _captureVideoFrame: $e');
      return _createDummyFrame();
    }
  }

  // Создаем заглушку, если не удалось захватить кадр
  Future<Uint8List?> _createDummyFrame() async {
    const size = Size(64.0, 64.0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Рисуем черный фон
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Рисуем контур
    paint
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        const Radius.circular(4),
      ),
      paint,
    );

    // Индикатор проблемы с загрузкой
    paint
      ..color = Colors.red.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Создаем символ ошибки (восклицательный знак)
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 12, paint);

    paint.color = Colors.white;

    // Восклицательный знак
    final exclamationPath = Path();
    exclamationPath.moveTo(center.dx, center.dy - 6);
    exclamationPath.lineTo(center.dx, center.dy + 1);
    exclamationPath.moveTo(center.dx, center.dy + 4);
    exclamationPath.lineTo(center.dx, center.dy + 4);

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(exclamationPath, paint);

    final picture = recorder.endRecording();
    final image =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  // Вычисляет простой хеш для сравнения изображений
  int _computeImageHash(Uint8List bytes) {
    if (bytes.isEmpty) return 0;

    int hash = 0;
    // Берем каждый 10-й байт для ускорения вычислений
    for (int i = 0; i < bytes.length; i += 10) {
      hash = (hash * 31 + bytes[i]) & 0xFFFFFFFF;
    }
    return hash;
  }
}

class _MarkerData {
  final VideoPlayerController? controller;
  final List<double> coordinates;
  final bool isGif;
  final String url;
  final bool isInitialized;
  final mapbox.PointAnnotation? annotation;
  bool isVisible = false;

  _MarkerData({
    this.controller,
    required this.coordinates,
    this.isGif = false,
    required this.url,
    this.isInitialized = false,
    this.annotation,
  });

  _MarkerData copyWith({
    VideoPlayerController? controller,
    List<double>? coordinates,
    bool? isGif,
    String? url,
    bool? isInitialized,
    mapbox.PointAnnotation? annotation,
    bool? isVisible,
  }) {
    return _MarkerData(
      controller: controller ?? this.controller,
      coordinates: coordinates ?? this.coordinates,
      isGif: isGif ?? this.isGif,
      url: url ?? this.url,
      isInitialized: isInitialized ?? this.isInitialized,
      annotation: annotation ?? this.annotation,
    )..isVisible = isVisible ?? this.isVisible;
  }
}
