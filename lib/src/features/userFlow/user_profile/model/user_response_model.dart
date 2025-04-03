class UserModel {
  final int? id;
  final String? email;
  final String? password;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? website;
  final String? avatarUrl;
  final String? description;
  final String? dateOfBirth;
  final String? gender;
  final String? phone;
  final bool? isOnline;
  final DateTime? lastActivity;
  final bool? isEmailVerified;
  final PrivacySettings? privacy;
  final SecuritySettings? security;
  final SelectedMapStyle? selectedMapStyle;

  UserModel({
    this.id,
    this.email,
    this.password,
    this.username,
    this.firstName,
    this.lastName,
    this.website,
    this.avatarUrl,
    this.description,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.isOnline,
    this.lastActivity,
    this.isEmailVerified,
    this.privacy,
    this.security,
    this.selectedMapStyle,
  });

  UserModel copyWith({
    int? id,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? website,
    String? avatarUrl,
    String? description,
    String? gender,
    String? phone,
    bool? isOnline,
    String? lastActivity,
    bool? isEmailVerified,
    PrivacySettings? privacy,
    String? dateOfBirth,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      website: website ?? this.website,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      description: description ?? this.description,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      isOnline: isOnline ?? this.isOnline,
      lastActivity: lastActivity != null
          ? DateTime.parse(lastActivity)
          : this.lastActivity,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      privacy: privacy ?? this.privacy,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int?,
      email: json['email'] as String?,
      username: json['username'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      website: json['website'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      description: json['description'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      phone: json['phone'] as String?,
      isOnline: json['is_online'] as bool?,
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'] as String)
          : null,
      isEmailVerified: json['is_email_verified'] as bool?,
      privacy: json['privacy'] != null
          ? PrivacySettings.fromJson(json['privacy'] as Map<String, dynamic>)
          : null,
      security: json['security'] != null
          ? SecuritySettings.fromJson(json['security'] as Map<String, dynamic>)
          : null,
      selectedMapStyle: json['selected_map_style'] != null
          ? SelectedMapStyle.fromJson(
              json['selected_map_style'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Парсим список UserModel из массива (GET)
  static List<UserModel> fromJsonList(List<dynamic> data) {
    return data.map((item) => UserModel.fromJson(item)).toList();
  }

  /// Конвертация в JSON (POST)
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    if (email != null && email!.isNotEmpty) data['email'] = email;
    if (password != null && password!.isNotEmpty) data['password'] = password;
    if (username != null && username!.isNotEmpty) data['username'] = username;
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (website != null) data['website'] = website;
    if (description != null) data['description'] = description;
    if (dateOfBirth != null && dateOfBirth!.isNotEmpty)
      data['date_of_birth'] = dateOfBirth;
    if (gender != null && gender!.isNotEmpty) data['gender'] = gender;
    if (isOnline != null) data['is_online'] = isOnline;
    if (lastActivity != null)
      data['last_activity'] = lastActivity!.toIso8601String();
    if (phone != null) data['phone'] = phone;

    if (selectedMapStyle != null && selectedMapStyle!.id != null) {
      data['selected_map_style'] = selectedMapStyle!.id;
    }

    if (privacy != null) {
      data['privacy'] = privacy!.toJson();
    }

    return data;
  }
}

/// Для privacy
class PrivacySettings {
  final bool? isSearchableByEmail;
  final bool? isSearchableByPhone;
  final bool? isShowGeolocationToFriends;
  final bool? isPreciseGeolocation;

  PrivacySettings({
    this.isSearchableByEmail,
    this.isSearchableByPhone,
    this.isShowGeolocationToFriends,
    this.isPreciseGeolocation,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      isSearchableByEmail: json['is_searchable_by_email'] as bool?,
      isSearchableByPhone: json['is_searchable_by_phone'] as bool?,
      isShowGeolocationToFriends:
          json['is_show_geolocation_to_friends'] as bool?,
      isPreciseGeolocation: json['is_precise_geolocation'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    // Явно указываем false вместо null, чтобы сервер точно получил значение
    json['is_searchable_by_email'] = isSearchableByEmail ?? false;
    json['is_searchable_by_phone'] = isSearchableByPhone ?? false;

    // Для других полей сохраняем возможность null (если это допустимо для API)
    if (isShowGeolocationToFriends != null) {
      json['is_show_geolocation_to_friends'] = isShowGeolocationToFriends;
    }
    if (isPreciseGeolocation != null) {
      json['is_precise_geolocation'] = isPreciseGeolocation;
    }

    return json;
  }
}

/// Для security
class SecuritySettings {
  final bool? twoFactorEnabled;

  SecuritySettings({this.twoFactorEnabled});

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      twoFactorEnabled: json['two_factor_enabled'] as bool?,
    );
  }
}

/// Для selected_map_style
class SelectedMapStyle {
  final int? id;
  final String? name;
  final String? styleUrl;

  SelectedMapStyle({this.id, this.name, this.styleUrl});

  factory SelectedMapStyle.fromJson(Map<String, dynamic> json) {
    return SelectedMapStyle(
      id: json['id'] as int?,
      name: json['name'] as String?,
      styleUrl: json['style_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (id != null) json['id'] = id;
    if (name != null) json['name'] = name;
    if (styleUrl != null) json['style_url'] = styleUrl;
    return json;
  }
}

class UserAvatarModel {
  final int id;
  final String image;
  final String imageUrl;
  final String createdAt;

  UserAvatarModel({
    required this.id,
    required this.image,
    required this.imageUrl,
    required this.createdAt,
  });

  factory UserAvatarModel.fromJson(Map<String, dynamic> json) {
    return UserAvatarModel(
      id: json['id'] as int,
      image: json['image'] as String,
      imageUrl: json['image_url'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'image_url': imageUrl,
      'created_at': createdAt,
    };
  }
}
