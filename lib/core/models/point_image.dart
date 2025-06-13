/// Модель изображения точки, используемая как в полной модели Point,
/// так и в карточках поиска SearchPoint/PointCard.
class PointImage {
  final int id;
  final String image;

  PointImage({required this.id, required this.image});

  factory PointImage.fromJson(Map<String, dynamic> json) =>
      PointImage(
          id: json['id'] as int? ?? 0, image: json['image'] as String? ?? ''
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'image': image,
  };
}
