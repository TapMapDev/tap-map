import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
import 'package:video_player/video_player.dart';

class GifMarkerManager {
  final mp.MapboxMap mapboxMap;
  final Map<String, _GifMarkerData> _markersById = {};
  Timer? _zoomCheckTimer;

  GifMarkerManager({required this.mapboxMap});

  void initialize() {
    _setupZoomChecker();
    _createGifMarkers();
  }

  void dispose() {
    _zoomCheckTimer?.cancel();
    _disposeAllMarkers();
  }

  Future<void> _createGifMarkers() async {
    try {
      // Query features from the source
      final features = await mapboxMap.querySourceFeatures(
        "places_source",
        mp.SourceQueryOptions(
          filter: jsonEncode(["has", "marker_type"]),
        ),
      );

      for (final feature in features) {
        if (feature == null) continue;

        // Parse feature data
        final featureJson = jsonDecode(feature.queriedFeature.toString())
            as Map<String, dynamic>;
        final props = featureJson['properties'] as Map<String, dynamic>?;
        if (props == null) continue;

        final id = featureJson['id']?.toString();
        if (id == null) continue;

        // Check if marker_type is a WebM video URL
        final markerType = props['marker_type']?.toString();
        if (markerType == null || !markerType.endsWith('.webm')) continue;

        // Skip if marker already exists
        if (_markersById.containsKey(id)) continue;

        // Create video player
        final videoController = VideoPlayerController.network(markerType);
        await videoController.initialize();
        videoController.setLooping(true);
        videoController.setVolume(0.0);
        videoController.play();

        // Get coordinates from geometry
        final geometry = featureJson['geometry'] as Map<String, dynamic>?;
        if (geometry == null) continue;

        final coordinates = geometry['coordinates'] as List<dynamic>?;
        if (coordinates == null || coordinates.length != 2) continue;

        // Create symbol layer for the video marker
        final symbolLayer = mp.SymbolLayer(
          id: "video_marker_$id",
          sourceId: "places_source",
          iconSize: 1.0,
          iconAllowOverlap: true,
        );

        await mapboxMap.style.addLayer(symbolLayer);

        // Store marker data
        _markersById[id] = _GifMarkerData(
          id: id,
          videoController: videoController,
          coordinates: mp.Point(
            coordinates: mp.Position(
              coordinates[0] as double,
              coordinates[1] as double,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating GIF markers: $e');
    }
  }

  void _setupZoomChecker() {
    // Check zoom level every 100ms
    _zoomCheckTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      try {
        mapboxMap.getCameraState().then((cameraState) {
          final zoom = cameraState.zoom;
          final scale = _getGifScale(zoom);
          _updateMarkersScale(scale);
        });
      } catch (e) {
        debugPrint('Ошибка при получении состояния камеры: $e');
      }
    });
  }

  double _getGifScale(double zoom) {
    // Implement your scaling logic here based on zoom level
    // This is a simple example, adjust the formula as needed
    return 0.5 + (zoom / 20);
  }

  void _updateMarkersScale(double scale) {
    for (final entry in _markersById.entries) {
      final id = entry.key;
      try {
        mapboxMap.style.setStyleLayerProperty(
          "video_marker_$id",
          "icon-size",
          scale.toString(),
        );
      } catch (e) {
        debugPrint('Error updating scale for marker $id: $e');
      }
    }
  }

  void _disposeAllMarkers() {
    for (final entry in _markersById.entries) {
      final id = entry.key;
      entry.value.videoController.dispose();
      try {
        mapboxMap.style.removeStyleLayer("video_marker_$id");
      } catch (e) {
        debugPrint('Error removing marker layer $id: $e');
      }
    }
    _markersById.clear();
  }
}

class _GifMarkerData {
  final String id;
  final VideoPlayerController videoController;
  final mp.Point coordinates;

  _GifMarkerData({
    required this.id,
    required this.videoController,
    required this.coordinates,
  });
}
