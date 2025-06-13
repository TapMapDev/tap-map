import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/core/navigation/routes.dart';
import 'package:tap_map/features/auth/authorization_page.dart';
import 'package:tap_map/features/navbar/botom_nav_bar.dart';
import 'package:tap_map/features/password_reset/ui/new_password_page.dart';
import 'package:tap_map/features/password_reset/ui/pasword_reset_page.dart';
import 'package:tap_map/features/registration/registration_page.dart';
import 'package:tap_map/features/chat/presentation/pages/chat_list_screen.dart';
import 'package:tap_map/features/chat/presentation/pages/chat_screen.dart';
import 'package:tap_map/features/userFlow/map/major_map.dart';
import 'package:tap_map/features/userFlow/search_screen/search_page.dart';
import 'package:tap_map/features/user_profile/model/user_response_model.dart';
import 'package:tap_map/features/user_profile/ui/edit_profile_page.dart';
import 'package:tap_map/features/user_profile/ui/profile_share.dart';
import 'package:tap_map/features/user_profile/ui/public_user_profile.dart';
import 'package:tap_map/features/user_profile/ui/user_profile.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  debugLogDiagnostics: true,
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.authorization,
  redirect: (context, state) async {
    final prefs = GetIt.I<SharedPrefsRepository>();
    final token = await prefs.getAccessToken();
    final publicRoutes = [
      AppRoutes.authorization,
      AppRoutes.registration,
      AppRoutes.passwordReset,
      AppRoutes.newPassword,
      AppRoutes.publicProfile,
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
      builder: (context, state) => const AuthorizationPage(),
    ),
    GoRoute(
      path: AppRoutes.registration,
      builder: (context, state) => const RegistrationPage(),
    ),
    GoRoute(
      path: AppRoutes.newPassword,
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
    GoRoute(
      path: AppRoutes.shareProfile,
      builder: (context, state) {
        final username = state.uri.queryParameters['username'];
        return ProfileShareSection(username: username ?? '');
      },
    ),
    GoRoute(
      path: AppRoutes.publicProfile,
      builder: (context, state) {
        final username = state.pathParameters['username']!;
        return PublicUserProfileScreen(username: username);
      },
    ),
    GoRoute(
      path: AppRoutes.chat,
      builder: (context, state) {
        final chatId = state.uri.queryParameters['chatId'];
        final userId = state.uri.queryParameters['userId'];
        final username = state.uri.queryParameters['username'];

        if (chatId != null) {
          // Открываем чат по chatId (после создания чата)
          return ChatScreen(
            chatId: int.parse(chatId),
            chatName: username ?? 'Чат',
          );
        } else if (userId != null && username != null) {
          // Открываем чат по userId и username (старый вариант)
          return ChatScreen(
            chatId: int.parse(userId),
            chatName: username,
          );
        } else {
          // Нет нужных параметров — показываем ошибку
          return const Scaffold(
            body: Center(child: Text('Чат не найден')),
          );
        }
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return BottomNavbar(shell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.afisha,
              builder: (context, state) => const Center(child: Text('Афиша')),
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
              routes: [
                GoRoute(
                  path: ':pointId',
                  builder: (context, state) {
                    final id = state.pathParameters['pointId']!;
                    return MajorMap(openPointId: id);
                  },
                ),
                GoRoute(
                  path: 'event/:eventId',
                  builder: (context, state) {
                    final id = state.pathParameters['eventId']!;
                    return MajorMap(openEventId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.listChat,
              builder: (context, state) => const ChatListScreen(),
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
