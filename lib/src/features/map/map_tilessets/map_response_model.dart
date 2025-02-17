import 'dart:convert';

class FeatureModel {
  final int id;
  final String type;
  final String name;
  final double zoom;
  final double rating;
  final double minDist;
  final String markerType;
  final double latitude;
  final double longitude;

  FeatureModel({
    required this.id,
    required this.type,
    required this.name,
    required this.zoom,
    required this.rating,
    required this.minDist,
    required this.markerType,
    required this.latitude,
    required this.longitude,
  });

  factory FeatureModel.fromJson(Map<String, dynamic> json) {
    return FeatureModel(
      id: json['properties']['id'] as int,
      type: json['properties']['type'] as String,
      name: json['properties']['name'] as String,
      zoom: (json['properties']['zoom'] as num).toDouble(),
      rating: (json['properties']['rating'] as num).toDouble(),
      minDist: (json['properties']['min_dist'] as num).toDouble(),
      markerType: json['properties']['marker_type'] as String,
      latitude: (json['geometry']['coordinates'][1] as num).toDouble(),
      longitude: (json['geometry']['coordinates'][0] as num).toDouble(),
    );
  }

  static List<FeatureModel> fromJsonList(String jsonString) {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final features = data['features'] as List;
    return features.map((feature) => FeatureModel.fromJson(feature)).toList();
  }
}