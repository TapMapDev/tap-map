import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:tap_map/core/common/styles.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide StyleManager;
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/src/features/auth/authorization_page.dart';
import 'package:tap_map/src/features/auth/authorization_repository.dart';
import 'package:tap_map/src/features/auth/bloc/authorization_bloc.dart';
import 'package:tap_map/src/features/map/major_map.dart';

import 'package:tap_map/src/features/map/map_tilessets/config.dart';
import 'package:tap_map/src/features/navbar/botom_nav_bar.dart';
import 'package:tap_map/src/features/registration/bloc/registration_bloc.dart';
import 'package:tap_map/src/features/registration/registration_page.dart';
import 'package:tap_map/src/features/registration/registration_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  MapboxOptions.setAccessToken(MapConfig.accessToken);
  setup();
  runApp(const MyApp());
  await _setupPositionTracking();
}

Future<void> _setupPositionTracking() async {
  bool serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return;

  gl.LocationPermission permission = await gl.Geolocator.checkPermission();
  if (permission == gl.LocationPermission.denied) {
    permission = await gl.Geolocator.requestPermission();
    if (permission == gl.LocationPermission.denied ||
        permission == gl.LocationPermission.deniedForever) {
      return;
    }
  }

  gl.Position position = await gl.Geolocator.getCurrentPosition();
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
        home: 
        FutureBuilder<Widget>(
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
          // '/': (context) => const MajorMap(),
          '/authorization': (context) =>  MajorMap(),
          
          '/homepage': (context) =>
              const BottomNavbar(), // Ваш основной экран с BottomNavigationBar
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
    final String? access = prefs.getString('access_token');
    if (access != null) {
      return BottomNavbar(); // Если пользователь авторизован
    } else {
      return AuthorizationPage(); // Если не авторизован
    }
  }
}
