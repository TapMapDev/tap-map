class PointFeatureModel {
  final String title;   // «Wi-Fi», «Парковка 🚗» …
  PointFeatureModel({required this.title});

  factory PointFeatureModel.fromJson(Map<String, dynamic> j) =>
      PointFeatureModel(title: j['title'] as String);

  Map<String, dynamic> toJson() => {'title': title};
}
