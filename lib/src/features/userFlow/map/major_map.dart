import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
import 'package:tap_map/src/features/userFlow/map/styles/bloc/map_styles_bloc.dart';

class MapStyleButtons extends StatelessWidget {
  const MapStyleButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final mapStyleBloc = BlocProvider.of<MapStyleBloc>(context);

    return BlocBuilder<MapStyleBloc, MapStyleState>(
      buildWhen: (previous, current) => current
          is! MapStyleUpdateSuccess, // Чтобы не пересоздавать кнопки при смене стиля
      builder: (context, state) {
        if (state is MapStyleLoading) {
          return const CircularProgressIndicator();
        } else if (state is MapStyleSuccess) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Чтобы не занимало весь экран
              children: state.mapStyles.map((style) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ElevatedButton(
                    onPressed: () {
                      mapStyleBloc.add(UpdateMapStyleEvent(
                        newStyleId: style.id!,
                        uriStyle: style.styleUrl!,
                      ));
                    },
                    child: Text(style.name!),
                  ),
                );
              }).toList(),
            ),
          );
        } else if (state is MapStyleError) {
          return const Text("Failed to load styles");
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class MajorMap extends StatefulWidget {
  const MajorMap({super.key});

  @override
  State<MajorMap> createState() => _MajorMapState();
}

class _MajorMapState extends State<MajorMap> {
  mp.MapboxMap? mapboxMapController;
  StreamSubscription? userPositionStream;

  @override
  void initState() {
    super.initState();
    _setupPositionTracking();

    // Fetch map styles at the start
    Future.microtask(() {
      BlocProvider.of<MapStyleBloc>(context).add(FetchMapStylesEvent());
    });
  }

  @override
  void dispose() {
    userPositionStream?.cancel();
    super.dispose();
  }

  void _onStyleLoadedCallback(mp.MapLoadedEventData data) async {
    if (mapboxMapController != null) {
      await mapboxMapController?.style.addSource(mp.VectorSource(
        id: "places_source",
        tiles: ["https://map-travel.net/tilesets/data/tiles/{z}/{x}/{y}.pbf"],
        minzoom: 0,
        maxzoom: 20,
      ));

      await mapboxMapController?.style.addLayer(mp.CircleLayer(
        id: "places_circle_layer",
        sourceId: "places_source",
        sourceLayer: "mylayer",
        circleRadius: 3.0,
        circleOpacity: 0.8,
        circleStrokeWidth: 1.0,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MapStyleBloc, MapStyleState>(
      listener: (context, state) {
        if (state is MapStyleUpdateSuccess) {
          _updateMapStyle(state.styleUri);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            mp.MapWidget(
              styleUri: mp.MapboxStyles.MAPBOX_STREETS,
              cameraOptions: mp.CameraOptions(
                center: mp.Point(coordinates: mp.Position(98.360473, 7.886778)),
                zoom: 11.0,
              ),
              onMapCreated: _onMapCreated,
              onMapLoadedListener: _onStyleLoadedCallback,
            ),
            Positioned(
              bottom: 80,
              left: 20,
              child: const MapStyleButtons(),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: _centerOnUserLocation,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(mp.MapboxMap controller) {
    setState(() {
      mapboxMapController = controller;
    });

    mapboxMapController?.location.updateSettings(
      mp.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ),
    );
  }

  Future<void> _setupPositionTracking() async {
    bool serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    gl.LocationPermission permission = await gl.Geolocator.checkPermission();
    if (permission == gl.LocationPermission.denied) {
      permission = await gl.Geolocator.requestPermission();
      if (permission == gl.LocationPermission.denied ||
          permission == gl.LocationPermission.deniedForever) {
        return;
      }
    }

    gl.Position position = await gl.Geolocator.getCurrentPosition();
    _moveCameraToPosition(position);
  }

  Future<void> _centerOnUserLocation() async {
    gl.LocationPermission permission = await gl.Geolocator.checkPermission();
    if (permission == gl.LocationPermission.denied ||
        permission == gl.LocationPermission.deniedForever) {
      permission = await gl.Geolocator.requestPermission();
      if (permission == gl.LocationPermission.denied) {
        return;
      }
    }

    gl.Position position = await gl.Geolocator.getCurrentPosition();
    _moveCameraToPosition(position);
  }

  void _moveCameraToPosition(gl.Position position) {
    if (mapboxMapController != null) {
      mapboxMapController?.setCamera(mp.CameraOptions(
        zoom: 14,
        center: mp.Point(
          coordinates: mp.Position(position.longitude, position.latitude),
        ),
      ));
    }
  }

  Future<void> _updateMapStyle(String newStyle) async {
    if (mapboxMapController != null) {
      await mapboxMapController?.style.setStyleURI(newStyle);
    }
  }
}
