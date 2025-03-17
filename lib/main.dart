import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide StyleManager;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tap_map/core/common/styles.dart';
import 'package:tap_map/core/di/di.dart';
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

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setup();
  await dotenv.load(fileName: ".env");
  MapboxOptions.setAccessToken(MapConfig.accessToken);

  runApp(const MyApp());
  // await _setupPositionTracking();
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
      ],
      child: GetMaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Tap Map',
        routes: {
          '/authorization': (context) => const AuthorizationPage(),
          '/registration': (context) => const RegistrationPage(),
          '/homepage': (context) => const BottomNavbar(),
          '/password_reset': (context) => const ResetPasswordPage(),
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
          appBarTheme: const AppBarTheme(surfaceTintColor: Colors.transparent),
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
    final prefs = await SharedPreferences.getInstance();
    final String? access = prefs.getString('access_token');
    debugPrint("🔍 Читаем access_token: $access");
    if (access != null) {
      return const BottomNavbar();
    } else {
      return const AuthorizationPage();
    }
  }
}
