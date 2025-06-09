abstract class BaseCard {
  final int id;
  final String name;
  final String? description;
  final List<CardImage> images;
  final String? distance;
  final String? timeInfo;

  BaseCard({
    required this.id,
    required this.name,
    this.description,
    required this.images,
    this.distance,
    this.timeInfo,
  });

  factory BaseCard.fromJson(Map<String, dynamic> json) {
    final type = json['object_type'] as String? ?? 'point';
    if (type == 'event') {
      return EventCard.fromJson(json);
    }
    return PointCard.fromJson(json);
  }
}

class PointCard extends BaseCard {
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
            .map((e) => CardImage.fromJson(e as Map<String, dynamic>))
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
}

class EventCard extends BaseCard {
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
            .map((e) => CardImage.fromJson(e as Map<String, dynamic>))
            .toList(),
        startDt: DateTime.tryParse(json['start_dt'] ?? '') ?? DateTime.now(),
        endDt: DateTime.tryParse(json['end_dt'] ?? '') ?? DateTime.now(),
        eventStatus: json['event_status'] as String? ?? '',
        distance: json['distance'] as String?,
        timeInfo: json['time_info'] as String?,
        objectType: json['object_type'] as String?,
      );
}

class CardImage {
  final int id;
  final String image;

  CardImage({required this.id, required this.image});

  factory CardImage.fromJson(Map<String, dynamic> json) =>
      CardImage(id: json['id'] as int? ?? 0, image: json['image'] as String? ?? '');
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
