import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tap_map/ui/theme/OLD_app_text_styles.dart';
import 'package:tap_map/core/di/di.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/firebase_options.dart';
import 'package:tap_map/core/navigation/app_router.dart';
import 'package:tap_map/features/auth/bloc/authorization_bloc.dart';
import 'package:tap_map/features/auth/data/authorization_repository.dart';
import 'package:tap_map/features/password_reset/bloc/password_resert_bloc.dart';
import 'package:tap_map/features/password_reset/data/password_reset_repository.dart';
import 'package:tap_map/features/registration/bloc/registration_bloc.dart';
import 'package:tap_map/features/registration/data/registration_repository.dart';
import 'package:tap_map/features/chat/presentation/bloc/chat_bloc/chat_bloc.dart';
import 'package:tap_map/features/chat/data/repositories/chat_repository.dart';
import 'package:tap_map/features/map/icons/bloc/icons_bloc.dart';
import 'package:tap_map/features/map/icons/data/icons_repository.dart';
import 'package:tap_map/features/map/styles/bloc/map_styles_bloc.dart';
import 'package:tap_map/features/map/styles/data/map_styles_repository.dart';
import 'package:tap_map/features/search/bloc/search_bloc.dart';
import 'package:tap_map/features/search/data/repositories/search_repository.dart';
import 'package:tap_map/features/user_profile/bloc/user_information_bloc.dart';
import 'package:tap_map/features/user_profile/data/user_repository.dart';
import 'package:tap_map/features/chat/presentation/bloc/reply_bloc/reply_bloc.dart';
import 'package:tap_map/features/chat/presentation/bloc/delete_message/delete_message_bloc.dart';
import 'package:tap_map/features/chat/presentation/bloc/edit_bloc/edit_bloc.dart';


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
          // Закомментирован функционал закрепления сообщений
          // Закрепить
          // BlocProvider(
          //   create: (context) => PinBloc(
          //     chatRepository: getIt.get<ChatRepository>(),
          //   ),
          // ),
          BlocProvider(
            create: (context) => ReplyBloc(),
          ),
          BlocProvider(
            create: (context) => DeleteMessageBloc(
              chatRepository: getIt.get<ChatRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => EditBloc(
              chatRepository: getIt.get<ChatRepository>(),
            ),
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
