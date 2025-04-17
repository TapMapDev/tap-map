import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide StyleManager;
import 'package:tap_map/core/common/styles.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/core/services/deep_link_service.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/router/app_router.dart';
import 'package:tap_map/src/features/auth/bloc/authorization_bloc.dart';
import 'package:tap_map/src/features/auth/data/authorization_repository.dart';
import 'package:tap_map/src/features/password_reset/bloc/password_resert_bloc.dart';
import 'package:tap_map/src/features/password_reset/data/password_reset_repository.dart';
import 'package:tap_map/src/features/registration/bloc/registration_bloc.dart';
import 'package:tap_map/src/features/registration/data/registration_repository.dart';
import 'package:tap_map/src/features/userFlow/map/icons/bloc/icons_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/icons/data/icons_repository.dart';
import 'package:tap_map/src/features/userFlow/map/styles/bloc/map_styles_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/styles/data/map_styles_repository.dart';
import 'package:tap_map/src/features/userFlow/map/widgets/config.dart';
import 'package:tap_map/src/features/userFlow/search_screen/bloc/search_bloc.dart';
import 'package:tap_map/src/features/userFlow/search_screen/data/search_repository.dart';
import 'package:tap_map/src/features/userFlow/user_profile/bloc/user_information_bloc.dart';
import 'package:tap_map/src/features/userFlow/user_profile/data/user_repository.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  setup();
  MapboxOptions.setAccessToken(MapConfig.accessToken);

  final isAuthorized = await _initializeTokens();

  final router = appRouter;
  getIt.registerSingleton<GoRouter>(router);

  // Создаем DeepLinkService с роутером
  final deepLinkService = DeepLinkService(router);
  getIt.registerSingleton<DeepLinkService>(deepLinkService);

  runApp(MyApp(isAuthorized: isAuthorized));
  await deepLinkService.initialize();
}

// Функция для инициализации токенов при запуске
Future<bool> _initializeTokens() async {
  final prefs = getIt.get<SharedPrefsRepository>();
  final apiService = getIt.get<ApiService>();

  try {
    // Проверяем наличие токенов
    final refreshToken = await prefs.getRefreshToken();
    final accessToken = await prefs.getAccessToken();

    // Если есть refresh_token, пробуем обновить токены
    if (refreshToken != null) {
      final success = await apiService.refreshTokens();
      if (!success) {
        // Если обновление не удалось, очищаем токены
        await prefs.clear();
        return false;
      }
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('Error initializing tokens: $e');
    // В случае ошибки очищаем токены
    await prefs.clear();
    return false;
  }
}

class MyApp extends StatelessWidget {
  final bool isAuthorized;

  const MyApp({super.key, required this.isAuthorized});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthorizationBloc(getIt.get<AuthorizationRepositoryImpl>()),
          ),
          BlocProvider(
            create: (context) =>
                RegistrationBloc(getIt.get<RegistrationRepositoryImpl>()),
          ),
          BlocProvider(
            create: (context) => MapStyleBloc(getIt.get<MapStyleRepository>()),
          ),
          BlocProvider(
            create: (context) => IconsBloc(getIt.get<IconsRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                ResetPasswordBloc(getIt.get<ResetPasswordRepositoryImpl>()),
          ),
          BlocProvider<SearchBloc>(
            create: (context) => SearchBloc(
              getIt.get<SearchRepository>(),
            ),
          ),
          BlocProvider<UserBloc>(
            create: (context) => UserBloc(getIt.get<UserRepository>()),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
          title: 'Tap Map',
          theme: ThemeData(
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              surfaceTintColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: StyleManager.mainColor,
                foregroundColor: StyleManager.bgColor,
              ),
            ),
            scaffoldBackgroundColor: StyleManager.bgColor,
            fontFamily: 'regular',
          ),
        ));
  }
}
