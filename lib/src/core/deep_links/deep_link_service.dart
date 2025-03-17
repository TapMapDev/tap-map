import 'package:flutter/services.dart';
import 'package:tap_map/src/features/password_reset/password_reset_repository.dart';

class DeepLinkService {
  static const platform = MethodChannel('com.tapmap.app/deep_links');
  final ResetPasswordRepositoryImpl _resetPasswordRepository;

  DeepLinkService(this._resetPasswordRepository);

  Future<void> initialize() async {
    platform.setMethodCallHandler(_handleMethod);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'handleDeepLink':
        final String url = call.arguments['url'] as String;
        await _handleDeepLink(url);
        break;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  Future<void> _handleDeepLink(String url) async {
    print('Handling deep link: $url');

    if (url.startsWith('tapmap://reset-password')) {
      try {
        _resetPasswordRepository.handleResetPasswordLink(url);
        // Navigate to reset password screen
        // You'll need to implement navigation here
      } catch (e) {
        print('Error handling reset password link: $e');
      }
    }
  }
}
