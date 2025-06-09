import 'feature.dart';
import 'review.dart';

/// Model representing detailed point information returned from `/points/<id>/`.
class PointModel {
  final String type; // always "Feature"
  final PointProperties properties;
  final PointGeometryData geometry;
  final PointGeometryData? polygon;
  final PointGeometryData? trails;
  final List<PointModel>? polygonChildren;

  // Fields from the previous version that are still used in the UI.
  // TODO backend should provide these values
  final double rating;
  final int totalReviews;
  final List<PointFeature> features;
  final List<PointReview> reviews;
  final int friendsCount;
  final List<String> friendAvatars;

  PointModel({
    required this.type,
    required this.properties,
    required this.geometry,
    this.polygon,
    this.trails,
    this.polygonChildren,
    this.rating = 0,
    this.totalReviews = 0,
    this.features = const [],
    this.reviews = const [],
    this.friendsCount = 0,
    this.friendAvatars = const [],
  });

  factory PointModel.fromJson(Map<String, dynamic> json) {

    final props = PointProperties.fromJson(json['properties'] ?? {});

    return PointModel(
      type: json['type'] as String? ?? 'Feature',
      properties: props,
      geometry: PointGeometryData.fromJson(json['geometry'] ?? {}),
      polygon:
      json['polygon'] != null ? PointGeometryData.fromJson(json['polygon']) : null,
      trails:
      json['trails'] != null ? PointGeometryData.fromJson(json['trails']) : null,
      polygonChildren: (json['polygon_children'] as List<dynamic>? ?? [])
          .map((e) => PointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      rating: (props.extra['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: props.extra['totalReviews'] as int? ?? 0,
      features: (props.extra['features'] as List<dynamic>? ?? [])
          .map((e) => PointFeature.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviews: (props.extra['reviews'] as List<dynamic>? ?? [])
          .map((e) => PointReview.fromJson(e as Map<String, dynamic>))
          .toList(),
      friendsCount: props.extra['friendsCount'] as int? ?? 0,
      friendAvatars: List<String>.from(
          props.extra['friendAvatars'] as List<dynamic>? ?? const []),
    );
  }
}

class PointProperties {
  final int id;
  final String name;
  final String? address;
  final String? description;
  final String? shortDescription;
  final String? jsonDescription;
  final String markerType;
  final List<PointImage> images;
  final String? logo;
  final String? category;
  final String? subcategory;
  final int user;
  final List<String> tags;
  final PointContactInfo? contactInfo;
  final PointWorkingHours? workingHours;
  final List<PointProduct>? priceList;
  final String? googleMapsUrl;
  final dynamic jsonMenu;
  final double zoom;
  final Map<String, dynamic>? friendsVisited;
  final String? friendsVisitedText;

  /// Raw properties that may contain extra fields like rating.
  final Map<String, dynamic> extra;

  PointProperties({
    required this.id,
    required this.name,
    this.address,
    this.description,
    this.shortDescription,
    this.jsonDescription,
    required this.markerType,
    required this.images,
    this.logo,
    this.category,
    this.subcategory,
    required this.user,
    required this.tags,
    this.contactInfo,
    this.workingHours,
    this.priceList,
    this.googleMapsUrl,
    this.jsonMenu,
    required this.zoom,
    this.friendsVisited,
    this.friendsVisitedText,
    this.extra = const {},
  });

  factory PointProperties.fromJson(Map<String, dynamic> json) {
    return PointProperties(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      description: json['description'] as String?,
      shortDescription: json['short_description'] as String?,
      jsonDescription: json['json_description'] as String?,
      markerType: json['marker_type'] as String? ?? 'point',
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => PointImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      logo: json['logo'] as String?,
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      user: json['user'] as int? ?? 0,
      tags: List<String>.from(json['tags'] as List<dynamic>? ?? const []),
      contactInfo: json['contact_info'] != null
          ? PointContactInfo.fromJson(json['contact_info'])
          : null,
      workingHours: json['working_hours'] != null
          ? PointWorkingHours.fromJson(json['working_hours'])
          : null,
      priceList: (json['price_list'] as List<dynamic>?)?.map((e) =>
          PointProduct.fromJson(e as Map<String, dynamic>)).toList(),
      googleMapsUrl: json['google_maps_url'] as String?,
      jsonMenu: json['json_menu'],
      zoom: (json['zoom'] as num?)?.toDouble() ?? 16,
      friendsVisited: json['friends_visited'] as Map<String, dynamic>?,
      friendsVisitedText: json['friends_visited_text'] as String?,
      extra: json,
    );
  }
}

// TODO в будущем вынести в отдельный файл т.к. будем юзать в Событиях еще
class PointGeometryData {
  final String type;
  final List<dynamic> coordinates;

  PointGeometryData({required this.type, required this.coordinates});

  factory PointGeometryData.fromJson(Map<String, dynamic> json) => PointGeometryData(
    type: json['type'] as String? ?? '',
    coordinates: json['coordinates'] as List<dynamic>? ?? [],
  );
}

// TODO в будущем вынести в отдельный файл т.к. будем юзать в Событиях еще
class PointImage {
  final int id;
  final String image;

  PointImage({required this.id, required this.image});

  factory PointImage.fromJson(Map<String, dynamic> json) =>
      PointImage(id: json['id'] as int? ?? 0, image: json['image'] as String? ?? '');
}

// TODO в будущем вынести в отдельный файл т.к. будем юзать в Событиях еще
class PointContactInfo {
  final List<String> phoneNumbers;
  final List<String> websites;

  PointContactInfo({this.phoneNumbers = const [], this.websites = const []});

  factory PointContactInfo.fromJson(Map<String, dynamic> json) => PointContactInfo(
    phoneNumbers: List<String>.from(json['phone_numbers'] as List<dynamic>? ?? const []),
    websites: List<String>.from(json['websites'] as List<dynamic>? ?? const []),
  );
}

// TODO в будущем вынести в отдельный файл т.к. будем юзать в Событиях еще
class PointWorkingHours {
  final Map<String, dynamic> raw;

  PointWorkingHours({this.raw = const {}});

  factory PointWorkingHours.fromJson(Map<String, dynamic> json) =>
      PointWorkingHours(raw: json);
}

// TODO в будущем вынести в отдельный файл т.к. будем юзать в Событиях еще
class PointProduct {
  final String name;
  final double price;

  PointProduct({required this.name, required this.price});

  factory PointProduct.fromJson(Map<String, dynamic> json) => PointProduct(
    name: json['name'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0,
  );
}

/// Helper extension to safely get first element of a list.
extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
