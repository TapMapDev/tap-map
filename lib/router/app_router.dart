import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tap_map/router/guards.dart';
import 'package:tap_map/router/routes.dart';
import 'package:tap_map/src/features/auth/authorization_page.dart';
import 'package:tap_map/src/features/navbar/botom_nav_bar.dart';
import 'package:tap_map/src/features/password_reset/pasword_reset_page.dart';
import 'package:tap_map/src/features/registration/registration_page.dart';
import 'package:tap_map/src/features/userFlow/map/major_map.dart';
import 'package:tap_map/src/features/userFlow/search_screen/search_page.dart';
import 'package:tap_map/src/features/userFlow/user_profile/user_profile.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.map,
  routes: [
    GoRoute(
      path: AppRoutes.authorization,
      redirect: guestGuard,
      builder: (context, state) => const AuthorizationPage(),
    ),
    GoRoute(
      path: AppRoutes.registration,
      redirect: guestGuard,
      builder: (context, state) => const RegistrationPage(),
    ),
    GoRoute(
      path: AppRoutes.passwordReset,
      redirect: guestGuard,
      builder: (context, state) {
        final uid = state.uri.queryParameters['uid'];
        final token = state.uri.queryParameters['token'];
        return ResetPasswordPage(uid: uid, token: token);
      },
    ),
    StatefulShellRoute.indexedStack(
      redirect: authGuard,
      builder: (context, state, navigationShell) {
        return BottomNavbar(shell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.map,
              builder: (context, state) => const MajorMap(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.search,
              builder: (context, state) => const SearchPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              builder: (context, state) {
                return const Center(child: Text('Чат Placeholder'));
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const UserProfileScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/afisha',
              builder: (context, state) {
                return const Center(child: Text('Афиша Placeholder'));
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
