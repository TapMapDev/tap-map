import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/router/routes.dart';
import 'package:tap_map/src/features/auth/authorization_page.dart';
import 'package:tap_map/src/features/navbar/botom_nav_bar.dart';
import 'package:tap_map/src/features/password_reset/ui/new_password_page.dart';
import 'package:tap_map/src/features/password_reset/ui/pasword_reset_page.dart';
import 'package:tap_map/src/features/registration/registration_page.dart';
import 'package:tap_map/src/features/userFlow/map/major_map.dart';
import 'package:tap_map/src/features/userFlow/search_screen/search_page.dart';
import 'package:tap_map/src/features/userFlow/user_profile/ui/user_profile.dart';
import 'package:tap_map/src/features/userFlow/user_profile/ui/edit_profile_page.dart';
import 'package:tap_map/src/features/userFlow/user_profile/model/user_response_model.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GoRouter appRouter = GoRouter(
  debugLogDiagnostics: true,
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.map,
  redirect: (context, state) async {
    final prefs = GetIt.I<SharedPrefsRepository>();
    final token = await prefs.getAccessToken();

    print('Redirecting to ${state.matchedLocation}, token: $token');

    final publicRoutes = [
      AppRoutes.authorization,
      AppRoutes.registration,
      AppRoutes.passwordReset,
      AppRoutes.newPassword,
    ];
    final isPublic =
        publicRoutes.any((route) => state.matchedLocation.startsWith(route));

    if (token == null && !isPublic) {
      return AppRoutes.authorization;
    }

    if (token != null &&
        (state.matchedLocation == AppRoutes.authorization ||
            state.matchedLocation == AppRoutes.registration)) {
      return AppRoutes.map;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.authorization,
      // redirect: guestGuard,
      builder: (context, state) => const AuthorizationPage(),
    ),
    GoRoute(
      path: AppRoutes.registration,
      // redirect: guestGuard,
      builder: (context, state) => const RegistrationPage(),
    ),
    GoRoute(
      path: AppRoutes.newPassword,
      // redirect: guestGuard,
      builder: (context, state) {
        final uid = state.uri.queryParameters['uid'];
        final token = state.uri.queryParameters['token'];
        return NewPasswordPage(uid: uid, token: token);
      },
    ),
    GoRoute(
      path: AppRoutes.passwordReset,
      builder: (context, state) => const PasswordRequestPage(),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      builder: (context, state) {
        final user = state.extra as UserModel;
        return EditProfileScreen(user: user);
      },
    ),
    StatefulShellRoute.indexedStack(
      // redirect: authGuard,
      builder: (context, state, navigationShell) {
        return BottomNavbar(shell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.afisha,
              builder: (context, state) {
                return const Center(child: Text('Афиша'));
              },
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
              path: AppRoutes.map,
              builder: (context, state) => const MajorMap(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              builder: (context, state) {
                return const Center(child: Text('Чат'));
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
      ],
    ),
  ],
);
