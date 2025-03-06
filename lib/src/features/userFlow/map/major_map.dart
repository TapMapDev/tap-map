import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
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
  // Используем константу для ID слоя
  static const String placesLayerId = "places_symbol_layer";

  /// Позиция пользователя до создания карты
  gl.Position? _initialUserPosition;

  /// Флаг готовности локации
  bool isLocationLoaded = false;

  /// Флаг готовности стиля
  bool isStyleLoaded = false;

  /// Словарь "имя_иконки -> уже_загружено?"
  final Map<String, bool> loadedIcons = {};

  /// Сохранённый styleId
  int? currentStyleId;

  /// Сохранённый styleUri
  late String mapStyleUri;

  @override
  void initState() {
    super.initState();
    _loadSavedMapStyle(); // 1) Грузим стиль
    _setupPositionTracking(); // 2) Локация
    // 3) Запрашиваем список стилей
    Future.microtask(() {
      context.read<MapStyleBloc>().add(FetchMapStylesEvent());
    });
  }

  /// Грузим сохранённый стиль (URL + ID) из SharedPrefs
  Future<void> _loadSavedMapStyle() async {
    final prefs = getIt.get<SharedPrefsRepository>();
    final savedStyle = await prefs.getSavedMapStyle();
    final savedStyleId = await prefs.getMapStyleId();

    setState(() {
      mapStyleUri = savedStyle ?? mp.MapboxStyles.MAPBOX_STREETS;
      currentStyleId = savedStyleId;
      isStyleLoaded = true;
    });

    // Если нужно загрузить иконки заранее
    if (currentStyleId != null) {
      context.read<IconsBloc>().add(FetchIconsEvent(styleId: currentStyleId!));
    }
  }

  List<Object> _convertHexToRGBA(String hexColor) {
    hexColor = hexColor.replaceFirst('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    int hexValue = int.parse(hexColor, radix: 16);
    Color color = Color(hexValue);
    return ["rgba", color.red, color.green, color.blue, 1.0];
  }

  /// Запрос геолокации
  Future<void> _setupPositionTracking() async {
    await Future.delayed(Duration(milliseconds: 500));
    final serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    gl.LocationPermission permission = await gl.Geolocator.checkPermission();
    if (permission == gl.LocationPermission.denied) {
      permission = await gl.Geolocator.requestPermission();
      if (permission == gl.LocationPermission.denied ||
          permission == gl.LocationPermission.deniedForever) {
        return;
      }
    }

    final position = await gl.Geolocator.getCurrentPosition();
    setState(() {
      _initialUserPosition = position;
      isLocationLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isStyleLoaded || !isLocationLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<IconsBloc, IconsState>(
          listener: (context, state) async {
            if (state is IconsLoading) {
              debugPrint('🔄 Загрузка иконок...');
            } else if (state is IconsSuccess) {
              debugPrint('✅ Иконки получены. Загружаем в MapBox...');
              await _loadIcons(state.icons, styleId: state.styleId);

              final textColorExpression =
                  buildTextColorExpression(state.textColors);
              try {
                await mapboxMapController?.style.setStyleLayerProperty(
                  placesLayerId,
                  "text-color",
                  textColorExpression,
                );
                debugPrint("✅ Цвет текста обновлён!");
              } catch (e, st) {
                debugPrint("❌ Ошибка обновления цвета текста: $e\n$st");
              }
            }
          },
        ),
        BlocListener<MapStyleBloc, MapStyleState>(
          listener: (context, state) async {
            if (state is MapStyleUpdateSuccess) {
              await _updateMapStyle(state.styleUri);
              currentStyleId = state.newStyleId;
              await _clearIcons();
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
              styleUri: mapStyleUri,
              cameraOptions: mp.CameraOptions(
                center: _initialUserPosition != null
                    ? mp.Point(
                        coordinates: mp.Position(
                          _initialUserPosition!.longitude,
                          _initialUserPosition!.latitude,
                        ),
                      )
                    : mp.Point(coordinates: mp.Position(98.360473, 7.886778)),
                zoom: 14.0,
              ),
              onMapCreated: _onMapCreated,
              onMapLoadedListener: _onStyleLoadedCallback,
              onCameraChangeListener: (eventData) async {
                final cameraState = await mapboxMapController?.getCameraState();
                if (cameraState == null) return;

                final zoom = cameraState.zoom;
                final threshold = getThresholdByZoom(zoom);
                final iconExpression = buildIconImageExpression(threshold);
                final textExpression = buildTextFieldExpression(threshold);
                final layers =
                    await mapboxMapController!.style.getStyleLayers();
                final layerExists =
                    layers.any((layer) => layer?.id == placesLayerId);
                if (!layerExists) {
                  debugPrint(
                      "Слой $placesLayerId не найден. Пропускаем обновление.");
                  return;
                }
                try {
                  await mapboxMapController?.style.setStyleLayerProperty(
                    placesLayerId,
                    "icon-image",
                    iconExpression,
                  );
                } catch (e, st) {
                  debugPrint("❌ Ошибка обновления icon-image: $e\n$st");
                }
                try {
                  await mapboxMapController?.style.setStyleLayerProperty(
                    placesLayerId,
                    "text-field",
                    textExpression,
                  );
                } catch (e, st) {
                  debugPrint("❌ Ошибка обновления text-field: $e\n$st");
                }
              },
            ),
            const Positioned(
              bottom: 80,
              left: 20,
              child: MapStyleButtons(),
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
    mapboxMapController = controller;
    mapboxMapController?.location.updateSettings(
      mp.LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
  }

  Future<void> _onStyleLoadedCallback(mp.MapLoadedEventData data) async {
    if (mapboxMapController == null) return;
    debugPrint("🗺️ Стиль загружен! Добавляем слои...");
    await _addSourceAndLayers();
    await _loadMyDotIconFromUrl();

    final camState = await mapboxMapController?.getCameraState();
    final currentZoom = camState?.zoom ?? 14.0;
    final threshold = getThresholdByZoom(currentZoom);
    final iconExpr = buildIconImageExpression(threshold);
    final textExpr = buildTextFieldExpression(threshold);

    try {
      await mapboxMapController?.style.setStyleLayerProperty(
        placesLayerId,
        "icon-image",
        iconExpr,
      );
    } catch (e, st) {
      debugPrint("❌ Ошибка установки icon-image: $e\n$st");
    }
    try {
      await mapboxMapController?.style.setStyleLayerProperty(
        placesLayerId,
        "text-field",
        textExpr,
      );
    } catch (e, st) {
      debugPrint("❌ Ошибка установки text-field: $e\n$st");
    }

    if (currentStyleId != null) {
      context.read<IconsBloc>().add(FetchIconsEvent(styleId: currentStyleId!));
    }
  }

  List<Object> buildTextColorExpression(Map<String, String> textColors) {
    List<Object> matchExpression = [
      "match",
      ["get", "subcategory"],
    ];

    textColors.forEach((subcategory, color) {
      matchExpression.add(subcategory);
      matchExpression.add(_convertHexToRGBA(color));
    });
    matchExpression.add(["rgba", 255, 255, 255, 1.0]);
    return matchExpression;
  }

  /// Добавляем источник и SymbolLayer, если его ещё нет
  Future<void> _addSourceAndLayers() async {
    if (mapboxMapController == null) return;
    try {
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
          id: placesLayerId,
          sourceId: "places_source",
          sourceLayer: "mylayer",
          iconImage: "my_dot_icon",
          iconSize: 0.25,
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          // iconAllowOverlapExpression: ["literal", true],
          textField: "",
          textFont: ["DIN Offc Pro Medium"],
          textSizeExpression: <Object>[
            "interpolate",
            ["linear"],
            ["zoom"],
            5,
            3,
            18,
            14
          ],
          textOffsetExpression: <Object>[
            'interpolate',
            ['linear'],
            ['zoom'],
            5,
            [
              'literal',
              [0, 1.85]
            ],
            18,
            [
              'literal',
              [0, 0.75]
            ]
          ],
          textAnchor: mp.TextAnchor.TOP,
          textColor: Colors.white.value,
          textHaloColor: Colors.black.withOpacity(0.75).value,
          textHaloWidth: 2.0,
          textHaloBlur: 0.5,

        ),
      );
      debugPrint("✅ Источник и слой $placesLayerId добавлены");
    } catch (e, st) {
      debugPrint("❌ Ошибка при добавлении источника и слоя: $e\n$st");
    }
  }

  Future<void> _clearIcons() async {
    if (mapboxMapController == null) return;
    debugPrint('🔄 Удаляем старые иконки...');
    for (final iconKey in loadedIcons.keys) {
      try {
        await mapboxMapController?.style.removeStyleImage(iconKey);
      } catch (e) {
        debugPrint("Ошибка удаления иконки $iconKey: $e");
      }
    }
    loadedIcons.clear();
    debugPrint('✅ Все старые иконки удалены!');
  }

  Future<void> _loadIcons(List<IconsResponseModel> icons,
      {required int styleId}) async {
    if (mapboxMapController == null) return;
    debugPrint('🔄 Загружаем ${icons.length} иконок для styleId=$styleId...');
    final tasks = <Future<void>>[];
    for (final icon in icons) {
      final iconName = icon.name;
      final iconUrl = icon.logo.logoUrl;
      if (loadedIcons.containsKey(iconName)) {
        debugPrint('⚠️ Иконка $iconName уже загружена');
        continue;
      }
      tasks.add(_loadSingleIcon(iconName, iconUrl, styleId));
    }
    await Future.wait(tasks);
    debugPrint('✅ Все иконки загружены для styleId=$styleId!');
  }

  Future<void> _loadMyDotIconFromUrl() async {
    if (mapboxMapController == null) return;
    try {
      const iconUrl =
          "https://tap-maptravel.s3.ap-southeast-2.amazonaws.com/media/svgs/circle/%D0%9A%D1%80%D1%83%D0%B3_rdr.png";
      final downloaded = await NetworkAssetManager().downloadImage(iconUrl);
      if (downloaded == null || downloaded.isEmpty) return;
      final ui.Codec codec = await ui.instantiateImageCodec(downloaded);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image decodedImage = frameInfo.image;
      final byteData =
          await decodedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final mp.MbxImage mbxImage = mp.MbxImage(
        width: decodedImage.width,
        height: decodedImage.height,
        data: pngBytes,
      );
      await mapboxMapController?.style.addStyleImage(
        "my_dot_icon",
        1.0,
        mbxImage,
        false,
        [],
        [],
        null,
      );
      debugPrint('✅ my_dot_icon зарегистрирован!');
    } catch (e, st) {
      debugPrint('❌ Ошибка при загрузке my_dot_icon: $e\n$st');
    }
  }

  Future<void> _loadSingleIcon(String iconName, String url, int styleId) async {
    if (mapboxMapController == null) return;
    try {
      final compositeKey = '$styleId-$iconName';
      final prefs = getIt.get<SharedPrefsRepository>();
      final cached = await prefs.getIconBytes(compositeKey);
      Uint8List? finalBytes;

      if (cached != null && cached.isNotEmpty) {
        finalBytes = cached;
        debugPrint('💾 Иконка $iconName найдена в кэше');
      } else {
        final downloaded = await NetworkAssetManager().downloadImage(url);
        if (downloaded == null || downloaded.isEmpty) return;
        finalBytes = downloaded;
        await prefs.saveIconBytes(compositeKey, downloaded);
      }

      final ui.Codec codec = await ui.instantiateImageCodec(finalBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image decodedImage = frameInfo.image;
      final byteData =
          await decodedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
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
    } catch (e, st) {
      debugPrint('❌ Ошибка в _loadSingleIcon($iconName): $e\n$st');
    }
  }

  Future<void> _updateMapStyle(String newStyle) async {
    if (mapboxMapController == null) return;
    debugPrint("🔄 Меняем стиль карты на: $newStyle...");
    try {
      await mapboxMapController!.style.setStyleURI(newStyle);
    } catch (e, st) {
      debugPrint("❌ Ошибка смены стиля: $e\n$st");
    }
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (mapboxMapController != null) {
        debugPrint("✅ Новый стиль загружен! Пересоздаём источники...");
        await _addSourceAndLayers();
      }
    });
    getIt.get<SharedPrefsRepository>().saveMapStyle(newStyle);
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
    final position = await gl.Geolocator.getCurrentPosition();
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

  double getThresholdByZoom(double zoom) {
    // Определяем диапазон зума, где будет происходить переход (например, от 14 до 16)
    const double zoomStart = 14.0;
    const double zoomEnd = 16.0;
    // Порог, при котором объекты полностью скрыты (при минимальном зуме)
    const double maxThreshold = 500.0;
    // Порог, при котором объекты полностью отображаются (при максимальном зуме)
    const double minThreshold = 0.0;

    if (zoom <= zoomStart) {
      return maxThreshold;
    } else if (zoom >= zoomEnd) {
      return minThreshold;
    } else {
      // Линейная интерполяция между maxThreshold и minThreshold
      final t = (zoom - zoomStart) / (zoomEnd - zoomStart);
      return maxThreshold * (1 - t) + minThreshold * t;
    }
  }

  List<Object> buildIconImageExpression(double threshold) {
    return [
      "let",
      "myThreshold",
      threshold,
      [
        "case",
        [
        "<",
          [
            "to-number",
            ["coalesce", ["get", "min_dist"], 0]
          ],
          ["var", "myThreshold"]
        ],
        "my_dot_icon",
        ["get", "subcategory"]
      ]
    ];
  }

 List<Object> buildTextFieldExpression(double threshold) {
    return [
      "let",
      "myThreshold",
      threshold,
      [
        "case",
        [
          "<",
          [
            "to-number",
            ["coalesce", ["get", "min_dist"], 0]
          ],
          ["var", "myThreshold"]
        ],
        "",
        ["get", "name"]
      ]
    ];
  }
}

/// Класс для скачивания изображений
class NetworkAssetManager {
  Future<Uint8List?> downloadImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      debugPrint('⬇️ Downloading $uri');
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('HTTP error: ${response.statusCode}');
      }
      final bytes = await consolidateHttpClientResponseBytes(response);
      debugPrint('✅ Got ${bytes.length} bytes from $uri');
      return bytes;
    } catch (e, st) {
      debugPrint('❌ Error: $e\n$st');
      return null;
    }
  }
}
