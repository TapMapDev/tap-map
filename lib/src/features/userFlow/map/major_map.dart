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
import 'package:tap_map/src/features/userFlow/map/icons/bloc/icons_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/icons/model/icons_response_modal.dart';
import 'package:tap_map/src/features/userFlow/map/styles/bloc/map_styles_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/widgets/geo_location.dart';
import 'package:tap_map/src/features/userFlow/map/widgets/icon_opacity.dart'
    show OpenStatusManager;
import 'package:tap_map/src/features/userFlow/map/widgets/icon_opacity.dart';
import 'package:tap_map/src/features/userFlow/map/widgets/location_service.dart';
import 'package:tap_map/src/features/userFlow/map/widgets/map_style_buttons.dart';
// import 'package:tap_map/src/features/userFlow/map/widgets/video_marker_manager.dart';

class MajorMap extends StatefulWidget {
  const MajorMap({super.key});

  @override
  State<MajorMap> createState() => _MajorMapState();
}

class _MajorMapState extends State<MajorMap> {
  mp.MapboxMap? mapboxMapController;
  static const String placesLayerId = 'places_symbol_layer';
  // VideoMarkerManager? _gifMarkerManager;
  Timer? _cameraUpdateDebouncer;
  mp.CameraState? _lastCameraState;

  /// Позиция пользователя до создания карты
  gl.Position? _initialUserPosition;

  /// Флаг готовности локации
  bool isLocationLoaded = true; // Начинаем с true для мгновенного отображения

  /// Флаг готовности стиля
  bool isStyleLoaded = false; // Нужно дождаться загрузки стиля

  /// Словарь 'имя_иконки -> уже_загружено?'
  final Map<String, bool> loadedIcons = {};

  /// Сохранённый styleId
  int? currentStyleId;

  /// Сохранённый styleUri - не задаем значение по умолчанию
  late String mapStyleUri;

  bool _isDisposed = false; // Добавляем флаг для отслеживания состояния виджета
  bool _wasInactive = false; // Флаг для отслеживания неактивного состояния

  @override
  void initState() {
    super.initState();

    // Сначала загружаем стиль, затем уже все остальное
    _loadSavedMapStyle().then((_) {
      if (mounted) {
        // Загружаем позицию пользователя
        _loadUserPosition();

        // Запрашиваем список стилей
        context.read<MapStyleBloc>().add(FetchMapStylesEvent());

        // Обновляем состояния каждые 30 секунд
        Timer.periodic(const Duration(seconds: 60), (_) {
          if (mounted && mapboxMapController != null) {
            updateOpenCloseStates();
          }
        });
      }
    });
  }

  /// Загружаем сохраненный стиль перед отрисовкой карты
  Future<void> _loadSavedMapStyle() async {
    try {
      final prefs = getIt.get<SharedPrefsRepository>();
      final savedStyle = await prefs.getSavedMapStyle();
      final savedStyleId = await prefs.getMapStyleId();

      if (mounted) {
        setState(() {
          mapStyleUri = savedStyle ?? mp.MapboxStyles.MAPBOX_STREETS;
          currentStyleId = savedStyleId;
          isStyleLoaded = true;
        });
      }
    } catch (e) {
      // В случае ошибки установим дефолтный стиль
      if (mounted) {
        setState(() {
          mapStyleUri = mp.MapboxStyles.MAPBOX_STREETS;
          isStyleLoaded = true;
        });
      }
    }
  }

  // Новый метод для асинхронной загрузки позиции пользователя
  Future<void> _loadUserPosition() async {
    final position = await LocationService.getUserPosition();
    if (position != null && mounted) {
      setState(() {
        _initialUserPosition = position;
      });
    }
  }

  List<Object> _convertHexToRGBA(String hexColor) {
    hexColor = hexColor.replaceFirst('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    int hexValue = int.parse(hexColor, radix: 16);
    Color color = Color(hexValue);
    return ['rgba', color.red, color.green, color.blue, 1.0];
  }

  @override
  Widget build(BuildContext context) {
    if (!isStyleLoaded) {
      // Показываем индикатор загрузки только пока загружаем стиль
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Проверяем, нужно ли создать GifMarkerManager
    // if (mapboxMapController != null &&
    //     _gifMarkerManager == null &&
    //     !_isDisposed &&
    //     mounted) {
    //   Future.microtask(() {
    //     if (mounted && !_isDisposed) {
    //       // Принудительно запускаем сборку мусора перед созданием нового менеджера
    //       _forceGarbageCollection().then((_) {
    //         if (mounted && !_isDisposed) {
    //           setState(() {
    //             _gifMarkerManager = VideoMarkerManager(
    //                 key: VideoMarkerManager.globalKey,
    //                 mapboxMap: mapboxMapController!);
    //           });
    //         }
    //       });
    //     }
    //   });
    // }

    return MultiBlocListener(
      listeners: [
        BlocListener<IconsBloc, IconsState>(
          listener: (context, state) async {
            if (_isDisposed) return;
            if (state is IconsLoading) {
            } else if (state is IconsSuccess) {
              await _loadIcons(state.icons, styleId: state.styleId);

              if (_isDisposed) return;
              final textColorExpression =
                  buildTextColorExpression(state.textColors);
              await mapboxMapController?.style.setStyleLayerProperty(
                placesLayerId,
                'text-color',
                textColorExpression,
              );
            }
          },
        ),
        BlocListener<MapStyleBloc, MapStyleState>(
          listener: (context, state) async {
            if (state is MapStyleUpdateSuccess) {
              // Сохраняем ID стиля
              currentStyleId = state.newStyleId;
              await getIt
                  .get<SharedPrefsRepository>()
                  .saveMapStyleId(state.newStyleId);

              // Обновляем стиль
              await _updateMapStyle(state.styleUri);

              // Очищаем иконки
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
                  zoom: 12.5,
                ),
                onMapCreated: _onMapCreated,
                onMapLoadedListener: _onStyleLoadedCallback,
                onCameraChangeListener: (eventData) async {
                  if (_isDisposed) return;

                  // Получаем текущее состояние камеры
                  final cameraState =
                      await mapboxMapController?.getCameraState();
                  if (cameraState == null) return;

                  // Проверяем, действительно ли изменилась позиция камеры
                  if (_lastCameraState != null &&
                      _lastCameraState!.center == cameraState.center &&
                      _lastCameraState!.zoom == cameraState.zoom) {
                    return;
                  }
                  _lastCameraState = cameraState;

                  // Отменяем предыдущий отложенный вызов
                  _cameraUpdateDebouncer?.cancel();

                  // Создаем новый отложенный вызов
                  _cameraUpdateDebouncer =
                      Timer(const Duration(milliseconds: 150), () async {
                    if (_isDisposed) return;

                    final zoom = cameraState.zoom;
                    final threshold = getThresholdByZoom(zoom);
                    final iconExpression = buildIconImageExpression(threshold);
                    final textExpression = buildTextFieldExpression(threshold);

                    // Проверяем существование слоя
                    final layers =
                        await mapboxMapController!.style.getStyleLayers();
                    final layerExists =
                        layers.any((layer) => layer?.id == placesLayerId);
                    if (!layerExists) return;

                    // Обновляем свойства слоя параллельно
                    final futures = <Future<void>>[
                      mapboxMapController!.style.setStyleLayerProperty(
                        placesLayerId,
                        'icon-image',
                        iconExpression,
                      ),
                      mapboxMapController!.style.setStyleLayerProperty(
                        placesLayerId,
                        'text-field',
                        textExpression,
                      ),
                    ];
                    await Future.wait(futures);

                    // Обновляем позиции видео-маркеров
                    // if (_gifMarkerManager != null) {
                    //   VideoMarkerManager.updateMarkers();
                    // }
                  });
                }),
            // if (_gifMarkerManager != null) _gifMarkerManager!,
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

    // Объединяем настройки в один вызов для ускорения инициализации
    Future.microtask(() {
      // Настройки локации
      mapboxMapController?.location.updateSettings(
        mp.LocationComponentSettings(enabled: true, pulsingEnabled: true),
      );

      // Отключаем ненужные элементы управления
      mapboxMapController?.scaleBar.updateSettings(
        mp.ScaleBarSettings(enabled: false),
      );
      mapboxMapController?.compass.updateSettings(
        mp.CompassSettings(enabled: false),
      );
      mapboxMapController?.attribution.updateSettings(
        mp.AttributionSettings(enabled: false),
      );
    });
  }

  Future<void> _onStyleLoadedCallback(mp.MapLoadedEventData data) async {
    if (mapboxMapController == null || _isDisposed) return;

    // Запускаем загрузку иконок и инициализацию слоев параллельно
    final futures = <Future>[];

    // Добавляем источники и слои
    futures.add(_addSourceAndLayers());

    // Загружаем иконку для точки
    futures.add(_loadMyDotIconFromUrl());

    // Ждем завершения обеих операций
    await Future.wait(futures);

    if (_isDisposed) return;

    // Проверяем, что слой создан успешно
    final styleLayers = await mapboxMapController?.style.getStyleLayers();
    final layerExists =
        styleLayers?.any((layer) => layer?.id == placesLayerId) ?? false;
    if (!layerExists) {
      return;
    }

    // Асинхронно обновляем состояния открытия/закрытия
    updateOpenCloseStates();

    // Создаем GifMarkerManager сразу после загрузки стиля
    // if (_gifMarkerManager == null && !_isDisposed && mounted) {
    //   setState(() {
    //     _gifMarkerManager = VideoMarkerManager(
    //       key: VideoMarkerManager.globalKey,
    //       mapboxMap: mapboxMapController!,
    //     );
    //   });

    //   // Добавляем задержку перед обновлением маркеров
    //   Future.delayed(const Duration(seconds: 1), () {
    //     if (mounted && !_isDisposed) {
    //       VideoMarkerManager.updateMarkers();
    //     }
    //   });
    // }

    if (_isDisposed) return;

    // Получаем и устанавливаем настройки для слоев
    final camState = await mapboxMapController?.getCameraState();
    final currentZoom = camState?.zoom ?? 14.0;
    final threshold = getThresholdByZoom(currentZoom);

    // Применяем настройки асинхронно
    _applyLayerSettings(threshold);

    // Запрашиваем иконки, если есть ID стиля
    if (_isDisposed) return;
    if (currentStyleId != null) {
      context.read<IconsBloc>().add(FetchIconsEvent(styleId: currentStyleId!));
    }
  }

  /// Инициализирует или обновляет GifMarkerManager
  // void _initializeGifMarkerManager() {
  //   if (_isDisposed) return;

  //   // Если GifMarkerManager уже существует, вызываем forceUpdate
  //   if (_gifMarkerManager != null) {
  //     VideoMarkerManager.updateMarkers();
  //     return;
  //   }

  //   // Пересоздаем GifMarkerManager при загрузке стиля
  //   setState(() {
  //     _gifMarkerManager = null; // Сначала обнуляем старый менеджер
  //   });

  //   // Создаем новый менеджер
  //   Future.microtask(() {
  //     if (mounted && !_isDisposed && mapboxMapController != null) {
  //       setState(() {
  //         _gifMarkerManager = VideoMarkerManager(
  //           key: VideoMarkerManager.globalKey,
  //           mapboxMap: mapboxMapController!,
  //         );
  //       });
  //       // Добавляем задержку перед обновлением маркеров
  //       Future.delayed(const Duration(seconds: 1), () {
  //         if (mounted && !_isDisposed) {
  //           VideoMarkerManager.updateMarkers();
  //         }
  //       });
  //     }
  //   });
  // }

  /// Применяет настройки слоев асинхронно
  Future<void> _applyLayerSettings(double threshold) async {
    if (_isDisposed || mapboxMapController == null) return;

    final layers = await mapboxMapController!.style.getStyleLayers();
    final layerExists = layers.any((layer) => layer?.id == placesLayerId);
    if (!layerExists) return;

    final iconExpr = buildIconImageExpression(threshold);
    final textExpr = buildTextFieldExpression(threshold);

    await mapboxMapController?.style.setStyleLayerProperty(
      placesLayerId,
      'icon-image',
      iconExpr,
    );

    await mapboxMapController?.style.setStyleLayerProperty(
      placesLayerId,
      'text-field',
      textExpr,
    );
  }

  List<Object> buildTextColorExpression(Map<String, String> textColors) {
    List<Object> matchExpression = [
      'match',
      ['get', 'subcategory'],
    ];

    textColors.forEach((subcategory, color) {
      matchExpression.add(subcategory);
      matchExpression.add(_convertHexToRGBA(color));
    });
    matchExpression.add(['rgba', 255, 255, 255, 1.0]);
    return matchExpression;
  }

  /// Добавляем источник и SymbolLayer, если его ещё нет
  Future<void> _addSourceAndLayers() async {
    if (mapboxMapController == null) return;
    try {
      // Проверяем существование источника
      final sources = await mapboxMapController!.style.getStyleSources();
      final layers = await mapboxMapController!.style.getStyleLayers();

      for (var source in sources) {
        if (source != null) {}
      }

      final sourceExists =
          sources.any((source) => source?.id == 'places_source');

      if (!sourceExists) {
        final vectorSource = mp.VectorSource(
          id: 'places_source',
          tiles: ['https://map-travel.net/tilesets/data/tiles/{z}/{x}/{y}.pbf'],
          minzoom: 0,
          maxzoom: 20,
        );

        await mapboxMapController?.style.addSource(vectorSource);
      }

      // Добавляем источник для видео-маркеров
      // final videoSourceExists =
      //     sources.any((source) => source?.id == 'video_markers_source');
      // if (!videoSourceExists) {
      //   await mapboxMapController?.style.addSource(
      //     mp.GeoJsonSource(
      //       id: 'video_markers_source',
      //       data: jsonEncode({'type': 'FeatureCollection', 'features': []}),
      //     ),
      //   );
      // }

      // Проверяем существование слоя для видео
      // final videoLayerExists =
      //     layers.any((layer) => layer?.id == 'video_markers_layer');
      // if (!videoLayerExists) {
      //   await mapboxMapController?.style.addLayer(
      //     mp.SymbolLayer(
      //       id: 'video_markers_layer',
      //       sourceId: 'video_markers_source',
      //       minZoom: 0,
      //       maxZoom: 22,
      //       iconAllowOverlap: true,
      //       iconIgnorePlacement: true,
      //       symbolSortKey: 1, // Размещаем под основным слоем
      //     ),
      //   );
      // }

      // Проверяем существование основного слоя
      final layerExists = layers.any((layer) => layer?.id == placesLayerId);

      if (!layerExists) {
        await mapboxMapController?.style.addLayer(
          mp.SymbolLayer(
            id: placesLayerId,
            sourceId: 'places_source',
            sourceLayer: 'mylayer',
            iconSizeExpression: <Object>[
              'interpolate',
              ['linear'],
              ['zoom'],
              5,
              1,
              18,
              1.5
            ],
            iconSize: 0.3,
            iconAllowOverlap: true,
            textAllowOverlap: false,
            textOptional: true,
            textFont: ['DIN Offc Pro Medium'],
            textSizeExpression: <Object>[
              'interpolate',
              ['linear'],
              ['zoom'],
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
      }

      // Проверяем, что слой правильно связан с источником
      final layer = layers.firstWhere(
        (layer) => layer?.id == placesLayerId,
        orElse: () => null,
      );
      if (layer != null) {}
    } catch (e) {}
  }

  Future<void> _clearIcons() async {
    if (mapboxMapController == null) return;
    for (final iconKey in List<String>.from(loadedIcons.keys)) {
      if (await mapboxMapController!.style.styleLayerExists(iconKey)) {
        await mapboxMapController!.style.removeStyleImage(iconKey);
      }
    }
    loadedIcons.clear();
  }

  Future<void> _loadIcons(List<IconsResponseModel> icons,
      {required int styleId}) async {
    final tasks = <Future<void>>[];

    // Сначала устанавливаем базовый opacity
    if (mapboxMapController != null) {
      await mapboxMapController?.style.setStyleLayerProperty(
        placesLayerId,
        'icon-opacity',
        buildIconOpacityExpression(),
      );
      debugPrint('✅ Базовый opacity установлен');
    }

    for (final icon in icons) {
      final iconName = icon.name;
      final iconUrl = icon.logo.logoUrl;
      if (loadedIcons.containsKey(iconName)) {
        continue;
      }
      tasks.add(_loadSingleIcon(iconName, iconUrl, styleId));
    }

    // Ждем загрузки всех иконок
    await Future.wait(tasks);
  }

  Future<void> _loadMyDotIconFromUrl() async {
    if (mapboxMapController == null) return;
    const iconUrl =
        'https://tap-maptravel.s3.ap-southeast-2.amazonaws.com/media/svgs/circle/%D0%9A%D1%80%D1%83%D0%B3_rdr.png';
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
      'my_dot_icon',
      1.0,
      mbxImage,
      false,
      [],
      [],
      null,
    );
  }

  Future<void> _loadSingleIcon(String iconName, String url, int styleId) async {
    if (mapboxMapController == null) return;
    if (url.isEmpty || !url.startsWith('http')) {
      debugPrint('❌ Некорректный URL для иконки $iconName: $url');
      return;
    }
    final compositeKey = '$styleId-$iconName';
    final prefs = getIt.get<SharedPrefsRepository>();
    final cached = await prefs.getIconBytes(compositeKey);
    Uint8List? finalBytes;

    if (cached != null && cached.isNotEmpty) {
      finalBytes = cached;
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

    // Сначала сохраняем стиль, чтобы он использовался при следующем открытии
    await getIt.get<SharedPrefsRepository>().saveMapStyle(newStyle);

    // Обновляем локальную переменную
    mapStyleUri = newStyle;

    // Сначала убираем маркеры, чтобы не тормозили при переключении
    // setState(() {
    //   _gifMarkerManager = null;
    // });

    // Очищаем кэш видео контроллеров перед сменой стиля
    // VideoMarkerManager.updateMarkers();

    // Устанавливаем новый стиль без задержки
    await mapboxMapController!.style.setStyleURI(newStyle);

    // Обновляем базовые настройки и слои асинхронно, не блокируя UI
    Future.microtask(() async {
      // Отключаем локацию на время обновления слоев
      await mapboxMapController?.location.updateSettings(
        mp.LocationComponentSettings(enabled: false),
      );

      // Добавляем источники и слои
      await _addSourceAndLayers();

      // Обновляем состояния иконок
      updateOpenCloseStates();

      // Включаем локацию
      await mapboxMapController?.location.updateSettings(
        mp.LocationComponentSettings(enabled: true, pulsingEnabled: true),
      );

      // Создаем новый GifMarkerManager с небольшой задержкой
      // if (mounted && !_isDisposed && mapboxMapController != null) {
      //   Future.delayed(const Duration(milliseconds: 500), () {
      //     if (mounted && !_isDisposed) {
      //       setState(() {
      //         _gifMarkerManager = VideoMarkerManager(
      //             key: VideoMarkerManager.globalKey,
      //             mapboxMap: mapboxMapController!);
      //       });

      //       // Даем время на инициализацию и затем обновляем маркеры
      //       Future.delayed(const Duration(seconds: 1), () {
      //         if (mounted && !_isDisposed) {
      //           VideoMarkerManager.updateMarkers();
      //         }
      //       });
      //     }
      //   });
      // }
    });
  }

  // Метод для принудительного запуска сборки мусора
  Future<void> _forceGarbageCollection() async {
    // Даем время на сборку мусора
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // Функция проверки работы точки теперь использует OpenStatusManager
  Future<void> updateOpenCloseStates() async {
    return OpenStatusManager.updateOpenCloseStates(
      mapboxMapController,
      placesLayerId,
      _isDisposed,
    );
  }

  double getThresholdByZoom(double zoom) {
    return OpenStatusManager.getThresholdByZoom(zoom);
  }

  List<Object> buildIconImageExpression(double threshold) {
    return OpenStatusManager.buildIconImageExpression(threshold);
  }

  List<Object> buildTextFieldExpression(double threshold) {
    return OpenStatusManager.buildTextFieldExpression(threshold);
  }

  List<Object> buildIconOpacityExpression() {
    return OpenStatusManager.buildIconOpacityExpression();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Если виджет был неактивен и теперь снова активен, переинициализируем GifMarkerManager
    // if (_wasInactive &&
    //     mounted &&
    //     !_isDisposed &&
    //     mapboxMapController != null) {
    //   _wasInactive = false;

    //   // Если GifMarkerManager уже существует, вызываем forceUpdate
    //   if (_gifMarkerManager != null) {
    //     VideoMarkerManager.updateMarkers();
    //   } else {
    //     // Пересоздаем GifMarkerManager
    //     setState(() {
    //       _gifMarkerManager = null;
    //     });

    //     // Даем время на обновление состояния
    //     Future.delayed(const Duration(milliseconds: 300), () {
    //       if (mounted && !_isDisposed && mapboxMapController != null) {
    //         setState(() {
    //           _gifMarkerManager = VideoMarkerManager(
    //               key: VideoMarkerManager.globalKey,
    //               mapboxMap: mapboxMapController!);
    //         });
    //       }
    //     });
    //   }
    // }
  }

  @override
  void deactivate() {
    _wasInactive = true;
    super.deactivate();
  }

  @override
  void dispose() {
    _cameraUpdateDebouncer?.cancel();
    _isDisposed = true;
    super.dispose();
  }
}

class NetworkAssetManager {
  Future<Uint8List?> downloadImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('HTTP error: ${response.statusCode}');
      }
      final bytes = await consolidateHttpClientResponseBytes(response);
      return bytes;
    } catch (e) {
      return null;
    }
  }
}
