import 'feature.dart';
import 'review.dart';

class Point {
  final String type; // always "Feature"
  final PointProperties properties;
  final GeometryData geometry;
  final GeometryData? polygon;
  final GeometryData? trails;
  final List<Point>? polygonChildren;

  // Fields from the previous version that are still used in the UI.
  // TODO backend should provide these values
  final double rating;
  final int totalReviews;
  final List<String> imageUrls;
  final List<Feature> features;
  final List<Review> reviews;
  final int friendsCount;
  final List<String> friendAvatars;

  Point({
    required this.type,
    required this.properties,
    required this.geometry,
    this.polygon,
    this.trails,
    this.rating = 0,
    this.totalReviews = 0,
    this.features = const [],
    this.reviews = const [],
    this.friendsCount = 0,
    this.friendAvatars = const [],
  });

  factory Point.fromJson(Map<String, dynamic> json) {
    final props = PointProperties.fromJson(json['properties'] ?? {});
    return Point(
      type: json['type'] as String? ?? 'Feature',
      properties: props,
      geometry: GeometryData.fromJson(json['geometry'] ?? {}),
      polygon:
      json['polygon'] != null ? GeometryData.fromJson(json['polygon']) : null,
      trails:
      json['trails'] != null ? GeometryData.fromJson(json['trails']) : null,
      polygonChildren: (json['polygon_children'] as List<dynamic>? ?? [])
          .map((e) => Point.fromJson(e as Map<String, dynamic>))
          .toList(),
        rating: (props.extra['rating'] as num?)?.toDouble() ?? 0,
        totalReviews: props.extra['totalReviews'] as int? ?? 0,
        features: (props.extra['features'] as List<dynamic>? ?? [])
            .map((e) => Feature.fromJson(e as Map<String, dynamic>))
            .toList(),
      reviews: (props.extra['reviews'] as List<dynamic>? ?? [])
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
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
  final List<ImageInfo> images;
  final String? logo;
  final String? category;
  final String? subcategory;
  final int user;
  final List<String> tags;
  final ContactInfo? contactInfo;
  final WorkingHours? workingHours;
  final List<Product>? priceList;
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
          .map((e) => ImageInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      logo: json['logo'] as String?,
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      user: json['user'] as int? ?? 0,
      tags: List<String>.from(json['tags'] as List<dynamic>? ?? const []),
      contactInfo: json['contact_info'] != null
          ? ContactInfo.fromJson(json['contact_info'])
          : null,
      workingHours: json['working_hours'] != null
          ? WorkingHours.fromJson(json['working_hours'])
          : null,
      priceList: (json['price_list'] as List<dynamic>?)?.map((e) =>
          Product.fromJson(e as Map<String, dynamic>)).toList(),
      googleMapsUrl: json['google_maps_url'] as String?,
      jsonMenu: json['json_menu'],
      zoom: (json['zoom'] as num?)?.toDouble() ?? 16,
      friendsVisited: json['friends_visited'] as Map<String, dynamic>?,
      friendsVisitedText: json['friends_visited_text'] as String?,
      extra: json,
    );
  }
}

class GeometryData {
  final String type;
  final List<dynamic> coordinates;

  GeometryData({required this.type, required this.coordinates});

  factory GeometryData.fromJson(Map<String, dynamic> json) => GeometryData(
    type: json['type'] as String? ?? '',
    coordinates: json['coordinates'] as List<dynamic>? ?? [],
  );
}

class ImageInfo {
  final int id;
  final String image;

  ImageInfo({required this.id, required this.image});

  factory ImageInfo.fromJson(Map<String, dynamic> json) =>
      ImageInfo(id: json['id'] as int? ?? 0, image: json['image'] as String? ?? '');
}

class ContactInfo {
  final List<String> phoneNumbers;
  final List<String> websites;

  ContactInfo({this.phoneNumbers = const [], this.websites = const []});

  factory ContactInfo.fromJson(Map<String, dynamic> json) => ContactInfo(
    phoneNumbers: List<String>.from(json['phone_numbers'] as List<dynamic>? ?? const []),
    websites: List<String>.from(json['websites'] as List<dynamic>? ?? const []),
  );
}

class WorkingHours {
  final Map<String, dynamic> raw;

  WorkingHours({this.raw = const {}});

  factory WorkingHours.fromJson(Map<String, dynamic> json) =>
      WorkingHours(raw: json);
}

class Product {
  final String name;
  final double price;

  Product({required this.name, required this.price});

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    name: json['name'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0,
  );
}

/// Helper extension to safely get first element of a list.
extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
