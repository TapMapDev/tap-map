import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:tap_map/router/routes.dart';
import 'package:uni_links3/uni_links.dart';

class DeepLinkService {
  final GoRouter router;

  DeepLinkService(this.router);

  Future<void> initialize() async {
    final uri = await getInitialUri();
    if (uri != null) _handleUri(uri);

    uriLinkStream.listen((uri) {
      if (uri != null) _handleUri(uri);
    });
  }

  void _handleUri(Uri uri) {
    if (uri.host == 'reset_password_confirm') {
      final uid = uri.queryParameters['uid'];
      final token = uri.queryParameters['token'];

      final path = '${AppRoutes.newPassword}?uid=$uid&token=$token';
      router.go(path);
    }
  }
}
