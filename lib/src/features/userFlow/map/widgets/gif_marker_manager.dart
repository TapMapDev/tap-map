import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

class _GifMarkerManagerState extends State<GifMarkerManager> {
  final Map<String, _MarkerData> _markersById = {};
  bool _isDisposed = false;
  bool _isInitialized = false;
  Timer? _zoomCheckerTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('🎬 GifMarkerManager: initState called');
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!_isDisposed && mounted) {
        _initializeMarkers();
      }
    });
  }

  @override
  void didUpdateWidget(GifMarkerManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isInitialized && !_isDisposed && mounted) {
      debugPrint('🎬 GifMarkerManager: Map updated, retrying initialization');
      _initializeMarkers();
    }
  }

  @override
  void dispose() {
    debugPrint('🎬 GifMarkerManager: dispose called');
    _isDisposed = true;
    _zoomCheckerTimer?.cancel();
    for (final markerData in _markersById.values) {
      debugPrint('🎬 GifMarkerManager: disposing controller for marker');
      markerData.controller.dispose();
    }
    super.dispose();
  }

  // Функция для расчета масштаба
  double getGifScale(double zoom) {
    const minZoom = 5.0;
    const maxZoom = 18.0;
    const minScale = 0.1;
    const maxScale = 0.35;
    final clampedZoom = zoom.clamp(minZoom, maxZoom);
    final t = (clampedZoom - minZoom) / (maxZoom - minZoom);
    return minScale + t * (maxScale - minScale);
  }

  // Метод для масштабирования маркеров при изменении зума
  void _setupZoomChecker() {
    _zoomCheckerTimer?.cancel();
    _zoomCheckerTimer =
        Timer.periodic(const Duration(milliseconds: 1000), (_) async {
      if (_isDisposed) return;

      try {
        final cameraState = await widget.mapboxMap.getCameraState();
        final zoom = cameraState.zoom ?? 14.0;
        final scale = getGifScale(zoom);

        // Обновляем маркеры пакетами по 2 штуки
        final entries = _markersById.entries.toList();
        for (var i = 0; i < entries.length; i += 2) {
          if (_isDisposed) return;

          final batch = entries.skip(i).take(2);
          await Future.wait(
            batch.map((entry) async {
              final markerData = entry.value;
              final updatedOptions = mapbox.PointAnnotationOptions(
                geometry: markerData.marker.geometry,
                image: await _getScaledVideoFrame(markerData.controller,
                    scale: scale),
                iconSize: scale,
                iconAnchor: mapbox.IconAnchor.BOTTOM,
                iconOffset: [0, -20],
              );

              final pointAnnotationManager = await widget.mapboxMap.annotations
                  .createPointAnnotationManager();
              await pointAnnotationManager.delete(markerData.marker);
              final newMarker =
                  await pointAnnotationManager.create(updatedOptions);

              setState(() {
                _markersById[entry.key] = _MarkerData(
                  marker: newMarker,
                  controller: markerData.controller,
                );
              });
            }),
          );

          // Добавляем небольшую задержку между пакетами
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } catch (e) {
        debugPrint('❌ GifMarkerManager: Error in zoom checker: $e');
      }
    });
  }

  // Метод для получения scaled видеофрейма
  Future<Uint8List> _getScaledVideoFrame(VideoPlayerController controller,
      {required double scale}) async {
    if (!controller.value.isInitialized) {
      debugPrint('❌ GifMarkerManager: Video not initialized');
      throw Exception('Video not initialized');
    }

    final textureId = controller.textureId;
    debugPrint(
        '🎬 GifMarkerManager: Getting scaled frame from texture ID: $textureId with scale: $scale');

    final boundary = GlobalKey();
    final widget = RepaintBoundary(
      key: boundary,
      child: SizedBox(
        width: 35 * scale,
        height: 35 * scale,
        child: Texture(
          textureId: textureId,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );

    final context = this.context;
    if (!context.mounted) {
      debugPrint('❌ GifMarkerManager: Context is not available');
      throw Exception('Context is not available');
    }

    OverlayEntry? overlay;
    try {
      overlay = OverlayEntry(builder: (context) => widget);
      Overlay.of(context).insert(overlay);

      await Future.delayed(const Duration(milliseconds: 100));

      final renderObject = boundary.currentContext?.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        debugPrint('❌ GifMarkerManager: RenderObject is null or invalid');
        throw Exception('RenderObject is null or invalid');
      }

      if (!controller.value.isPlaying) {
        await controller.play();
      }

      final image = await (renderObject).toImage(
        pixelRatio: 1.0,
      );

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        debugPrint('❌ GifMarkerManager: Failed to convert frame to bytes');
        throw Exception('Failed to convert frame to bytes');
      }

      debugPrint(
          '🎬 GifMarkerManager: Successfully converted scaled frame to bytes');
      return byteData.buffer.asUint8List();
    } finally {
      overlay?.remove();
    }
  }

  Future<void> _initializeMarkers() async {
    if (_isDisposed || _isInitialized) return;
    debugPrint('🎬 GifMarkerManager: Starting marker initialization');

    try {
      final style = await widget.mapboxMap.style.getStyleURI();
      debugPrint('🎬 GifMarkerManager: Map style loaded: $style');

      final layers = await widget.mapboxMap.style.getStyleLayers();
      final layerExists =
          layers.any((layer) => layer?.id == "places_symbol_layer");
      debugPrint(
          '🎬 GifMarkerManager: places_symbol_layer exists: $layerExists');

      if (!layerExists) {
        debugPrint('❌ GifMarkerManager: places_symbol_layer not found');
        return;
      }

      debugPrint('🎬 GifMarkerManager: Querying rendered features');
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

      if (features.isEmpty) {
        debugPrint(
            '🎬 GifMarkerManager: No features found, retrying in 1 second');
        Future.delayed(const Duration(seconds: 1), () {
          if (!_isDisposed && mounted) {
            _initializeMarkers();
          }
        });
        return;
      }

      _isInitialized = true;

      for (final feature in features) {
        if (feature == null) continue;

        final properties =
            feature.queriedFeature.feature as Map<dynamic, dynamic>;
        final id = properties['id']?.toString();
        final nestedProperties =
            properties['properties'] as Map<dynamic, dynamic>?;

        // Добавляем подробное логирование структуры данных
        debugPrint('🎬 GifMarkerManager: Processing feature:');
        debugPrint('  - ID: $id');
        debugPrint('  - Raw Properties: ${jsonEncode(properties)}');
        debugPrint(
            '  - Raw Nested Properties: ${jsonEncode(nestedProperties)}');

        if (id == null) {
          debugPrint('🎬 GifMarkerManager: Skipping feature - missing id');
          continue;
        }

        // Проверяем все возможные места, где может быть marker_type
        final markerType = properties['marker_type']?.toString() ??
            properties['markerType']?.toString() ??
            properties['marker_url']?.toString() ??
            properties['markerUrl']?.toString() ??
            properties['video_url']?.toString() ??
            properties['videoUrl']?.toString() ??
            nestedProperties?['marker_type']?.toString() ??
            nestedProperties?['markerType']?.toString() ??
            nestedProperties?['marker_url']?.toString() ??
            nestedProperties?['markerUrl']?.toString() ??
            nestedProperties?['video_url']?.toString() ??
            nestedProperties?['videoUrl']?.toString();

        debugPrint('🎬 GifMarkerManager: Found marker_type: $markerType');

        if (markerType == null || !markerType.endsWith('.webm')) {
          debugPrint(
              '🎬 GifMarkerManager: Skipping feature - not a webm marker');
          continue;
        }

        if (_markersById.containsKey(id)) {
          debugPrint('🎬 GifMarkerManager: Marker $id already exists');
          continue;
        }

        final geometry = properties['geometry'] as Map<dynamic, dynamic>?;
        if (geometry == null) {
          debugPrint(
              '🎬 GifMarkerManager: Skipping feature - missing geometry');
          continue;
        }

        final coordinates = geometry['coordinates'] as List?;
        if (coordinates == null || coordinates.length < 2) {
          debugPrint(
              '🎬 GifMarkerManager: Skipping feature - invalid coordinates');
          continue;
        }

        debugPrint(
            '🎬 GifMarkerManager: Creating video marker for $id at coordinates: $coordinates');
        await _createVideoMarker(id, coordinates, markerType);
      }
    } catch (e) {
      debugPrint('❌ GifMarkerManager: Error initializing markers: $e');
      Future.delayed(const Duration(seconds: 1), () {
        if (!_isDisposed && mounted) {
          _initializeMarkers();
        }
      });
    }
  }

  Future<void> _createVideoMarker(
      String id, List coordinates, String videoUrl) async {
    if (_isDisposed) return;
    debugPrint(
        '🎬 GifMarkerManager: Creating video marker for $id with URL: $videoUrl');

    try {
      debugPrint('🎬 GifMarkerManager: Initializing video controller');
      final controller = VideoPlayerController.network(videoUrl);
      await controller.initialize();
      debugPrint('🎬 GifMarkerManager: Video controller initialized');
      controller.setLooping(true);
      controller.setVolume(0.0);
      await controller.play();

      // Получаем текущий зум карты
      final cameraState = await widget.mapboxMap.getCameraState();
      final currentZoom = cameraState.zoom ?? 14.0;
      final initialScale = getGifScale(currentZoom);

      debugPrint('🎬 GifMarkerManager: Video playback started');
      debugPrint('🎬 GifMarkerManager: Getting video frame');

      final imageBytes =
          await _getScaledVideoFrame(controller, scale: initialScale);
      debugPrint(
          '🎬 GifMarkerManager: Got video frame, size: ${imageBytes.length} bytes');

      final markerOptions = mapbox.PointAnnotationOptions(
        geometry: mapbox.Point(
          coordinates: mapbox.Position(
            coordinates[0] as double,
            coordinates[1] as double,
          ),
        ),
        image: imageBytes,
        iconSize: initialScale,
        iconAnchor: mapbox.IconAnchor.BOTTOM,
        iconOffset: [0, -20],
      );

      debugPrint('🎬 GifMarkerManager: Creating point annotation');
      final pointAnnotationManager =
          await widget.mapboxMap.annotations.createPointAnnotationManager();
      final marker = await pointAnnotationManager.create(markerOptions);

      setState(() {
        _markersById[id] = _MarkerData(
          marker: marker,
          controller: controller,
        );
      });

      debugPrint('🎬 GifMarkerManager: Marker added to state');
      _setupZoomChecker();
    } catch (e) {
      debugPrint('❌ GifMarkerManager: Error creating video marker: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '🎬 GifMarkerManager: Building widget with ${_markersById.length} markers');
    return Stack(
      children: _markersById.entries.map((entry) {
        final markerData = entry.value;
        final position = markerData.marker.geometry.coordinates;
        debugPrint(
            '🎬 GifMarkerManager: Building marker at position: ${position.lng}, ${position.lat}');
        return Positioned(
          left: position.lng.toDouble(),
          top: position.lat.toDouble(),
          child: SizedBox(
            width: 20,
            height: 20,
            child: Texture(
              textureId: markerData.controller.textureId,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MarkerData {
  final mapbox.PointAnnotation marker;
  final VideoPlayerController controller;

  _MarkerData({
    required this.marker,
    required this.controller,
  });
}
