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
    String? message;

    if (json['detail'] is List) {
      message = (json['detail'] as List).join(', ');
    } else if (json['detail'] != null) {
      message = json['detail'].toString();
    } else if (json['message'] != null) {
      message = json['message'].toString();
    }

    return AuthorizationResponseModel(
      message: message,
      statusCode: statusCode,
      accessToken: json['access'],
      refreshToken: json['refresh'],
    );
  }
}
