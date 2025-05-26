import 'feature.dart';
import 'review.dart';

/// Модель детальной информации о точке.
/// Поддерживает формат ответа:
/// {
///   "type": "...",
///   "properties": { ... },
///   "geometry": { ... }
/// }
class PointDetail {
  final String id;
  final String name;
  final String category;
  final String address;
  final String phone;
  final String website;
  final double rating;
  final int totalReviews;
  final List<String> imageUrls;
  final List<Feature> features;
  final List<Review> reviews;
  final int friendsCount;
  final List<String> friendAvatars;

  PointDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.phone,
    required this.website,
    required this.rating,
    required this.totalReviews,
    required this.imageUrls,
    required this.features,
    required this.reviews,
    required this.friendsCount,
    required this.friendAvatars,
  });

  /// Создаёт модель из JSON «объекта-Feature»
  factory PointDetail.fromJson(Map<String, dynamic> json) {
    // Если API положил данные внутрь "properties" — подставляем их,
    // иначе работаем сразу с корнем.
    final Map<String, dynamic> p =
        (json['properties'] as Map<String, dynamic>?) ?? json;

    // Берём контактную инфу (массив) и вытягиваем первый телефон/сайт
    final contact = p['contact_info'] as Map<String, dynamic>?;

    return PointDetail(
      id: (p['id'] ?? '').toString(),
      name: p['name'] as String? ?? '',
      category: p['category'] as String? ?? '',
      address: p['address'] as String? ?? '',
      phone: (contact?['phone_numbers'] as List<dynamic>?)?.firstOrNull ?? '',
      website: (contact?['websites'] as List<dynamic>?)?.firstOrNull ?? '',
      rating: (p['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: p['totalReviews'] as int? ?? 0,
      imageUrls: (p['images'] as List<dynamic>? ?? [])
          .map((e) => (e as Map<String, dynamic>)['image'] as String)
          .toList(),
      features: (p['features'] as List<dynamic>? ?? [])
          .map((e) => Feature.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviews: (p['reviews'] as List<dynamic>? ?? [])
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
      friendsCount: p['friendsCount'] as int? ?? 0,
      friendAvatars:
      List<String>.from(p['friendAvatars'] as List<dynamic>? ?? const []),
    );
  }
}

/// Хелпер-расширение для безопасного получения первого элемента списка.
extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
