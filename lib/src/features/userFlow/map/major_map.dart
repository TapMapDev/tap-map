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
import 'package:tap_map/src/features/userFlow/map/icons/bloc/icons_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/icons/icons_responce_modal.dart';
import 'package:tap_map/src/features/userFlow/map/styles/bloc/map_styles_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/widgets/geo_location.dart';
import 'package:tap_map/src/features/userFlow/map/widgets/gif_marker_manager.dart';
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

  bool _isDisposed = false; // Добавляем флаг для отслеживания состояния виджета

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

    // Обновляем состояния каждые 30 секунд вместо минуты
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && mapboxMapController != null) {
        updateOpenCloseStates();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true; // Устанавливаем флаг при уничтожении
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
            if (_isDisposed) return;
            if (state is IconsLoading) {
              debugPrint('🔄 Загрузка иконок...');
            } else if (state is IconsSuccess) {
              debugPrint('✅ Иконки получены. Загружаем в MapBox...');
              await _loadIcons(state.icons, styleId: state.styleId);

              if (_isDisposed) return;
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
                if (_isDisposed) return;
                final cameraState = await mapboxMapController?.getCameraState();
                if (cameraState == null) return;

                final zoom = cameraState.zoom;
                final threshold = getThresholdByZoom(zoom);
                final iconExpression = buildIconImageExpression(threshold);
                final textExpression = buildTextFieldExpression(threshold);

                if (_isDisposed) return;
                final layers =
                    await mapboxMapController!.style.getStyleLayers();
                final layerExists =
                    layers.any((layer) => layer?.id == placesLayerId);
                if (!layerExists) {
                  debugPrint(
                      "Слой $placesLayerId не найден. Пропускаем обновление.");
                  return;
                }

                if (_isDisposed) return;
                try {
                  await mapboxMapController?.style.setStyleLayerProperty(
                    placesLayerId,
                    "icon-image",
                    iconExpression,
                  );
                } catch (e, st) {
                  debugPrint("❌ Ошибка обновления icon-image: $e\n$st");
                }

                if (_isDisposed) return;
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
            if (mapboxMapController != null)
              GifMarkerManager(mapboxMap: mapboxMapController!),
            const Positioned(
              top: 30,
              right: 13,
              child: MapStyleButton(),
            ),
            if (mapboxMapController != null)
              Positioned(
                bottom: 14,
                right: 13,
                child:
                    GeoLocationButton(mapboxMapController: mapboxMapController),
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

  Future<void> _onStyleLoadedCallback(mp.MapLoadedEventData data) async {
    if (mapboxMapController == null || _isDisposed) return;
    debugPrint("🗺️ Стиль загружен! Добавляем слои...");
    await _loadMyDotIconFromUrl();
    await _addSourceAndLayers();

    if (_isDisposed) return;
    final styleLayers = await mapboxMapController?.style.getStyleLayers();
    final layerExists =
        styleLayers?.any((layer) => layer?.id == placesLayerId) ?? false;
    if (!layerExists) {
      debugPrint("Слой $placesLayerId не появился!");
      return;
    }

    if (_isDisposed) return;
    await updateOpenCloseStates();

    if (_isDisposed) return;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && mapboxMapController != null && !_isDisposed) {
        updateOpenCloseStates();
      }
    });

    if (_isDisposed) return;
    final camState = await mapboxMapController?.getCameraState();
    final currentZoom = camState?.zoom ?? 14.0;
    final threshold = getThresholdByZoom(currentZoom);
    final iconExpr = buildIconImageExpression(threshold);
    final textExpr = buildTextFieldExpression(threshold);

    if (_isDisposed) return;
    try {
      await mapboxMapController?.style.setStyleLayerProperty(
        placesLayerId,
        "icon-image",
        iconExpr,
      );
    } catch (e, st) {
      debugPrint("❌ Ошибка установки icon-image: $e\n$st");
    }

    if (_isDisposed) return;
    try {
      await mapboxMapController?.style.setStyleLayerProperty(
        placesLayerId,
        "text-field",
        textExpr,
      );
    } catch (e, st) {
      debugPrint("❌ Ошибка установки text-field: $e\n$st");
    }

    if (_isDisposed) return;
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

      debugPrint("🔄 Проверяем источники карты:");
      for (var source in sources) {
        if (source != null) {
          debugPrint("  - ID: ${source.id}, Type: ${source.type}");
        }
      }

      final sourceExists =
          sources.any((source) => source?.id == "places_source");

      if (!sourceExists) {
        debugPrint("🔄 Добавляем источник places_source...");
        final vectorSource = mp.VectorSource(
          id: "places_source",
          tiles: ["https://map-travel.net/tilesets/data/tiles/{z}/{x}/{y}.pbf"],
          minzoom: 0,
          maxzoom: 20,
        );

        // Логируем конфигурацию источника
        debugPrint("  - Конфигурация places_source:");
        debugPrint(
            "  - URL тайлов: https://map-travel.net/tilesets/data/tiles/{z}/{x}/{y}.pbf");
        debugPrint("  - MinZoom: 0");
        debugPrint("  - MaxZoom: 20");

        await mapboxMapController?.style.addSource(vectorSource);
        debugPrint("✅ Источник places_source добавлен");
      } else {
        debugPrint("ℹ️ Источник places_source уже существует");
      }

      // Проверяем загрузку тайлов
      debugPrint("🔄 Проверяем загрузку тайлов...");
      final source = sources.firstWhere(
        (source) => source?.id == "places_source",
        orElse: () => null,
      );
      if (source != null) {
        debugPrint("ℹ️ Информация о places_source:");
        debugPrint("  - ID: ${source.id}");
        debugPrint("  - Type: ${source.type}");
        if (source is mp.VectorSource) {
          debugPrint("  - Tiles: ${(source as mp.VectorSource).tiles}");
          debugPrint("  - MinZoom: ${(source as mp.VectorSource).minzoom}");
          debugPrint("  - MaxZoom: ${(source as mp.VectorSource).maxzoom}");
        }
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

      // Проверяем, что слой правильно связан с источником
      final layer = layers.firstWhere(
        (layer) => layer?.id == placesLayerId,
        orElse: () => null,
      );
      if (layer != null) {
        debugPrint("ℹ️ Информация о слое $placesLayerId:");
        if (layer is mp.SymbolLayer) {
          debugPrint("  - Source ID: ${(layer as mp.SymbolLayer).sourceId}");
          debugPrint(
              "  - Source Layer: ${(layer as mp.SymbolLayer).sourceLayer}");
        }
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
    debugPrint('🔄 Загружаем ${icons.length} иконок для styleId=$styleId...');
    final tasks = <Future<void>>[];

    // Сначала устанавливаем базовый opacity
    if (mapboxMapController != null) {
      try {
        await mapboxMapController?.style.setStyleLayerProperty(
          placesLayerId,
          'icon-opacity',
          buildIconOpacityExpression(),
        );
        debugPrint('✅ Базовый opacity установлен');
      } catch (e) {
        debugPrint('❌ Ошибка при установке базового opacity: $e');
      }
    }

    for (final icon in icons) {
      final iconName = icon.name;
      final iconUrl = icon.logo.logoUrl;
      if (loadedIcons.containsKey(iconName)) {
        // debugPrint('⚠️ Иконка $iconName уже загружена');
        continue;
      }
      tasks.add(_loadSingleIcon(iconName, iconUrl, styleId));
    }

    // Ждем загрузки всех иконок
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

    final compositeKey = '$styleId-$iconName';
    final prefs = getIt.get<SharedPrefsRepository>();
    final cached = await prefs.getIconBytes(compositeKey);
    Uint8List? finalBytes;

    if (cached != null && cached.isNotEmpty) {
      finalBytes = cached;
      // debugPrint('💾 Иконка $iconName найдена в кэше');
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
  }

  Future<void> _updateMapStyle(String newStyle) async {
    if (mapboxMapController == null) return;

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
      return false;
    }
  }

  Future<void> updateOpenCloseStates() async {
    if (mapboxMapController == null) return;

    try {
      final now = DateTime.now();

      // Получаем features с оптимизированным запросом
      final features = await mapboxMapController!.queryRenderedFeatures(
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

      // Обрабатываем features пакетами по 20 штук для оптимизации
      for (var i = 0; i < features.length; i += 20) {
        final batch = features.skip(i).take(20);
        await Future.wait(
          batch.map((feature) async {
            if (feature == null) return;

            final featureData = feature.queriedFeature.feature;
            final properties = featureData as Map<dynamic, dynamic>;
            final id = properties['id']?.toString();
            final nestedProperties =
                properties['properties'] as Map<dynamic, dynamic>?;

            if (id == null || nestedProperties == null) return;

            String? workingHours =
                nestedProperties['working_hours']?.toString();
            if (workingHours != null) {
              workingHours = workingHours.replaceAll('\\"', '"');
            }

            final isClosed = isPointClosedNow(workingHours, now);

            await mapboxMapController!.setFeatureState(
              "places_source",
              "mylayer",
              id,
              jsonEncode({"closed": isClosed}),
            );
          }),
        );
      }

      debugPrint("✨ Обновление состояний завершено");
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
        // Если расстояние меньше порога, используем my_dot_icon
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
        // Если заведение закрыто, используем закрытую версию иконки
        [
          "==",
          ["feature-state", "closed"],
          true
        ],
        [
          "concat",
          ["get", "subca tegory"],
          "_closed"
        ],
        // В остальных случаях используем обычную иконку
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
      0.6, // если closed = true, opacity = 0.7
      1.0 // в остальных случаях opacity = 1.0
    ];
  }
}

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
