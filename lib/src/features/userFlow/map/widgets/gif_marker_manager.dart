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

  @override
  void initState() {
    super.initState();
    if (_enableDetailedLogs) {
      debugPrint('🎬 GifMarkerManager: initState called');
    }
    WidgetsBinding.instance.addObserver(this);

    // Отложенная инициализация для уверенности, что карта загружена
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleInitialization();
    });
  }

  void _scheduleInitialization() {
    if (_isInitializing || _isInitialized || _isDisposed) return;

    _isInitializing = true;
    // Увеличиваем задержку с каждой попыткой
    final delay = Duration(seconds: 1 + _initializationAttempts);
    debugPrint(
        '🎬 GifMarkerManager: Scheduling initialization in ${delay.inSeconds}s (attempt ${_initializationAttempts + 1})');

    Future.delayed(delay, () {
      if (mounted && !_isDisposed && !_isInitialized) {
        _initialize();
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
    } else if (state == AppLifecycleState.paused) {
      // Приложение ушло в фон - останавливаем обновление
      _updateTimer?.cancel();
      _styleCheckTimer?.cancel();
    }
  }

  @override
  void deactivate() {
    debugPrint('🎬 GifMarkerManager: deactivate called');
    // Останавливаем таймеры при деактивации виджета
    _updateTimer?.cancel();
    _styleCheckTimer?.cancel();
    super.deactivate();
  }

  // Публичный метод для принудительной переинициализации
  void reinitialize() {
    if (_isDisposed) return;
    _clearMarkers();
    _isInitialized = false;
    _isInitializing = false;
    _initializationAttempts = 0;
    _scheduleInitialization();
  }

  Future<void> _initialize() async {
    if (_isDisposed || _isInitialized) {
      _isInitializing = false;
      return;
    }

    try {
      debugPrint(
          '🎬 GifMarkerManager: Initializing... (attempt ${_initializationAttempts + 1})');
      _initializationAttempts++;

      // Проверяем, загружен ли стиль карты
      final styleURI = await widget.mapboxMap.style.getStyleURI();
      if (styleURI.isEmpty) {
        debugPrint('❌ GifMarkerManager: Style not loaded yet');
        _isInitializing = false;
        if (_initializationAttempts < _maxInitializationAttempts) {
          _scheduleInitialization();
        } else {
          // Если после нескольких попыток стиль не загрузился, запускаем периодическую проверку
          _startStyleCheckTimer();
        }
        return;
      }

      // Проверяем наличие слоя
      final layers = await widget.mapboxMap.style.getStyleLayers();
      final layerExists =
          layers.any((layer) => layer?.id == "places_symbol_layer");

      if (!layerExists) {
        debugPrint('❌ GifMarkerManager: places_symbol_layer not found');
        _isInitializing = false;
        if (_initializationAttempts < _maxInitializationAttempts) {
          _scheduleInitialization();
        } else {
          // Если после нескольких попыток слой не найден, запускаем периодическую проверку
          _startStyleCheckTimer();
        }
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

      if (features.isEmpty) {
        debugPrint(
            '❌ GifMarkerManager: No features found in places_symbol_layer');
        _isInitializing = false;
        if (_initializationAttempts < _maxInitializationAttempts) {
          _scheduleInitialization();
        } else {
          // Если после нескольких попыток точки не найдены, запускаем периодическую проверку
          _startStyleCheckTimer();
        }
        return;
      }

      if (_isDisposed) {
        _isInitializing = false;
        return;
      }

      // Обрабатываем каждую точку
      int processedMarkers = 0;
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
        processedMarkers++;
      }

      // Проверяем, были ли созданы маркеры
      if (processedMarkers == 0 && _markersById.isEmpty) {
        debugPrint(
            '⚠️ GifMarkerManager: No markers were created, will retry later');
        _isInitializing = false;
        if (_initializationAttempts < _maxInitializationAttempts) {
          _scheduleInitialization();
        } else {
          // Если после нескольких попыток маркеры не созданы, запускаем периодическую проверку
          _startStyleCheckTimer();
        }
        return;
      }

      // Запускаем таймер обновления позиций маркеров
      _startUpdateTimer();

      // Останавливаем таймер проверки стиля, если он был запущен
      _styleCheckTimer?.cancel();

      _isInitialized = true;
      _isInitializing = false;
      debugPrint(
          '✅ GifMarkerManager: Initialization complete with ${_markersById.length} markers (processed $processedMarkers)');
    } catch (e) {
      debugPrint('❌ GifMarkerManager: Error initializing: $e');
      _isInitializing = false;
      if (_initializationAttempts < _maxInitializationAttempts) {
        _scheduleInitialization();
      } else {
        // Если после нескольких попыток произошла ошибка, запускаем периодическую проверку
        _startStyleCheckTimer();
      }
    }
  }

  // Запускаем периодическую проверку стиля и слоев
  void _startStyleCheckTimer() {
    _styleCheckTimer?.cancel();
    debugPrint('🎬 GifMarkerManager: Starting style check timer');
    _styleCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || _isDisposed || _isInitialized || _isInitializing) {
        timer.cancel();
        return;
      }
      debugPrint('🎬 GifMarkerManager: Checking style and layers...');
      _scheduleInitialization();
    });
  }

  void _startUpdateTimer() {
    _updateTimer?.cancel();
    // Уменьшаем частоту обновления до 30 кадров в секунду, этого достаточно для плавности
    _updateTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (mounted && !_isDisposed) {
        _updateMarkerPositions();
      }
    });
  }

  // Добавляем метод для обновления позиций маркеров с проверкой изменений
  Future<void> _updateMarkerPositions() async {
    if (!mounted || _isDisposed || _markersById.isEmpty) return;

    // Проверяем, изменилась ли камера
    final cameraState = await widget.mapboxMap.getCameraState();
    bool cameraChanged = false;

    if (_lastCameraState == null) {
      cameraChanged = true;
    } else {
      final zoomDiff = (_lastCameraState!.zoom != cameraState.zoom);
      final bearingDiff = (_lastCameraState!.bearing != cameraState.bearing);
      final pitchDiff = (_lastCameraState!.pitch != cameraState.pitch);

      // Безопасно извлекаем координаты с проверкой на null
      final lastLng = _lastCameraState!.center.coordinates[0];
      final lastLat = _lastCameraState!.center.coordinates[1];
      final currentLng = cameraState.center.coordinates[0];
      final currentLat = cameraState.center.coordinates[1];

      // Проверяем, что координаты не null перед вычислением разницы
      double lngDiff = 0.001;
      double latDiff = 0.001;

      if (lastLng != null && currentLng != null) {
        lngDiff = (lastLng - currentLng).abs().toDouble();
      }

      if (lastLat != null && currentLat != null) {
        latDiff = (lastLat - currentLat).abs().toDouble();
      }

      cameraChanged = zoomDiff ||
          bearingDiff ||
          pitchDiff ||
          lngDiff > 0.0000001 ||
          latDiff > 0.0000001;
    }

    _lastCameraState = cameraState;

    // Если камера не изменилась, не обновляем позиции
    if (!cameraChanged) return;

    // Обновляем позиции только если камера изменилась
    setState(() {
      // Позиции будут пересчитаны в _buildMarkers
    });
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
      _styleCheckTimer?.cancel();
      _clearMarkers();
      _isInitialized = false;
      _isInitializing = false;
      _initializationAttempts = 0;
      _scheduleInitialization();
    } else if (!_isInitialized && !_isInitializing) {
      // Если виджет обновился, но маркеры не инициализированы, попробуем инициализировать
      if (_enableDetailedLogs) {
        debugPrint(
            '🎬 GifMarkerManager: Widget updated but not initialized, trying to initialize');
      }
      _scheduleInitialization();
    }
  }

  void _clearMarkers() {
    if (_enableDetailedLogs) {
      debugPrint(
          '🎬 GifMarkerManager: Clearing ${_markersById.length} markers');
    }

    // Очищаем контроллеры видео
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
    _updateTimer?.cancel();
    _styleCheckTimer?.cancel();
    _clearMarkers();
    // Очищаем кэш GIF при уничтожении
    GifCache.clear();
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

      // Если это GIF, предварительно проверяем его доступность
      if (isGif) {
        try {
          // Проверяем, можно ли загрузить GIF
          final response = await http.head(Uri.parse(videoUrl));
          if (response.statusCode != 200) {
            debugPrint(
                '❌ GifMarkerManager: GIF not available: $videoUrl (status: ${response.statusCode})');
            return;
          }
          debugPrint('✅ GifMarkerManager: GIF is available: $videoUrl');
        } catch (e) {
          debugPrint('❌ GifMarkerManager: Error checking GIF availability: $e');
          return;
        }
      }
      // Если это не GIF, используем VideoPlayer
      else {
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

          // Проверяем, что контроллер все еще валиден
          if (_isDisposed || !controller.value.isInitialized) {
            controller.dispose();
            return;
          }

          // Настраиваем зацикливание и автоматическое воспроизведение
          await controller.setLooping(true);
          await controller.setVolume(0.0);

          // Проверяем длительность видео и устанавливаем оптимальную скорость воспроизведения
          if (controller.value.duration.inMilliseconds > 0) {
            // Если видео слишком длинное, можно ускорить его
            if (controller.value.duration.inSeconds > 10) {
              await controller.setPlaybackSpeed(1.5);
            }
            if (_enableDetailedLogs) {
              debugPrint(
                  '🎬 GifMarkerManager: Video duration: ${controller.value.duration.inSeconds}s');
            }
          }

          // Запускаем воспроизведение
          await controller.play();
          debugPrint('✅ GifMarkerManager: Video playback started for $id');

          // Добавляем периодическую проверку воспроизведения
          Timer.periodic(const Duration(seconds: 2), (timer) {
            if (_isDisposed || controller == null || !mounted) {
              timer.cancel();
              return;
            }

            // Проверяем, что контроллер все еще валиден
            if (!controller.value.isInitialized) {
              timer.cancel();
              return;
            }

            // Если видео остановилось, перезапускаем его
            if (!controller.value.isPlaying) {
              debugPrint(
                  '🔄 GifMarkerManager: Restarting video playback for $id');
              controller.play();
            }
          });
        } catch (e) {
          debugPrint('❌ GifMarkerManager: Failed to initialize video: $e');
          controller.dispose();
          return;
        }

        if (_isDisposed) {
          controller.dispose();
          return;
        }
      }

      // Сохраняем данные маркера
      setState(() {
        _markersById[id] = _MarkerData(
          controller: controller,
          coordinates: [coordinates[0] as double, coordinates[1] as double],
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
  Future<Offset?> _getScreenPoint(List<double> coordinates) async {
    try {
      final point = mapbox.Point(
        coordinates: mapbox.Position(
          coordinates[0],
          coordinates[1],
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _buildCachedMarkers(),
    );
  }

  // Кэшированные маркеры для более стабильного отображения
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

  // Публичный метод для принудительного обновления маркеров
  void forceUpdate() {
    if (_isDisposed) return;
    debugPrint('🎬 GifMarkerManager: Force update requested');

    // Если инициализация уже идет, не запускаем новую
    if (_isInitializing) {
      debugPrint(
          '🎬 GifMarkerManager: Initialization already in progress, skipping force update');
      return;
    }

    // Если маркеры уже инициализированы, обновляем их
    if (_isInitialized) {
      debugPrint('🎬 GifMarkerManager: Updating marker positions and states');

      // Обновляем позиции маркеров
      _updateMarkerPositions();

      // Проверяем состояние видео-контроллеров
      for (final entry in _markersById.entries) {
        final markerData = entry.value;
        if (!markerData.isGif && markerData.controller != null) {
          final controller = markerData.controller!;

          // Проверяем, что контроллер инициализирован
          if (controller.value.isInitialized) {
            // Если видео не воспроизводится, запускаем его
            if (!controller.value.isPlaying) {
              debugPrint(
                  '🔄 GifMarkerManager: Restarting video for marker ${entry.key}');
              controller.play();
            }
          } else {
            debugPrint(
                '⚠️ GifMarkerManager: Controller for marker ${entry.key} is not initialized');
          }
        }
      }

      return;
    }

    // Если маркеры не инициализированы, запускаем инициализацию
    reinitialize();
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
  }

  void _checkAndStartVideo() {
    if (!widget.markerData.isGif &&
        widget.markerData.controller != null &&
        widget.markerData.controller!.value.isInitialized &&
        !_videoStarted) {
      _videoStarted = true;
      widget.markerData.controller!.play().then((_) {
        debugPrint('✅ Video playback started in _MarkerWidget');
      }).catchError((error) {
        debugPrint('❌ Error starting video in _MarkerWidget: $error');
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
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

    return AnimatedPositioned(
      duration:
          const Duration(milliseconds: 0), // Мгновенное обновление позиции
      left: _screenPoint!.dx - 15, // Центрируем маркер (половина ширины)
      top: _screenPoint!.dy - 15, // Центрируем маркер (половина высоты)
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
          child: widget.markerData.isGif
              ? LoopingGifWidget(
                  key: ValueKey('gif_${widget.markerData.url}'),
                  url: widget.markerData.url,
                  fit: BoxFit.cover,
                )
              : _buildVideoPlayer(),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    // Проверяем, что контроллер существует и инициализирован
    if (widget.markerData.controller == null) {
      return const Center(
        child: Icon(Icons.error, color: Colors.red, size: 16),
      );
    }

    if (!widget.markerData.controller!.value.isInitialized) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.0,
      child: VideoPlayer(widget.markerData.controller!),
    );
  }
}

class _MarkerData {
  final VideoPlayerController? controller;
  final List<double> coordinates;
  final bool isGif;
  final String url;

  _MarkerData({
    this.controller,
    required this.coordinates,
    this.isGif = false,
    required this.url,
  });
}
