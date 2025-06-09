import 'package:tap_map/src/features/userFlow/map/point_detail/data/models/point.dart';
import 'package:tap_map/src/features/userFlow/common/data/models/point_image.dart';

abstract class SearchPoint {
  final int id;
  final String name;
  final String? description;
  final List<PointImage> images;
  final String? distance;
  final String? timeInfo;

  SearchPoint({
    required this.id,
    required this.name,
    this.description,
    required this.images,
    this.distance,
    this.timeInfo,
  });

  factory SearchPoint.fromJson(Map<String, dynamic> json) {
    final type = json['object_type'] as String? ?? 'point';
    if (type == 'event') {
      return EventCard.fromJson(json);
    }
    return PointCard.fromJson(json);
  }
}

class PointCard extends SearchPoint {
  final String? openStatus;
  final String? category;
  final List<TinderInfo> tinderInfo;
  final List<CardData> underCardData;
  final List<CardData> belowCardData;
  final String? objectType;

  PointCard({
    required super.id,
    required super.name,
    super.description,
    required super.images,
    super.distance,
    super.timeInfo,
    this.openStatus,
    this.category,
    this.tinderInfo = const [],
    this.underCardData = const [],
    this.belowCardData = const [],
    this.objectType,
  });

  factory PointCard.fromJson(Map<String, dynamic> json) => PointCard(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    images: (json['images'] as List<dynamic>? ?? [])
        .map((e) => PointImage.fromJson(e as Map<String, dynamic>))
        .toList(),
    distance: json['distance'] as String?,
    timeInfo: json['time_info'] as String?,
    openStatus: json['open_status'] as String?,
    category: json['category'] as String?,
    tinderInfo: (json['tinder_info'] as List<dynamic>? ?? [])
        .map((e) => TinderInfo.fromJson(e as Map<String, dynamic>))
        .toList(),
    underCardData: (json['under_card_data'] as List<dynamic>? ?? [])
        .map((e) => CardData.fromJson(e as Map<String, dynamic>))
        .toList(),
    belowCardData: (json['below_card_data'] as List<dynamic>? ?? [])
        .map((e) => CardData.fromJson(e as Map<String, dynamic>))
        .toList(),
    objectType: json['object_type'] as String?,
  );

  /// Создает карточку точки из полной модели Point
  factory PointCard.fromPoint(Point point) {
    return PointCard(
      id: point.properties.id,
      name: point.properties.name,
      description: point.properties.description,
      images: point.properties.images,
      category: point.properties.category,
      // TODO Остальные поля могут быть заполнены при необходимости
    );
  }
}

class EventCard extends SearchPoint {
  final DateTime startDt;
  final DateTime endDt;
  final String eventStatus;
  final String? objectType;

  EventCard({
    required super.id,
    required super.name,
    super.description,
    required super.images,
    required this.startDt,
    required this.endDt,
    required this.eventStatus,
    super.distance,
    super.timeInfo,
    this.objectType,
  });

  factory EventCard.fromJson(Map<String, dynamic> json) => EventCard(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    images: (json['images'] as List<dynamic>? ?? [])
        .map((e) => PointImage.fromJson(e as Map<String, dynamic>))
        .toList(),
    startDt: DateTime.tryParse(json['start_dt'] ?? '') ?? DateTime.now(),
    endDt: DateTime.tryParse(json['end_dt'] ?? '') ?? DateTime.now(),
    eventStatus: json['event_status'] as String? ?? '',
    distance: json['distance'] as String?,
    timeInfo: json['time_info'] as String?,
    objectType: json['object_type'] as String?,
  );
}

class TinderInfo {
  final String label;
  final String value;

  TinderInfo({required this.label, required this.value});

  factory TinderInfo.fromJson(Map<String, dynamic> json) => TinderInfo(
    label: json['label'] as String? ?? '',
    value: json['value'] as String? ?? '',
  );
}

class CardData {
  final String label;
  final String value;

  CardData({required this.label, required this.value});

  factory CardData.fromJson(Map<String, dynamic> json) => CardData(
    label: json['label'] as String? ?? '',
    value: json['value'] as String? ?? '',
  );
}
