import 'package:equatable/equatable.dart';

class IconsResponseModel extends Equatable {
  final int id;
  final String name;
  final LogoModel logo;
  final String textColor;

  const IconsResponseModel({
    required this.id,
    required this.name,
    required this.logo,
    required this.textColor,
  });

  /// Фабричный метод для создания модели из JSON
  factory IconsResponseModel.fromJson(Map<String, dynamic> json) {
    return IconsResponseModel(
      id: json['id'] as int,
      name: json['name'] as String,
      logo: json['logo'] != null
          ? LogoModel.fromJson(json['logo'])
          : const LogoModel(id: 0, name: 'Unknown', logoUrl: ''),
      textColor: json['text_color'] as String? ?? '#ffffff', // Защита от null
    );
  }

  @override
  List<Object?> get props => [id, name, logo, textColor];
}

class LogoModel extends Equatable {
  final int id;
  final String name;
  final String logoUrl; // Исправил название

  const LogoModel({
    required this.id,
    required this.name,
    required this.logoUrl,
  });

  /// Фабричный метод для создания модели из JSON
  factory LogoModel.fromJson(Map<String, dynamic> json) {
    return LogoModel(
      id: json['id'] as int,
      name: json['name'] as String,
      logoUrl: json['logo'] as String? ?? '', // Защита от null
    );
  }

  @override
  List<Object?> get props => [id, name, logoUrl];
}