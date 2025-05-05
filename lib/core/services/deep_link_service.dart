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
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) _handleUri(initialLink);

    _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    });
  }

  void _handleUri(Uri uri) {
    // Проверяем схему и путь/хост
    if (uri.scheme == 'tapmap') {
      if (uri.path == '/reset_password_confirm' ||
          uri.path == 'reset_password_confirm' ||
          uri.host == 'reset_password_confirm') {
        // Извлекаем параметры из URL
        Map<String, String> params = Map.from(uri.queryParameters);

        // Исправляем проблему с &amp;
        String? token = params['token'] ?? params['amp;token'];
        String? uid = params['uid'];

        if (uid != null && token != null) {
          // Формируем чистый URL без amp;
          final path = '${AppRoutes.newPassword}?uid=$uid&token=$token';
          router.go(path);
        }
      } else if (uri.host == 'user' && uri.path.startsWith('/@')) {
        // Обработка ссылок на профиль пользователя
        final username =
            uri.path.substring(1); // Убираем только / из пути, сохраняя @
        final path = '/user/$username';
        router.go(path);
      }
    }
  }
}
