class PointFeature {
  final String title;   // «Wi-Fi», «Парковка 🚗» …
  PointFeature({required this.title});

  factory PointFeature.fromJson(Map<String, dynamic> j) =>
      PointFeature(title: j['title'] as String);

  Map<String, dynamic> toJson() => {'title': title};
}
