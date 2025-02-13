class AuthorizationResponseModel {
  final int statusCode;
  final String? message;
  final String? accessToken;
  final String? refreshToken;

  AuthorizationResponseModel(
      {required this.message,
      required this.statusCode,
      required this.accessToken,
      required this.refreshToken});

  factory AuthorizationResponseModel.fromJson(
          Map<String, dynamic> json, int statusCode) =>
      AuthorizationResponseModel(
        message: json['detail'] ?? json['message'],
        statusCode: statusCode,
        accessToken: json['tokens']?['access'],
        refreshToken: json['tokens']?['refresh'],
      );
}
