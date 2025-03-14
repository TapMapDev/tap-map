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
    for (final markerData in _markersById.values) {
      debugPrint('🎬 GifMarkerManager: disposing controller for marker');
      markerData.controller.dispose();
    }
    super.dispose();
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

        // Добавляем подробное логирование структуры
        debugPrint('🎬 GifMarkerManager: Processing feature:');
        debugPrint('  - ID: $id');
        debugPrint('  - Feature Type: ${properties['type']}');
        debugPrint(
            '  - Has Properties: ${properties.containsKey('properties')}');
        debugPrint('  - Properties Keys: ${properties.keys.join(', ')}');

        if (nestedProperties != null) {
          debugPrint(
              '  - Nested Properties Keys: ${nestedProperties.keys.join(', ')}');
          debugPrint('  - Nested Properties Values:');
          nestedProperties.forEach((key, value) {
            debugPrint('    - $key: $value');
          });
        }

        if (id == null) {
          debugPrint('🎬 GifMarkerManager: Skipping feature - missing id');
          continue;
        }

        // Проверяем все возможные места, где может быть URL видео
        final possibleUrls = {
          'root.marker_type': properties['marker_type']?.toString(),
          'root.markerType': properties['markerType']?.toString(),
          'root.marker_url': properties['marker_url']?.toString(),
          'root.markerUrl': properties['markerUrl']?.toString(),
          'root.video_url': properties['video_url']?.toString(),
          'root.videoUrl': properties['videoUrl']?.toString(),
          'root.url': properties['url']?.toString(),
          'root.media_url': properties['media_url']?.toString(),
          'root.mediaUrl': properties['mediaUrl']?.toString(),
        };

        if (nestedProperties != null) {
          possibleUrls.addAll({
            'nested.marker_type': nestedProperties['marker_type']?.toString(),
            'nested.markerType': nestedProperties['markerType']?.toString(),
            'nested.marker_url': nestedProperties['marker_url']?.toString(),
            'nested.markerUrl': nestedProperties['markerUrl']?.toString(),
            'nested.video_url': nestedProperties['video_url']?.toString(),
            'nested.videoUrl': nestedProperties['videoUrl']?.toString(),
            'nested.url': nestedProperties['url']?.toString(),
            'nested.media_url': nestedProperties['media_url']?.toString(),
            'nested.mediaUrl': nestedProperties['mediaUrl']?.toString(),
          });
        }

        debugPrint('🎬 GifMarkerManager: All possible URLs:');
        possibleUrls.forEach((key, value) {
          if (value != null) {
            debugPrint('  - $key: $value');
          }
        });

        // Ищем первый непустой URL, который заканчивается на .webm
        final markerType = possibleUrls.values.firstWhere(
          (url) => url != null && url.endsWith('.webm'),
          orElse: () => null,
        );

        if (markerType == null) {
          debugPrint('🎬 GifMarkerManager: No valid webm URL found');
          continue;
        }

        debugPrint('🎬 GifMarkerManager: Found valid webm URL: $markerType');

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
      debugPrint('🎬 GifMarkerManager: Video playback started');

      debugPrint('🎬 GifMarkerManager: Getting video frame');
      final imageBytes = await _getVideoFrame(controller);
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
      );

      debugPrint('🎬 GifMarkerManager: Creating point annotation');
      final pointAnnotationManager =
          await widget.mapboxMap.annotations.createPointAnnotationManager();
      final marker = await pointAnnotationManager.create(markerOptions);
      debugPrint('🎬 GifMarkerManager: Point annotation created successfully');

      setState(() {
        _markersById[id] = _MarkerData(
          marker: marker,
          controller: controller,
        );
      });
      debugPrint('🎬 GifMarkerManager: Marker added to state');
    } catch (e) {
      debugPrint('❌ GifMarkerManager: Error creating video marker: $e');
    }
  }

  Future<Uint8List> _getVideoFrame(VideoPlayerController controller) async {
    if (!controller.value.isInitialized) {
      debugPrint('❌ GifMarkerManager: Video not initialized');
      throw Exception('Video not initialized');
    }

    final textureId = controller.textureId;
    debugPrint(
        '🎬 GifMarkerManager: Getting frame from texture ID: $textureId');

    // Create a widget to display the video
    final videoWidget = Texture(
      textureId: textureId,
    );

    // Convert widget to image
    final boundary = GlobalKey();
    final widget = RepaintBoundary(
      key: boundary,
      child: SizedBox(
        width: 35,
        height: 35,
        child: videoWidget,
      ),
    );

    // Используем BuildContext для рендеринга
    final context = this.context;
    if (!context.mounted) {
      debugPrint('❌ GifMarkerManager: Context is not available');
      throw Exception('Context is not available');
    }
    OverlayEntry? overlay;
    try {
      debugPrint('🎬 GifMarkerManager: Converting widget to image');

      // Создаем OverlayEntry для временного добавления виджета
      overlay = OverlayEntry(
        builder: (context) => widget,
      );

      // Добавляем виджет в оверлей
      Overlay.of(context).insert(overlay);

      // Даем время на рендеринг
      await Future.delayed(const Duration(milliseconds: 50));

      final renderObject = boundary.currentContext?.findRenderObject();
      if (renderObject == null) {
        debugPrint('❌ GifMarkerManager: RenderObject is null');
        throw Exception('RenderObject is null');
      }

      final renderBoundary = renderObject as RenderRepaintBoundary;
      final ui.Image image = await renderBoundary.toImage(pixelRatio: 1.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('❌ GifMarkerManager: Failed to convert frame to bytes');
        throw Exception('Failed to convert frame to bytes');
      }

      debugPrint('🎬 GifMarkerManager: Successfully converted frame to bytes');
      return byteData.buffer.asUint8List();
    } finally {
      // Удаляем оверлей
      overlay?.remove();
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
