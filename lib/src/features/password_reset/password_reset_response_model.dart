class PasswordResetModel {
  final int statusCode;
  final String? message;

  PasswordResetModel({
    required this.statusCode,
    this.message,
  });

  factory PasswordResetModel.fromJson(
      Map<String, dynamic> json, int statusCode) {
    String? message;

    if (json.isEmpty) {
      message = 'Password reset instructions have been sent to your email';
    } else if (json['success'] != null) {
      message = json['success'].toString();
    } else if (json['email'] != null) {
      if (json['email'] is List) {
        message = (json['email'] as List).first.toString();
      } else {
        message = json['email'].toString();
      }
    } else if (json['error'] != null) {
      message = json['error'].toString();
    } else if (json['message'] != null) {
      message = json['message'].toString();
    } else if (json['detail'] != null) {
      message = json['detail'].toString();
    }

    return PasswordResetModel(
      message:
          message ?? 'Password reset instructions have been sent to your email',
      statusCode: statusCode,
    );
  }
}
