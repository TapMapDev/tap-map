import 'dart:convert';

import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/features/search_screen/model/search_response_modal.dart';

// TODO(tapmap): Упростить репозиторий, избавиться от интерфейса SearchRepository
// и придерживаться общего подхода BLoC + репозиторий.

abstract class SearchRepository {
  Future<List<ScreenResponseModal>> getPlaces({
    required int offset,
    required int limit,
  });

  Future<List<ScreenResponseModal>> getPlacesByCategory(
    String category, {
    required int offset,
    required int limit,
  });

  Future<void> likePlace(int placeId, {required String objectType});
  Future<void> skipPlace(int placeId, {required String objectType});
  Future<List<ScreenResponseModal>> fetchPlace();
  Future<List<ScreenResponseModal>?> getCachedPlaces();
  Future<void> cachePlaces(List<ScreenResponseModal> places);
}

class SearchRepositoryImpl implements SearchRepository {
  final ApiService apiService;
  final Map<String, List<ScreenResponseModal>> _cache = {};
  final Map<int, ScreenResponseModal> _placeCache = {};
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  SearchRepositoryImpl({required this.apiService});

  Future<T> _retryOperation<T>(Future<T> Function() operation) async {
    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        if (retryCount == _maxRetries) {
          throw Exception('Operation failed after $_maxRetries attempts: $e');
        }
        await Future.delayed(_retryDelay * retryCount);
      }
    }
    throw Exception('Unexpected error in retry operation');
  }

  // TODO fetchPoint, compare model with PointDetil model
  @override
  Future<List<ScreenResponseModal>> fetchPlace() async {
    try {
      final response = await apiService
          .getData('/cards/?lat=7.884296908086358&lon=98.38744968835519');

      if (response['statusCode'] == 200) {
        // Проверяем разные варианты структуры ответа
        dynamic data = response['data'];

        if (data is Map<String, dynamic>) {
          // Используем безопасные преобразования
          return [_parseFromRawData(data)];
        } else if (data is List) {
          // Обрабатываем список мест
          List<ScreenResponseModal> results = [];
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              results.add(_parseFromRawData(item));
            }
          }

          if (results.isEmpty) {
            return [_createMockData()];
          }

          return results;
        } else {
          return [_createMockData()];
        }
      } else {
        // Проверяем, есть ли какие-то данные в ответе, даже если код не 200
        if (response['data'] != null) {
          dynamic data = response['data'];

          // Пытаемся извлечь хоть какие-то данные из ответа
          if (data is Map<String, dynamic>) {
            return [_parseFromRawData(data)];
          } else if (data is List && data.isNotEmpty) {
            List<ScreenResponseModal> results = [];
            for (var item in data) {
              if (item is Map<String, dynamic>) {
                results.add(_parseFromRawData(item));
              }
            }
            if (results.isNotEmpty) {
              return results;
            }
          }
        }

        // Создаем 3 тестовых места для демонстрации
        return [
          _createMockData(),
          _createMockData().copyWith(
              id: 2,
              name: 'Coffee Shop',
              description:
                  'Perfect place for coffee lovers with a great variety of coffee beans',
              images: [
                ScreenImage(id: 1, image: 'https://picsum.photos/500/802'),
                ScreenImage(id: 2, image: 'https://picsum.photos/500/803')
              ]),
          _createMockData().copyWith(
              id: 3,
              name: 'Beachfront Bar',
              description: 'Enjoy cocktails with a stunning sea view',
              images: [
                ScreenImage(id: 1, image: 'https://picsum.photos/500/804'),
                ScreenImage(id: 2, image: 'https://picsum.photos/500/805')
              ])
        ];
      }
    } catch (e) {   
      // Возвращаем несколько тестовых мест при ошибке
      return [
        _createMockData(),
        _createMockData().copyWith(
            id: 2,
            name: 'Coffee Shop',
            description:
                'Perfect place for coffee lovers with a great variety of coffee beans',
            images: [
              ScreenImage(id: 1, image: 'https://picsum.photos/500/802'),
              ScreenImage(id: 2, image: 'https://picsum.photos/500/803')
            ]),
        _createMockData().copyWith(
            id: 3,
            name: 'Beachfront Bar',
            description: 'Enjoy cocktails with a stunning sea view',
            images: [
              ScreenImage(id: 1, image: 'https://picsum.photos/500/804'),
              ScreenImage(id: 2, image: 'https://picsum.photos/500/805')
            ])
      ];
    }
  }

  // Метод для парсинга из любого формата данных
  ScreenResponseModal _parseFromRawData(Map<String, dynamic> data) {
    try {
      // Логируем все ключи и значения, чтобы лучше понять структуру
      data.forEach((key, value) {
        print('Ключ: $key, Тип: ${value.runtimeType}');
      });
      dynamic images = data['images'];
      if (images is String) {
        images = jsonDecode(images);
      }

      // Также проверяем tinder_info и under_card_data
      dynamic tinderInfo = data['tinder_info'];
      if (tinderInfo is String) {
        try {
          tinderInfo = jsonDecode(tinderInfo);
          print('Успешно распарсили строку tinder_info как JSON');
        } catch (e) {
          print('Не удалось распарсить tinder_info как JSON: $e');
        }
      }

      dynamic underCardData = data['under_card_data'];
      if (underCardData is String) {
        try {
          underCardData = jsonDecode(underCardData);
          print('Успешно распарсили строку under_card_data как JSON');
        } catch (e) {
          print('Не удалось распарсить under_card_data как JSON: $e');
        }
      }

      // Создаем модель с преобразованными данными
      return ScreenResponseModal(
        id: _parseIntSafely(data['id']),
        name: _parseStringSafely(data['name'], 'Без названия'),
        description: _parseStringSafely(data['description'], 'Нет описания'),
        images: _parseImages(images),
        openStatus: _parseStringSafely(data['open_status'], 'unknown'),
        distance: _parseStringSafely(data['distance'], '0 км'),
        timeInfo: _parseStringSafely(data['time_info'], ''),
        category: _parseStringSafely(data['category'], 'Без категории'),
        tinderInfo: _parseTinderInfo(tinderInfo),
        underCardData: _parseUnderCardData(underCardData),
        objectType: _parseStringSafely(data['object_type'], 'point'),
      );
    } catch (e, stackTrace) {
      print('Ошибка при парсинге данных: $e');
      print('Stack trace: $stackTrace');

      // Создаем модель с минимальными данными из ответа
      return ScreenResponseModal(
        id: _parseIntSafely(data['id']),
        name: _parseStringSafely(data['name'], 'Место'),
        description:
            _parseStringSafely(data['description'], 'Описание отсутствует'),
        images: _extractImagesFromAnyField(data) ??
            [ScreenImage(id: 1, image: 'https://picsum.photos/500/800')],
        openStatus: _parseStringSafely(data['open_status'], 'unknown'),
        distance: _parseStringSafely(data['distance'], '0 км'),
        timeInfo: _parseStringSafely(data['time_info'], ''),
        category: _parseStringSafely(data['category'], 'Место'),
        tinderInfo: [TinderInfo(label: 'Информация', value: 'Недоступна')],
        underCardData: [UnderCardData(label: 'Данные', value: 'Недоступны')],
        objectType: _parseStringSafely(data['object_type'], 'point'),
      );
    }
  }

  // Безопасное извлечение строки
  String _parseStringSafely(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  // Безопасное извлечение целого числа
  int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  // Попытка найти изображения в любом поле ответа
  List<ScreenImage>? _extractImagesFromAnyField(Map<String, dynamic> data) {
    // Поиск в разных возможных полях
    for (var key in [
      'images',
      'image',
      'photos',
      'photo',
      'pictures',
      'picture',
      'url'
    ]) {
      if (data.containsKey(key)) {
        dynamic value = data[key];

        // Случай когда значение - строка URL
        if (value is String &&
            (value.startsWith('http') || value.startsWith('https'))) {
          return [ScreenImage(id: 1, image: value)];
        }

        // Случай когда значение - список строк URL
        if (value is List) {
          List<ScreenImage> result = [];
          for (int i = 0; i < value.length; i++) {
            var item = value[i];
            if (item is String &&
                (item.startsWith('http') || item.startsWith('https'))) {
              result.add(ScreenImage(id: i + 1, image: item));
            } else if (item is Map<String, dynamic> &&
                (item.containsKey('url') ||
                    item.containsKey('image') ||
                    item.containsKey('src') ||
                    item.containsKey('path'))) {
              String imageUrl =
                  item['url'] ?? item['image'] ?? item['src'] ?? item['path'];
              if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
                result.add(ScreenImage(id: i + 1, image: imageUrl));
              }
            }
          }
          if (result.isNotEmpty) return result;
        }

        // Случай когда значение - объект с URL
        if (value is Map<String, dynamic>) {
          for (var imageKey in ['url', 'src', 'path', 'href']) {
            if (value.containsKey(imageKey)) {
              String? url = value[imageKey] as String?;
              if (url != null &&
                  (url.startsWith('http') || url.startsWith('https'))) {
                return [ScreenImage(id: 1, image: url)];
              }
            }
          }
        }
      }
    }
    return null;
  }

  // Вспомогательный метод для парсинга имен и URL изображений
  List<ScreenImage> _parseImages(dynamic imagesData) {
    // Инициализируем список для результата
    List<ScreenImage> result = [];

    try {
      // Если imagesData - список
      if (imagesData is List) {
        int id = 1;
        for (var item in imagesData) {
          // Если элемент - объект (Map)
          if (item is Map<String, dynamic>) {
            // Ищем URL изображения в объекте
            String? imageUrl;

            // Проверяем разные возможные имена полей с URL изображения
            for (var key in ['url', 'src', 'path', 'href', 'image']) {
              if (item.containsKey(key) && item[key] is String) {
                imageUrl = item[key] as String;
                if ((imageUrl.startsWith('http') ||
                    imageUrl.startsWith('https'))) {
                  result.add(ScreenImage(id: id++, image: imageUrl));
                  break;
                }
              }
            }
          }
          // Если элемент - строка URL
          else if (item is String &&
              (item.startsWith('http') || item.startsWith('https'))) {
            result.add(ScreenImage(id: id++, image: item));
          }
        }
      }
      // Если imagesData - одиночная строка URL
      else if (imagesData is String &&
          (imagesData.startsWith('http') || imagesData.startsWith('https'))) {
        result.add(ScreenImage(id: 1, image: imagesData));
      }
      // Если imagesData - объект с URL
      else if (imagesData is Map<String, dynamic>) {
        // Ищем URL изображения в объекте
        for (var imageKey in ['url', 'src', 'path', 'href', 'image']) {
          if (imagesData.containsKey(imageKey)) {
            String? url = imagesData[imageKey] as String?;
            if (url != null &&
                (url.startsWith('http') || url.startsWith('https'))) {
              result.add(ScreenImage(id: 1, image: url));
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Ошибка при парсинге изображений: $e');
    }

    // Если ничего не удалось распарсить, добавляем несколько тестовых изображений
    if (result.isEmpty) {
      print('Не удалось получить изображения, используем тестовые');
      result.add(
          ScreenImage(id: 1, image: 'https://picsum.photos/id/1/800/1200'));
      result.add(
          ScreenImage(id: 2, image: 'https://picsum.photos/id/2/800/1200'));
      result.add(
          ScreenImage(id: 3, image: 'https://picsum.photos/id/3/800/1200'));
    }

    return result;
  }

  // Вспомогательный метод для парсинга tinder_info
  List<TinderInfo> _parseTinderInfo(dynamic tinderInfoData) {
    if (tinderInfoData is List) {
      try {
        return tinderInfoData.map((info) => TinderInfo.fromJson(info)).toList();
      } catch (e) {
        print('Ошибка при парсинге tinder_info: $e');
      }
    }
    // Возвращаем тестовую информацию
    return [
      TinderInfo(label: 'Рейтинг', value: '4.5'),
      TinderInfo(label: 'Цена', value: 'Средняя'),
    ];
  }

  // Вспомогательный метод для парсинга under_card_data
  List<UnderCardData> _parseUnderCardData(dynamic underCardData) {
    if (underCardData is List) {
      try {
        return underCardData
            .map((data) => UnderCardData.fromJson(data))
            .toList();
      } catch (e) {
        print('Ошибка при парсинге under_card_data: $e');
      }
    }
    // Возвращаем тестовые данные
    return [
      UnderCardData(label: 'Адрес', value: 'Phuket, Thailand'),
      UnderCardData(label: 'Часы работы', value: '09:00 - 22:00'),
    ];
  }

  // Метод для создания тестовых данных
  ScreenResponseModal _createMockData() {
    return ScreenResponseModal(
      id: 1,
      name: 'Restaurant Demo',
      description: 'A beautiful restaurant with amazing food',
      images: [
        ScreenImage(id: 1, image: 'https://picsum.photos/500/800'),
        ScreenImage(id: 2, image: 'https://picsum.photos/500/801'),
      ],
      openStatus: 'open',
      distance: '2.5 км',
      timeInfo: '20 мин',
      category: 'Ресторан',
      tinderInfo: [
        TinderInfo(label: 'Рейтинг', value: '4.8'),
        TinderInfo(label: 'Цена', value: 'Средняя'),
      ],
      underCardData: [
        UnderCardData(label: 'Адрес', value: 'Phuket, Thailand'),
        UnderCardData(label: 'Часы работы', value: '09:00 - 23:00'),
      ],
      objectType: 'point',
    );
  }

  @override
  Future<List<ScreenResponseModal>> getPlaces({
    required int offset,
    required int limit,
  }) async {
    final cacheKey = 'places_${offset}_$limit';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    return _retryOperation(() async {
      final response = await apiService.getData(
        '/api/places/search',
        queryParams: {
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );

      if (response['statusCode'] != 200) {
        throw Exception('Failed to load places: ${response['statusMessage']}');
      }

      final List<dynamic> placesJson =
          response['data']['places'] as List? ?? [];
      final places = placesJson
          .map((place) => ScreenResponseModal.fromJson(place))
          .toList();

      _cache[cacheKey] = places;
      return places;
    });
  }

  @override
  Future<List<ScreenResponseModal>> getPlacesByCategory(
    String category, {
    required int offset,
    required int limit,
  }) async {
    final cacheKey = 'category_${category}_${offset}_$limit';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    return _retryOperation(() async {
      final response = await apiService.getData(
        '/api/places/category/$category',
        queryParams: {
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );

      if (response['statusCode'] != 200) {
        throw Exception(
            'Failed to load places by category: ${response['statusMessage']}');
      }

      final List<dynamic> placesJson =
          response['data']['places'] as List? ?? [];
      final places = placesJson
          .map((place) => ScreenResponseModal.fromJson(place))
          .toList();

      _cache[cacheKey] = places;
      return places;
    });
  }

  @override
  Future<void> likePlace(int placeId, {required String objectType}) async {
    // Добавляем параметр, разрешающий временные 401 ошибки без обновления токенов
    Map<String, dynamic> optionalHeaders = {'X-Skip-Auth-Refresh': 'true'};

    return _retryOperation(() async {
      final response = await apiService.postData(
        '/tinder/favorite/',
        {'object_type': objectType, 'object_id': placeId},
        headers: optionalHeaders,
      );

      if (response['statusCode'] != 200) {
        throw Exception('Failed to like place: ${response['statusMessage']}');
      }

      // Инвалидируем кэш для этого места
      _placeCache.remove(placeId);
      _cache.clear(); // Очищаем кэш списков, так как они могут измениться
    });
  }

  @override
  Future<void> skipPlace(int placeId, {required String objectType}) async {
    // Добавляем параметр, разрешающий временные 401 ошибки без обновления токенов
    Map<String, dynamic> optionalHeaders = {'X-Skip-Auth-Refresh': 'true'};

    return _retryOperation(() async {
      final response = await apiService.postData(
        '/tinder/skip/',
        {'object_type': objectType, 'object_id': placeId},
        headers: optionalHeaders,
      );

      if (response['statusCode'] != 200) {
        throw Exception('Failed to skip place: ${response['statusMessage']}');
      }

      // Инвалидируем кэш для этого места
      _placeCache.remove(placeId);
      _cache.clear(); // Очищаем кэш списков, так как они могут измениться
    });
  }

  @override
  Future<List<ScreenResponseModal>?> getCachedPlaces() async {
    // Простая реализация - возвращаем кешированные данные, если они есть
    if (_cache.containsKey('recent_places')) {
      return _cache['recent_places'];
    }
    return null;
  }

  @override
  Future<void> cachePlaces(List<ScreenResponseModal> places) async {
    // Сохраняем места в кеш
    _cache['recent_places'] = places;

    // Также обновляем кеш отдельных мест
    for (var place in places) {
      _placeCache[place.id] = place;
    }
  }

  void clearCache() {
    _cache.clear();
    _placeCache.clear();
  }
}
