import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uni_links3/uni_links.dart';

class DeepLinkService {
  final GlobalKey<NavigatorState> navigatorKey;

  DeepLinkService(this.navigatorKey);
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

      navigatorKey.currentState?.pushNamed(
        '/password_reset',
        arguments: {'uid': uid, 'token': token},
      );
    }
  }
}
