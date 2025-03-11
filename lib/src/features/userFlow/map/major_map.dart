import 'dart:async';
import 'dart:convert';
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
import 'package:tap_map/src/features/userFlow/map/gif_marker_manager.dart';
import 'package:tap_map/src/features/userFlow/map/icons/bloc/icons_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/icons/icons_responce_modal.dart';
import 'package:tap_map/src/features/userFlow/map/styles/bloc/map_styles_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/widgets/geo_location.dart';
import 'package:tap_map/src/features/userFlow/map/widgets/location_service.dart';
import 'package:tap_map/src/features/userFlow/map/widgets/map_style_buttons.dart';

class MajorMap extends StatefulWidget {
  const MajorMap({super.key});

  @override
  State<MajorMap> createState() => _MajorMapState();
}

class _MajorMapState extends State<MajorMap> {
  mp.MapboxMap? mapboxMapController;
  // Используем константу для ID слоя
  static const String placesLayerId = "places_symbol_layer";
  GifMarkerManager? _gifMarkerManager;

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
    Future.delayed(const Duration(milliseconds: 500)).then((_) async {
      final position = await LocationService.getUserPosition();
      if (position != null && mounted) {
        setState(() {
          _initialUserPosition = position;
          isLocationLoaded = true;
        });
      }
    });
    // 3) Запрашиваем список стилей
    Future.microtask(() {
      context.read<MapStyleBloc>().add(FetchMapStylesEvent());
    });

    // Start periodic updates of open/close states
    Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && mapboxMapController != null) {
        updateOpenCloseStates();
      }
    });
    _gifMarkerManager;
  }

  @override
  void dispose() {
    _gifMarkerManager?.dispose();
    super.dispose();
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

              Future.delayed(const Duration(milliseconds: 500), () {
                context.read<MapStyleBloc>().add(ResetMapStyleEvent());
              });
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
                // await updateOpenCloseStates();
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
              top: 30,
              right: 13,
              child: MapStyleButton(),
            ),
            if (mapboxMapController != null)
              Positioned(
                  bottom: 14,
                  right: 13,
                  child: GeoLocationButton(
                      mapboxMapController: mapboxMapController)),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(mp.MapboxMap controller) {
    setState(() {
      mapboxMapController = controller;
      _gifMarkerManager = GifMarkerManager(mapboxMap: controller);
    });
    mapboxMapController?.location.updateSettings(
      mp.LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
    mapboxMapController?.scaleBar.updateSettings(
      mp.ScaleBarSettings(enabled: false),
    );
    mapboxMapController?.compass.updateSettings(
      mp.CompassSettings(enabled: false),
    );
    mapboxMapController?.attribution.updateSettings(
      mp.AttributionSettings(enabled: false),
    );
  }

  /// Обработчик тапа по карте: асинхронно запрашиваем фичи, выводим свойства
// Future<void> _handleMapTap(mp.ScreenCoordinate point) async {
//   if (mapboxMapController == null) return;

//   try {
//     final features = await mapboxMapController!.queryRenderedFeatures(
//       point,
//       mp.RenderedQueryOptions(
//         layers: ['places_symbol_layer'],
//         filter: null,
//       ),
//     );

//     if (features.isNotEmpty) {
//       for (final feature in features) {
//         final featureId = feature.id ?? 'no_id';
//         final props = feature.properties;
//         debugPrint('Тап по фиче: id=$featureId');
//         debugPrint('Свойства: $props');
//       }
//     } else {
//       debugPrint('Никаких фич на точке тапа не найдено.');
//     }
//   } catch (e, st) {
//     debugPrint('Ошибка при обработке тапа: $e\n$st');
//   }
// }
// }

  Future<void> _onStyleLoadedCallback(mp.MapLoadedEventData data) async {
    if (mapboxMapController == null) return;
    debugPrint("🗺️ Стиль загружен! Добавляем слои...");
    await _loadMyDotIconFromUrl();
    await _addSourceAndLayers();
    final styleLayers = await mapboxMapController?.style.getStyleLayers();
    final layerExists =
        styleLayers?.any((layer) => layer?.id == placesLayerId) ?? false;
    if (!layerExists) {
      debugPrint("Слой $placesLayerId не появился!");
      return;
    }

    // Initialize GIF markers after layers are added
    _gifMarkerManager?.initialize();

    await updateOpenCloseStates();

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
      // Проверяем существование источника
      final sources = await mapboxMapController!.style.getStyleSources();
      final layers = await mapboxMapController!.style.getStyleLayers();

      final sourceExists =
          sources.any((source) => source?.id == "places_source");

      if (!sourceExists) {
        await mapboxMapController?.style.addSource(
          mp.VectorSource(
            id: "places_source",
            tiles: [
              "https://map-travel.net/tilesets/data/tiles/{z}/{x}/{y}.pbf"
            ],
            minzoom: 0,
            maxzoom: 20,
          ),
        );
        debugPrint("✅ Источник places_source добавлен");
      } else {
        debugPrint("ℹ️ Источник places_source уже существует");
      }

      // Добавляем источник для видео-маркеров
      final videoSourceExists =
          sources.any((source) => source?.id == "video_markers_source");
      if (!videoSourceExists) {
        await mapboxMapController?.style.addSource(
          mp.GeoJsonSource(
            id: "video_markers_source",
            data: jsonEncode({"type": "FeatureCollection", "features": []}),
          ),
        );
        debugPrint("✅ Источник video_markers_source добавлен");
      }

      // Проверяем существование слоя для видео
      final videoLayerExists =
          layers.any((layer) => layer?.id == "video_markers_layer");
      if (!videoLayerExists) {
        await mapboxMapController?.style.addLayer(
          mp.SymbolLayer(
            id: "video_markers_layer",
            sourceId: "video_markers_source",
            minZoom: 0,
            maxZoom: 22,
            iconAllowOverlap: true,
            iconIgnorePlacement: true,
            symbolSortKey: 1, // Размещаем под основным слоем
          ),
        );
        debugPrint("✅ Слой video_markers_layer добавлен");
      }

      // Проверяем существование основного слоя
      final layerExists = layers.any((layer) => layer?.id == placesLayerId);

      if (!layerExists) {
        await mapboxMapController?.style.addLayer(
          mp.SymbolLayer(
            id: placesLayerId,
            sourceId: "places_source",
            sourceLayer: "mylayer",
            iconImageExpression: <Object>[
              "let",
              "myThreshold",
              500,
              [
                "case",
                [
                  "<",
                  [
                    "to-number",
                    [
                      "coalesce",
                      ["get", "min_dist"],
                      0
                    ]
                  ],
                  ["var", "myThreshold"]
                ],
                "my_dot_icon",
                ["get", "subcategory"]
              ]
            ],
            iconSize: 0.3,
            iconAllowOverlap: true,
            textAllowOverlap: false,
            textOptional: true,
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
            symbolSortKey: 2, // Размещаем над слоем видео
          ),
        );
        debugPrint("✅ Слой $placesLayerId добавлен");
      } else {
        debugPrint("ℹ️ Слой $placesLayerId уже существует");
      }

      // Обновляем opacity для существующего слоя
      if (layerExists) {
        await mapboxMapController?.style.setStyleLayerProperty(
          placesLayerId,
          'icon-opacity',
          buildIconOpacityExpression(),
        );
        debugPrint("✅ Opacity слоя обновлен");
      }
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

      // Обновляем opacity для иконок
      await mapboxMapController?.style
          .setStyleLayerProperty(placesLayerId, 'icon-opacity', [
        "case",
        [
          "boolean",
          ["feature-state", "closed"],
          false
        ],
        0.7, // если closed = true
        1.0 // если closed = false
      ]);
    } catch (e, st) {
      debugPrint('❌ Ошибка в _loadSingleIcon($iconName): $e\n$st');
    }
  }

  Future<void> _updateMapStyle(String newStyle) async {
    if (mapboxMapController == null) return;
    debugPrint("🔄 Меняем стиль карты на: $newStyle...");

    try {
      await mapboxMapController!.style.setStyleURI(newStyle);
      await Future.delayed(const Duration(milliseconds: 300));
      await mapboxMapController?.location.updateSettings(
        mp.LocationComponentSettings(enabled: false),
      );
      await _addSourceAndLayers();
      await updateOpenCloseStates();
      await Future.delayed(const Duration(milliseconds: 300));
      await mapboxMapController?.location.updateSettings(
        mp.LocationComponentSettings(enabled: true, pulsingEnabled: true),
      );
      getIt.get<SharedPrefsRepository>().saveMapStyle(newStyle);
    } catch (e, st) {
      debugPrint("❌ Ошибка смены стиля: $e\n$st");
    }
  }

  int _parseTime(String time) {
    final parts = time.split(':').map(int.parse).toList();
    return parts[0] * 60 + parts[1];
  }

// Функция проверки времени работы
  bool isPointClosedNow(String? workingHoursRaw, DateTime now) {
    if (workingHoursRaw == null || workingHoursRaw.isEmpty) return false;

    try {
      final workingHours = jsonDecode(workingHoursRaw) as Map<String, dynamic>;
      final dayOfWeek = now.weekday % 7; // 0=Monday, 6=Sunday (адаптируем к JS)
      final days = [
        'sunday',
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday'
      ];
      final dayKey = days[dayOfWeek];

      final schedule = workingHours[dayKey];
      if (schedule == null) return true; // Нет расписания - закрыто

      if (schedule['is_closed'] == true) return true;
      if (schedule['is_24'] == true) return false;

      final openTimes = List<String>.from(schedule['open_times'] ?? []);
      final closeTimes = List<String>.from(schedule['close_times'] ?? []);

      final nowMinutes = now.hour * 60 + now.minute;

      for (var i = 0; i < openTimes.length; i++) {
        final open = _parseTime(openTimes[i]);
        final close = _parseTime(closeTimes[i]);

        if (open < close) {
          if (nowMinutes >= open && nowMinutes < close) return false;
        } else {
          if (nowMinutes >= open || nowMinutes < close) return false;
        }
      }

      return true; // Ни один интервал не подошел
    } catch (e) {
      print('Ошибка обработки working_hours: $e');
      return false;
    }
  }

  Future<void> updateOpenCloseStates() async {
    if (mapboxMapController == null) return;

    try {
      // Проверяем, загружены ли иконки
      if (loadedIcons.isEmpty) {
        debugPrint(
            "⚠️ Иконки еще не загружены, пропускаем обновление состояний");
        return;
      }

      final now = DateTime.now();
      debugPrint(
          "🔄 Начинаем обновление состояний (${now.hour}:${now.minute})");

      // Получаем информацию о видимой области
      final bounds = await mapboxMapController!.getBounds();
      final zoom = (await mapboxMapController!.getCameraState()).zoom;
      debugPrint("🗺️ Текущий zoom: $zoom");
      debugPrint("🗺️ Видимая область: $bounds");

      // Получаем все features
      final layers = await mapboxMapController!.style.getStyleLayers();
      final sources = await mapboxMapController!.style.getStyleSources();

      debugPrint("\n🔍 Детальная информация о слоях и источниках:");
      for (final source in sources) {
        debugPrint("Source: ${source?.id} (${source?.type})");
        // Пробуем получить больше информации о source
        try {
          final sourceType = await mapboxMapController!.style
              .getStyleSourceProperty(source?.id ?? '', "type");
          final sourceTiles = await mapboxMapController!.style
              .getStyleSourceProperty(source?.id ?? '', "tiles");
          debugPrint("  - Type: $sourceType");
          debugPrint("  - Tiles: $sourceTiles");
        } catch (e) {
          debugPrint("  - Ошибка получения деталей: $e");
        }
      }

      for (final layer in layers) {
        debugPrint("Layer: ${layer?.id} (${layer?.type})");
        if (layer?.id == placesLayerId) {
          try {
            final sourceId = await mapboxMapController!.style
                .getStyleLayerProperty(layer?.id ?? '', "source");
            final sourceLayer = await mapboxMapController!.style
                .getStyleLayerProperty(layer?.id ?? '', "source-layer");
            debugPrint("  - Source: $sourceId");
            debugPrint("  - Source-layer: $sourceLayer");
          } catch (e) {
            debugPrint("  - Ошибка получения деталей слоя: $e");
          }
        }
      }

      // Пробуем запросить features с минимальным фильтром
      debugPrint("\n🔍 Пробуем запросить features...");
      List<mp.QueriedRenderedFeature?> features = [];
      String? sourceIdValue;
      String? sourceLayerValue;

      // Получаем детальную информацию о слое
      if (layers.any((l) => l?.id == placesLayerId)) {
        try {
          final sourceId = await mapboxMapController!.style
              .getStyleLayerProperty(placesLayerId, "source");
          final sourceLayer = await mapboxMapController!.style
              .getStyleLayerProperty(placesLayerId, "source-layer");

          sourceIdValue = sourceId.value?.toString();
          sourceLayerValue = sourceLayer.value?.toString();

          debugPrint("\n🔍 Конфигурация слоя:");
          debugPrint("Source ID: $sourceIdValue");
          debugPrint("Source Layer: $sourceLayerValue");

          // Пробуем получить информацию о векторных слоях
          final vectorLayers = await mapboxMapController!.style
              .getStyleSourceProperty("places_source", "vector_layers");
          debugPrint("Vector Layers: ${vectorLayers.value}");

          // Пробуем запросить features
          features = await mapboxMapController!.queryRenderedFeatures(
            mp.RenderedQueryGeometry(
              type: mp.Type.SCREEN_BOX,
              value: jsonEncode({
                "min": {"x": 0, "y": 0},
                "max": {"x": 10000, "y": 10000}
              }),
            ),
            mp.RenderedQueryOptions(
              layerIds: [placesLayerId],
              filter: null,
            ),
          );

          debugPrint("\n📍 Найдено ${features.length} точек");
        } catch (e) {
          debugPrint("❌ Ошибка при получении информации о слое: $e");
        }
      } else {
        debugPrint("❌ Слой $placesLayerId не найден!");
      }

      // Обрабатываем найденные features
      for (final feature in features) {
        try {
          if (feature == null) continue;

          // Добавляем больше отладочной информации
          // debugPrint("\n📌 Анализ feature:");
          // debugPrint("Type: ${feature.runtimeType}");

          // Получаем данные из feature
          final featureData = feature.queriedFeature;
          debugPrint("Feature source: ${featureData.source}");

          // Пробуем получить свойства из source
          try {
            final sourceJson =
                jsonDecode(featureData.source) as Map<String, dynamic>;
            final properties =
                sourceJson['properties'] as Map<String, dynamic>?;
            final id = sourceJson['id']?.toString();

            debugPrint("ID from source: $id");
            debugPrint("Properties from source: $properties");

            if (id == null) {
              debugPrint("⚠️ ID не найден в source");
              continue;
            }

            final workingHours = properties?['working_hours']?.toString();
            final isClosed = isPointClosedNow(workingHours, now);
            debugPrint("🕒 Feature $id is ${isClosed ? 'closed' : 'open'}");

            // Устанавливаем новое состояние
            if (sourceIdValue != null && sourceLayerValue != null) {
              await mapboxMapController!.setFeatureState(
                sourceIdValue,
                sourceLayerValue,
                id,
                jsonEncode({"closed": isClosed}),
              );
              debugPrint("✅ Состояние обновлено для $id: closed = $isClosed");
            } else {
              debugPrint(
                  "⚠️ Не удалось обновить состояние: source ID или layer не определены");
            }
          } catch (e) {
            debugPrint("❌ Ошибка при разборе source: $e");
            continue;
          }
        } catch (e, st) {
          debugPrint("❌ Ошибка обработки feature: $e");
          debugPrint("Stack trace: $st");
          continue;
        }
      }

      // Обновляем opacity слоя после обновления состояний
      await mapboxMapController?.style.setStyleLayerProperty(
        placesLayerId,
        'icon-opacity',
        buildIconOpacityExpression(),
      );
      debugPrint("✨ Opacity слоя обновлен");
    } catch (e, st) {
      debugPrint("❌ Ошибка в updateOpenCloseStates: $e");
      debugPrint("Stack trace: $st");
    }
  }

  double getThresholdByZoom(double zoom) {
    if (zoom < 6.0)
      return 3050;
    else if (zoom < 7.0)
      return 2850;
    else if (zoom < 7.5)
      return 2550;
    else if (zoom < 8.0)
      return 2350;
    else if (zoom < 8.5)
      return 2050;
    else if (zoom < 9.0)
      return 1850;
    else if (zoom < 9.5)
      return 1500;
    else if (zoom < 10.0)
      return 1200;
    else if (zoom < 10.5)
      return 1000;
    else if (zoom < 11.0)
      return 700;
    else if (zoom < 11.5)
      return 550;
    else if (zoom < 12.0)
      return 450;
    else if (zoom < 12.5)
      return 400;
    else if (zoom < 13.0)
      return 300;
    else if (zoom < 13.5)
      return 250;
    else if (zoom < 14.0)
      return 200;
    else if (zoom < 14.5)
      return 100;
    else if (zoom < 15.0)
      return 75;
    else if (zoom < 15.5)
      return 50;
    else if (zoom < 16.0)
      return 30;
    else if (zoom < 16.5)
      return 15;
    else if (zoom < 17.0)
      return 12;
    else if (zoom < 17.5)
      return 9;
    else if (zoom < 18.0)
      return 6;
    else if (zoom < 18.5)
      return 4;
    else if (zoom < 19.0)
      return 2;
    else
      return 0;
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
            [
              "coalesce",
              ["get", "min_dist"],
              0
            ]
          ],
          ["var", "myThreshold"]
        ],
        "my_dot_icon", // Если условие истинно, используем my_dot_icon
        // Если нет, пытаемся получить значение subcategory, а если его нет, то тоже my_dot_icon
        [
          "coalesce",
          ["get", "subcategory"],
          "my_dot_icon"
        ]
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
            [
              "coalesce",
              ["get", "min_dist"],
              0
            ]
          ],
          ["var", "myThreshold"]
        ],
        "",
        ["get", "name"]
      ]
    ];
  }

  List<Object> buildIconOpacityExpression() {
    return [
      "case",
      [
        "==",
        ["feature-state", "closed"],
        true
      ],
      0.7, // если closed = true, opacity = 0.7
      1.0 // в остальных случаях opacity = 1.0
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
