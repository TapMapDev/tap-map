class MapStyleResponceModel {
  final int? id;
  final String? name;
  final String? styleUrl;
  final String? fontName;

  MapStyleResponceModel({
    this.id,
    this.name,
    this.styleUrl,
    this.fontName,
  });

  factory MapStyleResponceModel.fromJson(Map<String, dynamic> json) {
    return MapStyleResponceModel(
      id: json['id'],
      name: json['name'],
      styleUrl: json['style_url'],
      fontName: json['font_name'],
    );
  }
}
