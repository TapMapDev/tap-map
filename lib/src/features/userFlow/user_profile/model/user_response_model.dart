class UserModel {
  final int? id;
  final String? email;
  final String? password; // POST для обновления
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? website;
  final String? avatarUrl; // GET приходит
  final String? description;
  final String? dateOfBirth;
  final String? gender;
  final String? phone;
  final bool? isOnline; // Changed from String? to bool?
  final DateTime? lastActivity; // Changed from String? to DateTime?
  final bool? isEmailVerified; // GET приходит
  final PrivacySettings? privacy;
  final SecuritySettings? security;
  final SelectedMapStyle? selectedMapStyle; // POST требует

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

  /// Парсим 1 объект из JSON (GET)
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
    // для POST /api/users/ бэк ждёт:
    // {
    //   "email": "...",
    //   "password": "...",
    //   "username": "...",
    //   "first_name": "...",
    // }
    // Не все поля нужны при POST – только те, что реально меняются.
    final data = <String, dynamic>{};

    // Добавляем только не-null поля и не пустые строки
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

    // В POST для selected_map_style должен быть ID, а не объект
    if (selectedMapStyle != null && selectedMapStyle!.id != null) {
      data['selected_map_style'] = selectedMapStyle!.id;
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
