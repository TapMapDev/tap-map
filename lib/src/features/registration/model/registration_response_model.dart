class RegistrationResponseModel {
  final String? username;
  final String? email;
  final String? password1;
  final String? password2;
  final int statusCode;
  final String? accessToken;
  final String? refreshToken;
  final String? error;

  RegistrationResponseModel({
    this.accessToken,
    this.error,
    this.refreshToken,
    required this.statusCode,
    this.username,
    this.email,
    this.password1,
    this.password2,
  });

  factory RegistrationResponseModel.fromJson(
      Map<String, dynamic> json, int statusCode) {
    String? errorMessage;
    String? errorField;

    // Проверяем поля на наличие ошибок
    for (final field in ['username', 'email', 'password1', 'password2']) {
      if (json[field] != null) {
        final value = json[field];
        if (value is List && value.isNotEmpty) {
          errorMessage = value.first.toString();
        } else if (value is String) {
          errorMessage = value;
        }
        errorField = field;
        break;
      }
    }

    // Ошибки, не относящиеся к конкретному полю
    if (errorMessage == null && json['non_field_errors'] != null) {
      final value = json['non_field_errors'];
      if (value is List && value.isNotEmpty) {
        errorMessage = value.first.toString();
      } else if (value is String) {
        errorMessage = value;
      }
    }

    // Локализованное имя поля для отображения в сообщении об ошибке
    const fieldNames = {
      'username': 'Юзернэйм',
      'email': 'Эмэил',
      'password1': 'Пароль',
      'password2': 'Повторите пароль',
    };

    if (errorMessage != null && errorField != null) {
      final fieldName = fieldNames[errorField] ?? errorField;
      if (errorMessage.contains('blank') ||
          errorMessage.contains('пуст') ||
          errorMessage.contains('required') ||
          errorMessage.contains('обязат')) {
        errorMessage = 'Поле "$fieldName" не может быть пустым';
      }
      if (errorMessage.contains('Пользователь с таким Электронная почта уже существует')) {
        errorMessage = 'Пользователь с такой Электронной почтой уже существует';
      }
    }

    return RegistrationResponseModel(
        username:
            statusCode == 201 || statusCode == 200 ? json['username'] : null,
        email: statusCode == 201 || statusCode == 200 ? json['email'] : null,
        password1:
            statusCode == 201 || statusCode == 200 ? json['password1'] : null,
        password2:
            statusCode == 201 || statusCode == 200 ? json['password2'] : null,
        statusCode: statusCode,
        accessToken: json['access'],
        refreshToken: json['refresh'],
        error: errorMessage);
  }
}