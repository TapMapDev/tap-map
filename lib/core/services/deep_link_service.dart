import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:tap_map/router/routes.dart';

class DeepLinkService {
  final GoRouter router;
  final AppLinks _appLinks = AppLinks();

  DeepLinkService(this.router);

  Future<void> initialize() async {
    debugPrint('🔗 Initializing DeepLinkService');

    // 1️⃣ стартовая ссылка
    final initialLink = await _appLinks.getInitialLink();
    debugPrint('Initial link: $initialLink');
    if (initialLink != null) _handleUri(initialLink);

    // 2️⃣ все последующие
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('Got link: $uri');
      _handleUri(uri);
    });
  }

  void _handleUri(Uri uri) {
    debugPrint('🔗 Обработка deeplink: $uri');
    debugPrint('Scheme: ${uri.scheme}');
    debugPrint('Host: ${uri.host}');
    debugPrint('Path: ${uri.path}');
    debugPrint('Query parameters: ${uri.queryParameters}');

    // Проверяем схему и путь/хост
    if (uri.scheme == 'tapmap' &&
        (uri.path == '/reset_password_confirm' ||
            uri.path == 'reset_password_confirm' ||
            uri.host == 'reset_password_confirm')) {
      // Извлекаем параметры из URL
      Map<String, String> params = Map.from(uri.queryParameters);

      // Исправляем проблему с &amp;
      String? token = params['token'] ?? params['amp;token'];
      String? uid = params['uid'];

      debugPrint('📝 Extracted parameters:');
      debugPrint('UID: $uid');
      debugPrint('Token: $token');

      if (uid != null && token != null) {
        // Формируем чистый URL без amp;
        final path = '${AppRoutes.newPassword}?uid=$uid&token=$token';
        debugPrint('✅ Переход по пути: $path');
        router.go(path);
      } else {
        debugPrint('❌ Missing required parameters in deep link');
        debugPrint('All parameters: $params');
      }
    } else {
      debugPrint(
          '❌ Unhandled deep link: scheme=${uri.scheme}, path=${uri.path}, host=${uri.host}');
    }
  }
}
