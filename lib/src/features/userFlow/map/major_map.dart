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

    // Если надо "прогреть" иконки заранее
    if (currentStyleId != null) {
      context.read<IconsBloc>().add(FetchIconsEvent(styleId: currentStyleId!));
    }
  }

  Future<void> _updateTextStyleFromJson(List<Map<String, dynamic>> data) async {
    if (mapboxMapController == null) return;

    for (var item in data) {
      final String textColor =
          item["text_color"] ?? "#FFFFFF"; // Дефолтный белый цвет
      final String name = item["name"] ?? "unknown"; // Название иконки

      final hasLayer = await _checkLayerExists("places_symbol_layer");
      if (!hasLayer) {
        debugPrint(
            "⚠️ Layer places_symbol_layer не найден! Попытка повторного добавления...");
        await _addSourceAndLayers();
        return;
      }

      try {
        // ✅ Устанавливаем цвет ТОЛЬКО для меток с соответствующим именем
        await mapboxMapController?.style.setStyleLayerProperty(
          "places_symbol_layer",
          "text-color",
          [
            "match",
            ["get", "name"], // Поле, по которому мы сравниваем
            name,
            _convertHexToRGBA(textColor), // Цвет для совпадающего name
            // ["rgba", 255, 255, 255, 1.0] // Дефолтный белый
          ],
        );

        debugPrint("✅ Цвет текста обновлён для $name: $textColor");
      } catch (e, st) {
        debugPrint("❌ Ошибка обновления цвета текста ($name): $e\n$st");
      }
    }
  }

  /// Проверка существования слоя
  Future<bool> _checkLayerExists(String layerId) async {
    try {
      final result = await mapboxMapController?.style
          .getStyleLayerProperty(layerId, "visibility");
      return result != null;
    } catch (e) {
      return false;
    }
  }

  List<Object> _convertHexToRGBA(String hexColor) {
    hexColor = hexColor.replaceFirst('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor'; // Добавляем альфа-канал (100% непрозрачность)
    }
    int hexValue = int.parse(hexColor, radix: 16);
    Color color = Color(hexValue);
    return ["rgba", color.red, color.green, color.blue, 1.0];
  }

  /// Конвертируем HEX в RGBA (если требуется)

  /// Преобразует HEX-цвет в Mapbox Expression
  List<Object> _parseColorExpression(String hexColor) {
    return ["literal", hexColor]; // Mapbox ожидает color в виде строки HEX
  }

  /// Запрашиваем геолокацию
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
    // Ждём, пока карта готова и локация получена
    if (!isStyleLoaded || !isLocationLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return MultiBlocListener(
      listeners: [
        // Ловим события IconsBloc (загрузка иконок)
        BlocListener<IconsBloc, IconsState>(
          listener: (context, state) async {
            if (state is IconsLoading) {
              debugPrint('🔄 Загрузка иконок...');
            } else if (state is IconsSuccess) {
              debugPrint('✅ Иконки получены. Загружаем в MapBox...');
              _loadIcons(state.icons, styleId: state.styleId);

              final textColorExpression =
                  buildTextColorExpression(state.textColors);

              try {
                await mapboxMapController?.style.setStyleLayerProperty(
                  "places_symbol_layer",
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
        // Ловим события MapStyleBloc (смена стиля)
        BlocListener<MapStyleBloc, MapStyleState>(
          listener: (context, state) async {
            if (state is MapStyleUpdateSuccess) {
              _updateMapStyle(state.styleUri);
              currentStyleId = state.newStyleId;
              await _clearIcons(); // чистим старые иконки
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

              /// Подписываемся на изменение камеры
              onCameraChangeListener: (eventData) async {
                // Запрашиваем текущее состояние камеры
                final cameraState = await mapboxMapController?.getCameraState();
                if (cameraState == null) return;

                final zoom = cameraState.zoom;
                // Считаем threshold
                final threshold = getThresholdByZoom(zoom);

                // Формируем icon-image expression
                final iconExpression = buildIconImageExpression(threshold);

                // Формируем text-field expression
                final textExpression = buildTextFieldExpression(threshold);

                // Обновляем icon-image
                mapboxMapController?.style.setStyleLayerProperty(
                  "places_symbol_layer",
                  "icon-image",
                  iconExpression,
                );
                // Обновляем text-field
                mapboxMapController?.style.setStyleLayerProperty(
                  "places_symbol_layer",
                  "text-field",
                  textExpression,
                );
              },
            ),

            // Кнопки выбора стиля
            const Positioned(
              bottom: 80,
              left: 20,
              child: MapStyleButtons(),
            ),

            // Кнопка "центр"
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

  /// Когда карта создана
  void _onMapCreated(mp.MapboxMap controller) {
    mapboxMapController = controller;

    // Включаем "синюю точку"
    mapboxMapController?.location.updateSettings(
      mp.LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
  }

  /// Когда стиль загружен
  Future<void> _onStyleLoadedCallback(mp.MapLoadedEventData data) async {
    if (mapboxMapController == null) return;
    debugPrint("🗺️ Стиль загружен! Добавляем слои...");
    // Добавляем источники и слой
    await _addSourceAndLayers();
    // Загружаем my_dot_icon
    await _loadMyDotIconFromUrl();

    // Однократно инициализируем icon-image и text-field
    final camState = await mapboxMapController?.getCameraState();
    final currentZoom = camState?.zoom ?? 14.0;
    final threshold = getThresholdByZoom(currentZoom);

    final iconExpr = buildIconImageExpression(threshold);
    final textExpr = buildTextFieldExpression(threshold);

    // Устанавливаем свойства
    mapboxMapController?.style.setStyleLayerProperty(
      "places_symbol_layer",
      "icon-image",
      iconExpr,
    );
    mapboxMapController?.style.setStyleLayerProperty(
      "places_symbol_layer",
      "text-field",
      textExpr,
    );

    // Если есть styleId -> грузим иконки
    if (currentStyleId != null) {
      context.read<IconsBloc>().add(FetchIconsEvent(styleId: currentStyleId!));
    }
  }

  List<Object> buildTextColorExpression(Map<String, String> textColors) {
    List<Object> matchExpression = [
      "match",
      ["get", "subcategory"], // Берём значение subcategory
    ];

    textColors.forEach((subcategory, color) {
      matchExpression.add(subcategory);
      matchExpression.add(_convertHexToRGBA(color)); // Конвертируем HEX в RGBA
    });

    matchExpression
        .add(["rgba", 255, 255, 255, 1.0]); // Белый цвет по умолчанию

    return matchExpression;
  }

  /// Добавляем источник + SymbolLayer (заглушка)
  Future<void> _addSourceAndLayers() async {
    await mapboxMapController?.style.addSource(
      mp.VectorSource(
        id: "places_source",
        tiles: ["https://map-travel.net/tilesets/data/tiles/{z}/{x}/{y}.pbf"],
        minzoom: 0,
        maxzoom: 20,
      ),
    );

    // Логика icon-image / text-field теперь обновляется динамически,
    // так что просто задаём заглушку
    await mapboxMapController?.style.addLayer(
      mp.SymbolLayer(
        id: "places_symbol_layer",
        sourceId: "places_source",
        sourceLayer: "mylayer",

        iconImage: "my_dot_icon", // Заглушка
        iconSize: 0.3,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,

        // Тоже заглушка
        textField: "",
        textFont: ["DIN Offc Pro Medium"],
        textSizeExpression: <Object>[
          "interpolate",
          ["linear"],
          ["zoom"],
          5, 3, // При зуме 5, размер текста 3
          18, 14 // При зуме 18, размер текста 14
        ],
        textOffsetExpression: <Object>[
          'interpolate',
          ['linear'],
          ['zoom'],
          5,
          [
            'literal',
            // [0, 1.0]
            [0, 1.85]
          ],
          18,
          [
            'literal',
            [0, 0.75]
            // [0, 1.55]
          ]
        ],
        textAnchor: mp.TextAnchor.TOP,
        textColor: Colors.white.value,
        textHaloColor: Colors.black.withOpacity(0.75).value,
        textHaloWidth: 2.0,
        textHaloBlur: 0.5,
      ),
    );
  }

  /// Очищаем старые иконки
  Future<void> _clearIcons() async {
    if (mapboxMapController == null) return;
    debugPrint('🔄 Удаляем старые иконки...');
    for (final iconKey in loadedIcons.keys) {
      await mapboxMapController?.style.removeStyleImage(iconKey);
    }
    loadedIcons.clear();
    debugPrint('✅ Все старые иконки удалены!');
  }

  /// Загружаем иконки из API
  Future<void> _loadIcons(
    List<IconsResponseModel> icons, {
    required int styleId,
  }) async {
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

  /// Загружаем my_dot_icon
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

  /// Загружаем одну иконку (API)
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

  /// Смена стиля
  Future<void> _updateMapStyle(String newStyle) async {
    if (mapboxMapController == null) return;
    debugPrint("🔄 Меняем стиль карты на: $newStyle...");
    await mapboxMapController!.style.setStyleURI(newStyle);

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (mapboxMapController != null) {
        debugPrint("✅ Новый стиль загружен! Пересоздаём источники...");
        await _addSourceAndLayers();
      }
    });
    getIt.get<SharedPrefsRepository>().saveMapStyle(newStyle);
  }

  /// Центрируемся на юзере
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

  /// Логика расчёта threshold по zуму (как в JS)
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

  /// Иконка: если min_dist < threshold => my_dot_icon, иначе subcategory
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
        "my_dot_icon",
        ["get", "subcategory"]
      ]
    ];
  }

  /// Текст: если min_dist < threshold => "" (нет текста), иначе => name
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
}

/// Класс утилит для скачивания
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
