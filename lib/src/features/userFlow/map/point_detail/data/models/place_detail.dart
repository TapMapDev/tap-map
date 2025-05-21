import 'feature.dart';
import 'review.dart';

class PlaceDetail {
  final String id;
  final String name;
  final String category;
  final String address;
  final String phone;
  final String website;
  final double rating;
  final int totalReviews;
  final String priceRange;
  final List<String> imageUrls;
  final List<Feature> features;
  final List<Review> reviews;
  final int friendsCount;
  final List<String> friendAvatars;

  PlaceDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.phone,
    required this.website,
    required this.rating,
    required this.totalReviews,
    required this.priceRange,
    required this.imageUrls,
    required this.features,
    required this.reviews,
    required this.friendsCount,
    required this.friendAvatars,
  });

  factory PlaceDetail.fromJson(Map<String, dynamic> j) => PlaceDetail(
    id: j['id'],
    name: j['name'],
    category: j['category'],
    address: j['address'],
    phone: j['phone'],
    website: j['website'],
    rating: (j['rating'] as num).toDouble(),
    totalReviews: j['totalReviews'],
    priceRange: j['priceRange'],
    imageUrls: List<String>.from(j['imageUrls']),
    features:
    (j['features'] as List).map((e) => Feature.fromJson(e)).toList(),
    reviews:
    (j['reviews'] as List).map((e) => Review.fromJson(e)).toList(),
    friendsCount: j['friendsCount'],
    friendAvatars: List<String>.from(j['friendAvatars']),
  );
}
