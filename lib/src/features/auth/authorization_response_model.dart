class AuthorizationResponseModel {
  final int statusCode;
  final String? message;
  final String? accessToken;
  final String? refreshToken;

  AuthorizationResponseModel({
    required this.message,
    required this.statusCode,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthorizationResponseModel.fromJson(
      Map<String, dynamic> json, int statusCode) {
    final accessToken = json['access'];
    final refreshToken = json['refresh'];
    
    // Логирование ошибки, если токены не пришли
    if (accessToken == null || refreshToken == null) {
      print("Ошибка: Access Token или Refresh Token отсутствует в ответе API.");
      print("Ответ API: $json");
    }

    return AuthorizationResponseModel(
      message: json['detail'] ?? json['message'],
      statusCode: statusCode,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}