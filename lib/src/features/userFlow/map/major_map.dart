import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
import 'package:tap_map/src/features/userFlow/map/styles/bloc/map_styles_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/icons/bloc/icons_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/icons/icons_responce_modal.dart';
import 'package:tap_map/src/features/userFlow/map/widgets/map_style_buttons.dart';

class MajorMap extends StatefulWidget {
  const MajorMap({Key? key}) : super(key: key);

  @override
  State<MajorMap> createState() => _MajorMapState();
}

class _MajorMapState extends State<MajorMap> {
  mp.MapboxMap? mapboxMapController;
  StreamSubscription? userPositionStream;
  final Map<String, bool> loadedIcons = {};
  int? currentStyleId;

  @override
  void initState() {
    super.initState();
    _setupPositionTracking();

    // При старте загружаем стили карты
    Future.microtask(() {
      context.read<MapStyleBloc>().add(FetchMapStylesEvent());
    });
  }

  @override
  void dispose() {
    userPositionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<IconsBloc, IconsState>(
          listener: (context, state) {
            if (state is IconsLoading) {
              debugPrint('🔄 Загрузка иконок...');
            } else if (state is IconsSuccess) {
              debugPrint(
                  '✅ Список иконок получен. Начинаем загрузку в MapBox...');
              _loadIcons(state.icons);
            } else if (state is IconsError) {
              debugPrint('❌ Ошибка загрузки иконок: ${state.message}');
            }
          },
        ),
        BlocListener<MapStyleBloc, MapStyleState>(
          listener: (context, state) {
            if (state is MapStyleUpdateSuccess) {
              _updateMapStyle(state.styleUri);
              currentStyleId = state.newStyleId;
              context
                  .read<IconsBloc>()
                  .add(FetchIconsEvent(styleId: state.newStyleId));
            }
          },
        ),
      ],
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
            const Positioned(
              bottom: 80,
              left: 20,
              child:  MapStyleButtons(),
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

  Future<void> _onStyleLoadedCallback(mp.MapLoadedEventData data) async {
    if (mapboxMapController == null) return;

    await _addSourceAndLayers();

    if (currentStyleId != null) {
      context.read<IconsBloc>().add(FetchIconsEvent(styleId: currentStyleId!));
    } else {
    }
  }

  Future<void> _addSourceAndLayers() async {
    await mapboxMapController?.style.addSource(
      mp.VectorSource(
        id: "places_source",
        tiles: ["https://map-travel.net/tilesets/data/tiles/{z}/{x}/{y}.pbf"],
        minzoom: 0,
        maxzoom: 20,
      ),
    );

    await mapboxMapController?.style.addLayer(
      mp.SymbolLayer(
        id: "places_symbol_layer",
        sourceId: "places_source",
        sourceLayer: "mylayer",
        iconImage: "{subcategory}",
        iconSize: 0.4,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        textField: "{subcategory}",
        textFont: ["DIN Offc Pro Medium"],
        textSize: 12.0,
        textAnchor: mp.TextAnchor.TOP,
        textColor: Colors.white.value,
        textHaloColor: Colors.black.withOpacity(0.75).value,
        textHaloWidth: 2.0,
        textHaloBlur: 0.5,
      ),
    );
  }

  Future<void> _loadIcons(List<IconsResponseModel> icons) async {
    if (mapboxMapController == null) return;
    debugPrint('🔄 Загружаем ${icons.length} иконок...');

    List<Future<void>> tasks = [];
    for (final icon in icons) {
      final iconKey = icon.name;
      final iconUrl = icon.logo.logoUrl;

      if (loadedIcons.containsKey(iconKey)) {
        continue;
      }
      tasks.add(_loadSingleIcon(iconKey, iconUrl));
    }

    await Future.wait(tasks);
    debugPrint('✅ Все иконки загружены!');
  }

  Future<void> _loadSingleIcon(String iconName, String url) async {
    try {
      final Uint8List? rawBytes =
          await NetworkAssetManager().downloadImage(url);
      if (rawBytes == null || rawBytes.isEmpty) {
        debugPrint('❌ Ошибка загрузки иконки $iconName: байты пустые');
        return;
      }

      final ui.Codec codec = await ui.instantiateImageCodec(rawBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image decodedImage = frameInfo.image;

      final ByteData? byteData =
          await decodedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        debugPrint('❌ Не удалось конвертировать $iconName в PNG');
        return;
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final mp.MbxImage mbxImage = mp.MbxImage(
        width: decodedImage.width,
        height: decodedImage.height,
        data: pngBytes,
      );

      await mapboxMapController?.style.addStyleImage(
        iconName,
        1.0,
        mbxImage,
        false,
        [],
        [],
        null,
      );

      loadedIcons[iconName] = true;
      debugPrint('✅ Иконка $iconName добавлена!');
    } catch (e, stackTrace) {
      debugPrint('❌ Ошибка в _loadSingleIcon($iconName): $e');
      debugPrint('StackTrace: $stackTrace');
    }
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
    mapboxMapController?.setCamera(
      mp.CameraOptions(
        zoom: 14,
        center: mp.Point(
          coordinates: mp.Position(position.longitude, position.latitude),
        ),
      ),
    );
  }

  Future<void> _updateMapStyle(String newStyle) async {
    await mapboxMapController?.style.setStyleURI(newStyle);
  }
}

class NetworkAssetManager {
  Future<Uint8List?> downloadImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      debugPrint('⬇️ Downloading image from: $uri');

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
        debugPrint('Headers: ${response.headers}');
        throw Exception('HTTP status: ${response.statusCode}');
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
      debugPrint('✅ Downloaded ${bytes.length} bytes from $uri');
      return bytes;
    } catch (e, stackTrace) {
      debugPrint('❌ Error downloading image: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}
