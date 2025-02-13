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
import 'package:tap_map/src/features/auth/check_auth/check_auth.dart';
import 'package:tap_map/src/features/map/map_tilessets/config.dart';
import 'package:tap_map/src/features/map/major_map.dart';

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
        // BlocProvider<RegistrationBloc>(
        //     create: (_) => RegistrationBloc(getIt<
        //         RegistrationRepositoryImpl>())), // Регистрация AuthBloc
        //     BlocProvider<ResetPasswordBloc>(
        //         create: (_) =>
        //             ResetPasswordBloc(getIt<ResetPasswordRepositoryImpl>()))
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const CheckAuthPage(),
          '/authorization': (context) => const AuthorizationPage(),
          '/homepage': (context) => const MajorMap(),
          // '/registration': (context) => const RegistrationPage(),
          // '/password_reset': (context) => const ResetPasswordPage(),
          // '/therapeutic_games': (context) => const TherapeuticGames(),
          // '/analyze_emotion': (context) =>  AnalyzeEmotion(),
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
}
