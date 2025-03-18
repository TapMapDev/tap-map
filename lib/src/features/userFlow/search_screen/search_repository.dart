import 'dart:convert';

import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/src/features/userFlow/search_screen/search_response_modal.dart';

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

  Future<void> likePlace(int placeId);
  Future<void> skipPlace(int placeId);
  Future<List<ScreenResponseModal>> fetchPlace();
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

  @override
  Future<List<ScreenResponseModal>> fetchPlace() async {
    try {
      final response = await apiService
          .getData('/cards/?lat=7.884296908086358&lon=98.38744968835519');

      print("Ответ API: $response");

      if (response['statusCode'] == 200) {
        // Проверяем разные варианты структуры ответа
        dynamic data = response['data'];

        if (data is Map<String, dynamic>) {
          print("Data как Map: ${data.keys.join(', ')}");

          // Используем безопасные преобразования
          return [_parseFromRawData(data)];
        } else if (data is List) {
          print("Data как List: ${data.length} элементов");

          // Обрабатываем список мест
          List<ScreenResponseModal> results = [];
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              results.add(_parseFromRawData(item));
            }
          }

          if (results.isEmpty) {
            print("Список пуст или не содержит валидных элементов");
            return [_createMockData()];
          }

          return results;
        } else {
          print("Неизвестный формат data: ${data.runtimeType}");
          throw Exception("Неизвестный формат ответа API");
        }
      } else {
        print(
            "Ошибка API: ${response['statusCode']} - ${response['statusMessage']}");
        throw Exception("Ошибка загрузки данных: ${response['statusMessage']}");
      }
    } catch (e, stackTrace) {
      print("Исключение в fetchPlace: $e");
      print("Stack trace: $stackTrace");

      // Возвращаем тестовые данные при ошибке
      return [_createMockData()];
    }
  }

  // Метод для парсинга из любого формата данных
  ScreenResponseModal _parseFromRawData(Map<String, dynamic> data) {
    try {
      // Логируем все ключи и значения, чтобы лучше понять структуру
      data.forEach((key, value) {
        print("Ключ: $key, Тип: ${value.runtimeType}");
      });

      // Некоторые API возвращают вложенный JSON в виде строки
      // Проверим это для важных полей
      dynamic images = data['images'];
      if (images is String) {
        try {
          // Пробуем распарсить строку как JSON
          images = jsonDecode(images);
          print("Успешно распарсили строку images как JSON");
        } catch (e) {
          print("Не удалось распарсить images как JSON: $e");
        }
      }

      // Также проверяем tinder_info и under_card_data
      dynamic tinderInfo = data['tinder_info'];
      if (tinderInfo is String) {
        try {
          tinderInfo = jsonDecode(tinderInfo);
          print("Успешно распарсили строку tinder_info как JSON");
        } catch (e) {
          print("Не удалось распарсить tinder_info как JSON: $e");
        }
      }

      dynamic underCardData = data['under_card_data'];
      if (underCardData is String) {
        try {
          underCardData = jsonDecode(underCardData);
          print("Успешно распарсили строку under_card_data как JSON");
        } catch (e) {
          print("Не удалось распарсить under_card_data как JSON: $e");
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
      );
    } catch (e, stackTrace) {
      print("Ошибка при парсинге данных: $e");
      print("Stack trace: $stackTrace");

      // Создаем модель с минимальными данными из ответа
      return ScreenResponseModal(
        id: _parseIntSafely(data['id']),
        name: _parseStringSafely(data['name'], 'Место'),
        description:
            _parseStringSafely(data['description'], 'Описание отсутствует'),
        images: _extractImagesFromAnyField(data) ??
            [ScreenImage(id: 1, image: "https://picsum.photos/500/800")],
        openStatus: _parseStringSafely(data['open_status'], 'unknown'),
        distance: _parseStringSafely(data['distance'], '0 км'),
        timeInfo: _parseStringSafely(data['time_info'], ''),
        category: _parseStringSafely(data['category'], 'Место'),
        tinderInfo: [TinderInfo(label: "Информация", value: "Недоступна")],
        underCardData: [UnderCardData(label: "Данные", value: "Недоступны")],
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

  // Вспомогательный метод для парсинга images
  List<ScreenImage> _parseImages(dynamic imagesData) {
    List<ScreenImage> result = [];

    try {
      // Случай 1: imagesData - это список объектов с полями id и image
      if (imagesData is List) {
        for (int i = 0; i < imagesData.length; i++) {
          dynamic item = imagesData[i];

          // Если элемент - объект с полями
          if (item is Map<String, dynamic>) {
            // Проверяем разные варианты полей для URL изображения
            String? imageUrl;
            for (var key in [
              'image',
              'url',
              'src',
              'path',
              'photo',
              'picture'
            ]) {
              if (item.containsKey(key) && item[key] is String) {
                imageUrl = item[key] as String;
                if (imageUrl.startsWith('http') ||
                    imageUrl.startsWith('https')) {
                  break;
                }
              }
            }

            // Если нашли URL, добавляем изображение
            if (imageUrl != null) {
              int id = item['id'] ?? i + 1;
              result.add(ScreenImage(id: id, image: imageUrl));
            }
          }
          // Если элемент просто строка URL
          else if (item is String &&
              (item.startsWith('http') || item.startsWith('https'))) {
            result.add(ScreenImage(id: i + 1, image: item));
          }
        }
      }
      // Случай 2: imagesData - это строка URL одного изображения
      else if (imagesData is String &&
          (imagesData.startsWith('http') || imagesData.startsWith('https'))) {
        result.add(ScreenImage(id: 1, image: imagesData));
      }
      // Случай 3: imagesData - это объект с URL изображения
      else if (imagesData is Map<String, dynamic>) {
        for (var key in ['url', 'image', 'src', 'path', 'photo', 'picture']) {
          if (imagesData.containsKey(key) && imagesData[key] is String) {
            String url = imagesData[key];
            if (url.startsWith('http') || url.startsWith('https')) {
              result.add(ScreenImage(id: 1, image: url));
              break;
            }
          }
        }
      }
    } catch (e) {
      print("Ошибка при парсинге изображений: $e");
    }

    // Если ничего не удалось распарсить, возвращаем тестовое изображение
    if (result.isEmpty) {
      result.add(ScreenImage(id: 1, image: "https://picsum.photos/500/800"));
    }

    return result;
  }

  // Вспомогательный метод для парсинга tinder_info
  List<TinderInfo> _parseTinderInfo(dynamic tinderInfoData) {
    if (tinderInfoData is List) {
      try {
        return tinderInfoData.map((info) => TinderInfo.fromJson(info)).toList();
      } catch (e) {
        print("Ошибка при парсинге tinder_info: $e");
      }
    }
    // Возвращаем тестовую информацию
    return [
      TinderInfo(label: "Рейтинг", value: "4.5"),
      TinderInfo(label: "Цена", value: "Средняя"),
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
        print("Ошибка при парсинге under_card_data: $e");
      }
    }
    // Возвращаем тестовые данные
    return [
      UnderCardData(label: "Адрес", value: "Phuket, Thailand"),
      UnderCardData(label: "Часы работы", value: "09:00 - 22:00"),
    ];
  }

  // Метод для создания тестовых данных
  ScreenResponseModal _createMockData() {
    return ScreenResponseModal(
      id: 1,
      name: "Restaurant Demo",
      description: "A beautiful restaurant with amazing food",
      images: [
        ScreenImage(id: 1, image: "https://picsum.photos/500/800"),
        ScreenImage(id: 2, image: "https://picsum.photos/500/801"),
      ],
      openStatus: "open",
      distance: "2.5 км",
      timeInfo: "20 мин",
      category: "Ресторан",
      tinderInfo: [
        TinderInfo(label: "Рейтинг", value: "4.8"),
        TinderInfo(label: "Цена", value: "Средняя"),
      ],
      underCardData: [
        UnderCardData(label: "Адрес", value: "Phuket, Thailand"),
        UnderCardData(label: "Часы работы", value: "09:00 - 23:00"),
      ],
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
  Future<void> likePlace(int placeId) async {
    return _retryOperation(() async {
      final response = await apiService.postData(
      '/api/places/$placeId/like',
      {},
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
  Future<void> skipPlace(int placeId) async {
    return _retryOperation(() async {
      final response = await apiService.postData(
      '/api/places/$placeId/skip',
      {},
    );

    if (response['statusCode'] != 200) {
      throw Exception('Failed to skip place: ${response['statusMessage']}');
      }

      // Инвалидируем кэш для этого места
      _placeCache.remove(placeId);
      _cache.clear(); // Очищаем кэш списков, так как они могут измениться
    });
  }

  void clearCache() {
    _cache.clear();
    _placeCache.clear();
  }
}
