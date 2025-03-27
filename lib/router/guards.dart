import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/core/di/di.dart';

Future<String?> authGuard(BuildContext context, GoRouterState state) async {
  final prefs = getIt<SharedPrefsRepository>();
  final token = await prefs.getAccessToken();

  if (token == null || token.isEmpty) {
    // Если нет токена, редиректим на логин
    return '/';
  }

  // Всё ок, пускаем
  return null;
}

Future<String?> guestGuard(BuildContext context, GoRouterState state) async {
  final prefs = getIt<SharedPrefsRepository>();
  final token = await prefs.getAccessToken();

  if (token != null && token.isNotEmpty) {
    // Уже вошел, нет смысла показывать login/registration
    return '/home/map';
  }

  return null;
}