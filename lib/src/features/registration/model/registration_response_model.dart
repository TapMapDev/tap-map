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
        error: json['username']?[0] ??
            json['email']?[0] ??
            json['non_field_errors']?[0] ??
            json['password1']?[0] ??
            json['password2']?[0]);
  }
}