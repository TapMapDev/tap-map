class Feature {
  final String title;   // «Wi-Fi», «Парковка 🚗» …
  Feature({required this.title});

  factory Feature.fromJson(Map<String, dynamic> j) =>
      Feature(title: j['title'] as String);

  Map<String, dynamic> toJson() => {'title': title};
}
