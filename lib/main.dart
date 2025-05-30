import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tap_map/ui/theme/OLD_app_text_styles.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/firebase_options.dart';
import 'package:tap_map/router/app_router.dart';
import 'package:tap_map/src/features/auth/bloc/authorization_bloc.dart';
import 'package:tap_map/src/features/auth/data/authorization_repository.dart';
import 'package:tap_map/src/features/password_reset/bloc/password_resert_bloc.dart';
import 'package:tap_map/src/features/password_reset/data/password_reset_repository.dart';
import 'package:tap_map/src/features/registration/bloc/registration_bloc.dart';
import 'package:tap_map/src/features/registration/data/registration_repository.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/chat_bloc/chat_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/data/chat_repository.dart';
import 'package:tap_map/src/features/userFlow/map/icons/bloc/icons_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/icons/data/icons_repository.dart';
import 'package:tap_map/src/features/userFlow/map/styles/bloc/map_styles_bloc.dart';
import 'package:tap_map/src/features/userFlow/map/styles/data/map_styles_repository.dart';
import 'package:tap_map/src/features/userFlow/search_screen/bloc/search_bloc.dart';
import 'package:tap_map/src/features/userFlow/search_screen/data/search_repository.dart';
import 'package:tap_map/src/features/userFlow/user_profile/bloc/user_information_bloc.dart';
import 'package:tap_map/src/features/userFlow/user_profile/data/user_repository.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/reply_bloc/reply_bloc.dart';
import 'package:tap_map/src/features/userFlow/chat/bloc/message_actions_bloc/message_actions_bloc.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: '.env');
  await setup();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage msg) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
          BlocProvider<UserBloc>(
            create: (context) => UserBloc(getIt.get<UserRepository>()),
          ),
          BlocProvider(
            create: (context) => ChatBloc(
              chatRepository: getIt.get<ChatRepository>(),
              prefsRepository: getIt.get<SharedPrefsRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => MessageActionsBloc(
              chatRepository: getIt.get<ChatRepository>(),
              webSocketService: getIt.get<ChatWebSocketService>(),
            ),
          ),
          BlocProvider(
            create: (context) => ReplyBloc(),
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
