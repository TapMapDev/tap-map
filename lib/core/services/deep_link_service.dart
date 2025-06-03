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

    // 1️⃣ стартовая ссылка
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) _handleUri(initialLink);

    // 2️⃣ все последующие
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('Got link: $uri');
      _handleUri(uri);
    });
  }

  Future<void> _handleUri(Uri uri) async {

    if (uri.scheme == 'tapmap') {
      if (uri.host == 'user') {
        // Извлекаем username из path, убирая @ если он есть
        final username = uri.path.replaceAll('/', '').replaceAll('@', '');
        final path = AppRoutes.publicProfile.replaceAll(':username', username);
        router.go(path);
      } else if (uri.path == '/reset_password_confirm' ||
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
      } else if (uri.host == 'point') {
        final id = uri.path.replaceAll('/', '');
        final path = AppRoutes.mapPoint.replaceAll(':pointId', id);
        router.go(path);
      } else if (uri.host == 'event') {
        final id = uri.path.replaceAll('/', '');
        final path = AppRoutes.mapEvent.replaceAll(':eventId', id);
        router.go(path);
      }
    } else if (uri.scheme == 'https' && uri.host == 'api.tap-map.net') {
      if (uri.path.startsWith('/api/users/link/')) {
        // Извлекаем username из path, убирая @ если он есть
        final username = uri.pathSegments.last.replaceAll('@', '');
        final path = AppRoutes.publicProfile.replaceAll(':username', username);
        router.go(path);
      }
    }
  }
}
