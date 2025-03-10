// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
// import 'package:video_player/video_player.dart';

// class GifMarkerManager {
//   final mp.MapboxMap mapboxMap;
//   final Map<String, _VideoMarker> _videoMarkers = {};
//   final Duration _animationInterval = const Duration(milliseconds: 500);

//   GifMarkerManager({required this.mapboxMap});

//   void initialize() {
//     _queryFeatures();
//     _setupAnimation();
//   }

// void _queryFeatures() async {
//   final features = await mapboxMap.querySourceFeatures(
//     'places_source',
//     mp.SourceQueryOptions(sourceLayerIds: ['mylayer'], filter: ''),
//   );

//   for (var queriedFeature in features) {
//     debugPrint("🛠 Queried feature: $queriedFeature");

//     // Доступ к feature
//     final feature = queriedFeature!.feature;
//     if (feature == null) continue;

//     final props = feature.properties; // Попробуем так
//     final geom = feature.geometry as mp.Point?;
//     final id = feature.featureId;

//     if (props == null || geom == null || id == null) continue;

//     debugPrint("✅ Найден объект: id=$id, props=$props");

//     final markerType = props['marker_type'] as String?;
//     if (markerType?.endsWith('.webm') != true) continue;

//     _createVideoMarker(id, geom.coordinates, markerType!);
//   }
// }
//   void _createVideoMarker(String id, mp.Position coords, String videoUrl) async {
//     if (_videoMarkers.containsKey(id)) return;

//     final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
//       ..initialize().then((_) {
//         controller.setLooping(true);
//         controller.play();
//       });

//     final overlayController = mp.OverlaySurfaceController();
    
//     mapboxMap.addSurface(
//       overlayController,
//       mp.SurfaceOptions(
//         location: coords,
//         width: 35,
//         height: 35,
//         anchor: mp.Anchor.MAP,
//       ),
//     );

//     overlayController.add(
//       VideoPlayer(controller),
//     );

//     _videoMarkers[id] = _VideoMarker(
//       controller: controller,
//       overlayController: overlayController,
//       popupData: _PopupData(
//         id: props['id'] as String?,
//         name: props['name'] as String?,
//         description: props['description'] as String?,
//       ),
//     );

//     _setupMarkerInteractions(id, coords);
//   }

//   void _setupMarkerInteractions(String id, Position coords) {
//     final marker = _videoMarkers[id];
//     if (marker == null) return;

//     // Обработка кликов (через queryRenderedFeatures)
//     mapboxMap.setOnMapClickListener((point) async {
//       final features = await mapboxMap.queryRenderedFeatures(
//         point,
//         mp.RenderedQueryOptions(layerIds: placesLayerId),
//       );

//       for (var feature in features) {
//         if (feature!.id == id) {
//           _showPopup(marker.popupData, coords);
//           return true;
//         }
//       }
//       return false;
//     });
//   }

//   void _showPopup(_PopupData data, Position coords) {
//     // Реализация показа попапа через showDialog
//   }

//   void _setupAnimation() {
//     // Для анимированных GIF-иконок
//     // (если используете кадры вместо видео)
//   }

//   void dispose() {
//     for (var marker in _videoMarkers.values) {
//       marker.controller.dispose();
//     }
//   }
// }

// class _VideoMarker {
//   final VideoPlayerController controller;
//   final mp.OverlaySurfaceController overlayController;
//   final _PopupData popupData;

//   _VideoMarker({
//     required this.controller,
//     required this.overlayController,
//     required this.popupData,
//   });
// }

// class _PopupData {
//   final String? id;
//   final String? name;
//   final String? description;

//   _PopupData({this.id, this.name, this.description});
// }