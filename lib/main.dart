import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide StyleManager;
import 'package:tap_map/core/common/styles.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/src/core/deep_links/deep_link_service.dart';
import 'package:tap_map/src/features/auth/authorization_page.dart';
import 'package:tap_map/src/features/auth/authorization_repository.dart';
import 'package:tap_map/src/features/auth/bloc/authorization_bloc.dart';
import 'package:tap_map/src/features/navbar/botom_nav_bar.dart';
import 'package:tap_map/src/features/password_reset/bloc/password_resert_bloc.dart';
import 'package:tap_map/src/features/password_reset/password_reset_repository.dart';
import 'package:tap_map/src/features/password_reset/pasword_reset_page.dart';
import 'package:tap_map/src/features/registration/bloc/registration_bloc.dart';
import 'package:tap_map/src/features/registration/registration_page.dart';
import 'package:tap_map/src/features/registration/registration_repository.dart';
import 'package:tap_map/src/features/userFlow/map/icons/bloc/icons_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/icons/icons_repository.dart';
import 'package:tap_map/src/features/userFlow/map/styles/bloc/map_styles_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/styles/map_styles_repository.dart';
import 'package:tap_map/src/features/userFlow/map/widgets/config.dart';
import 'package:tap_map/src/features/userFlow/search_screen/bloc/search_bloc.dart';
import 'package:tap_map/src/features/userFlow/search_screen/search_page.dart';
import 'package:tap_map/src/features/userFlow/search_screen/search_repository.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setup();
  await dotenv.load(fileName: ".env");
  MapboxOptions.setAccessToken(MapConfig.accessToken);

  // Инициализация токена - пробуем обновить при каждом запуске
  try {
    await _initializeTokens();
  } catch (e) {
    debugPrint("Ошибка при инициализации токенов: $e");
  }

  // Initialize deep link service
  final deepLinkService = getIt<DeepLinkService>();
  await deepLinkService.initialize();

  runApp(const MyApp());
  // await _setupPositionTracking();
}

// Функция для инициализации токенов при запуске
Future<void> _initializeTokens() async {
  final prefs = getIt.get<SharedPrefsRepository>();
  final apiService = getIt.get<ApiService>();

  // Проверяем наличие токенов
  final refreshToken = await prefs.getRefreshToken();
  final accessToken = await prefs.getAccessToken();

  debugPrint(
      "🔑 При запуске: access_token ${accessToken != null ? "существует" : "отсутствует"}");
  debugPrint(
      "🔑 При запуске: refresh_token ${refreshToken != null ? "существует" : "отсутствует"}");

  // Если есть refresh_token, пробуем обновить токены
  if (refreshToken != null) {
    final success = await apiService.refreshTokens();
    debugPrint(
        "🔄 Обновление токенов при запуске: ${success ? "успешно" : "не удалось"}");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      ],
      child: GetMaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Tap Map',
        routes: {
          '/authorization': (context) => const AuthorizationPage(),
          '/registration': (context) => const RegistrationPage(),
          '/homepage': (context) => const BottomNavbar(),
          '/password_reset': (context) {
            final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;

            return ResetPasswordPage(
              uid: args?['uid'],
              token: args?['token'],
            );
          },
          '/search': (context) => const SearchPage(),
        },
        home: FutureBuilder<Widget>(
          future: _getInitialPage(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return snapshot.data!;
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
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
      ),
    );
  }

  Future<Widget> _getInitialPage() async {
    final prefs = getIt.get<SharedPrefsRepository>();
    final String? access = await prefs.getAccessToken();
    debugPrint("🔍 Читаем access_token: $access");

    if (access != null) {
      return const BottomNavbar();
    } else {
      return const AuthorizationPage();
    }
  }
}
