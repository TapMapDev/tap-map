import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;

class OpenStatusManager {
  static int parseTime(String time) {
    final parts = time.split(':').map(int.parse).toList();
    return parts[0] * 60 + parts[1];
  }

  static bool isPointClosedNow(String? workingHoursRaw, DateTime now) {
    if (workingHoursRaw == null || workingHoursRaw.isEmpty) return false;

    try {
      final workingHours = jsonDecode(workingHoursRaw) as Map<String, dynamic>;
      final dayOfWeek = now.weekday % 7;
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
        final open = parseTime(openTimes[i]);
        final close = parseTime(closeTimes[i]);

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

  static Future<void> updateOpenCloseStates(
    mp.MapboxMap? mapboxMapController,
    String placesLayerId,
    bool isDisposed,
  ) async {
    if (mapboxMapController == null) return;

    final now = DateTime.now();

    // Получаем features с оптимизированным запросом
    final features = await mapboxMapController.queryRenderedFeatures(
      mp.RenderedQueryGeometry(
        type: mp.Type.SCREEN_BOX,
        value: jsonEncode({
          'min': {'x': 0, 'y': 0},
          'max': {'x': 10000, 'y': 10000}
        }),
      ),
      mp.RenderedQueryOptions(
        layerIds: [placesLayerId],
        filter: null,
      ),
    );

    // Обрабатываем features пакетами по 20 штук для оптимизации
    for (var i = 0; i < features.length; i += 20) {
      if (isDisposed) return;

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

          String? workingHours = nestedProperties['working_hours']?.toString();
          if (workingHours != null) {
            workingHours = workingHours.replaceAll('\\"', '"');
          }

          final isClosed = isPointClosedNow(workingHours, now);

          await mapboxMapController.setFeatureState(
            'places_source',
            'mylayer',
            id,
            jsonEncode({'closed': isClosed}),
          );
        }),
      );
    }
  }

  /// Возвращает пороговое значение для отображения иконок в зависимости от уровня зума
  static double getThresholdByZoom(double zoom) {
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

  /// Создает Expression для прозрачности иконок в зависимости от статуса открытия
  static List<Object> buildIconOpacityExpression() {
    return [
      'case',
      [
        '==',
        ['feature-state', 'closed'],
        true
      ],
      0.6, // если closed = true, opacity = 0.6
      1.0 // в остальных случаях opacity = 1.0
    ];
  }

  /// Создает Expression для изображения иконок в зависимости от расстояния и статуса открытия
  static List<Object> buildIconImageExpression(double threshold) {
    return [
      'let',
      'myThreshold',
      threshold,
      [
        'case',
        // Если расстояние меньше порога, используем my_dot_icon
        [
          '<',
          [
            'to-number',
            [
              'coalesce',
              ['get', 'min_dist'],
              0
            ]
          ],
          ['var', 'myThreshold']
        ],
        'my_dot_icon',
        // Если заведение закрыто, используем закрытую версию иконки
        [
          '==',
          ['feature-state', 'closed'],
          true
        ],
        [
          'concat',
          ['get', 'subcategory'],
          '_closed'
        ],
        // В остальных случаях используем обычную иконку
        ['get', 'subcategory']
      ]
    ];
  }

  /// Создает Expression для отображения текста в зависимости от расстояния
  static List<Object> buildTextFieldExpression(double threshold) {
    return [
      'let',
      'myThreshold',
      threshold,
      [
        'case',
        [
          '<',
          [
            'to-number',
            [
              'coalesce',
              ['get', 'min_dist'],
              0
            ]
          ],
          ['var', 'myThreshold']
        ],
        '',
        ['get', 'name']
      ]
    ];
  }
}
