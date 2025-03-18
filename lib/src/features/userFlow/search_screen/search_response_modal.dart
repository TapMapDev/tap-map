class ScreenResponseModal {
  final int id;
  final String name;
  final String description;
  final List<ScreenImage> images;
  final String openStatus;
  final String distance;
  final String timeInfo;
  final String category;
  final List<TinderInfo> tinderInfo;
  final List<UnderCardData> underCardData;
  final String? objectType;

  ScreenResponseModal({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.openStatus,
    required this.distance,
    required this.timeInfo,
    required this.category,
    required this.tinderInfo,
    required this.underCardData,
    this.objectType,
  });

  factory ScreenResponseModal.fromJson(Map<String, dynamic> json) {
    return ScreenResponseModal(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      images: (json['images'] as List)
          .map((image) => ScreenImage.fromJson(image))
          .toList(),
      openStatus: json['open_status'],
      distance: json['distance'],
      timeInfo: json['time_info'],
      category: json['category'],
      tinderInfo: (json['tinder_info'] as List)
          .map((info) => TinderInfo.fromJson(info))
          .toList(),
      underCardData: (json['under_card_data'] as List)
          .map((data) => UnderCardData.fromJson(data))
          .toList(),
      objectType: json['object_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'images': images.map((image) => image.toJson()).toList(),
      'open_status': openStatus,
      'distance': distance,
      'time_info': timeInfo,
      'category': category,
      'tinder_info': tinderInfo.map((info) => info.toJson()).toList(),
      'under_card_data': underCardData.map((data) => data.toJson()).toList(),
      'object_type': objectType,
    };
  }

  ScreenResponseModal copyWith({
    int? id,
    String? name,
    String? description,
    List<ScreenImage>? images,
    String? openStatus,
    String? distance,
    String? timeInfo,
    String? category,
    List<TinderInfo>? tinderInfo,
    List<UnderCardData>? underCardData,
    String? objectType,
  }) {
    return ScreenResponseModal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      images: images ?? this.images,
      openStatus: openStatus ?? this.openStatus,
      distance: distance ?? this.distance,
      timeInfo: timeInfo ?? this.timeInfo,
      category: category ?? this.category,
      tinderInfo: tinderInfo ?? this.tinderInfo,
      underCardData: underCardData ?? this.underCardData,
      objectType: objectType ?? this.objectType,
    );
  }
}

class ScreenImage {
  final int id;
  final String image;

  ScreenImage({required this.id, required this.image});

  factory ScreenImage.fromJson(Map<String, dynamic> json) {
    return ScreenImage(
      id: json['id'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
    };
  }

  ScreenImage copyWith({
    int? id,
    String? image,
  }) {
    return ScreenImage(
      id: id ?? this.id,
      image: image ?? this.image,
    );
  }
}

class TinderInfo {
  final String label;
  final String value;

  TinderInfo({required this.label, required this.value});

  factory TinderInfo.fromJson(Map<String, dynamic> json) {
    return TinderInfo(
      label: json['label'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
    };
  }

  TinderInfo copyWith({
    String? label,
    String? value,
  }) {
    return TinderInfo(
      label: label ?? this.label,
      value: value ?? this.value,
    );
  }
}

class UnderCardData {
  final String label;
  final String value;

  UnderCardData({required this.label, required this.value});

  factory UnderCardData.fromJson(Map<String, dynamic> json) {
    return UnderCardData(
      label: json['label'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
    };
  }

  UnderCardData copyWith({
    String? label,
    String? value,
  }) {
    return UnderCardData(
      label: label ?? this.label,
      value: value ?? this.value,
    );
  }
}
