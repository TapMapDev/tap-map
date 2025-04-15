import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/router/routes.dart';

Future<String?> authGuard(BuildContext context, GoRouterState state) async {
  final prefs = getIt<SharedPrefsRepository>();
  final token = await prefs.getAccessToken();

  if (token == null || token.isEmpty) {
    return AppRoutes.authorization;
  }
  return null;
}

Future<String?> guestGuard(BuildContext context, GoRouterState state) async {
  final prefs = getIt<SharedPrefsRepository>();
  final token = await prefs.getAccessToken();

  if (token != null && token.isNotEmpty) {
    return AppRoutes.map;
  }

  return null;
}
