import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:tap_map/core/common/styles.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide StyleManager;
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/src/features/auth/authorization_page.dart';
import 'package:tap_map/src/features/auth/authorization_repository.dart';
import 'package:tap_map/src/features/auth/bloc/authorization_bloc.dart';

import 'package:tap_map/src/features/map/map_tilessets/config.dart';
import 'package:tap_map/src/features/navbar/major_page.dart';
import 'package:tap_map/src/features/registration/bloc/registration_bloc.dart';
import 'package:tap_map/src/features/registration/registration_page.dart';
import 'package:tap_map/src/features/registration/registration_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  MapboxOptions.setAccessToken(MapConfig.accessToken);
  setup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthorizationBloc>(
            create: (_) =>
                AuthorizationBloc(getIt<AuthorizationRepositoryImpl>())),
        BlocProvider<RegistrationBloc>(
            create: (_) => RegistrationBloc(
                getIt<RegistrationRepositoryImpl>())), // Регистрация AuthBloc
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        home: FutureBuilder<Widget>(
          future: _getInitialPage(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text("Ошибка загрузки данных"));
            } else {
              return snapshot.data!;
            }
          },
        ),
        routes: {
          '/authorization': (context) => const AuthorizationPage(),
          '/homepage': (context) => const MainPage(), // Ваш основной экран с BottomNavigationBar
          '/registration': (context) => const RegistrationPage(),
        },
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

  // Проверка, залогинен ли пользователь
  Future<Widget> _getInitialPage() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (isLoggedIn) {
      return const MainPage(); // Если пользователь авторизован
    } else {
      return const AuthorizationPage(); // Если не авторизован
    }
  }
}


