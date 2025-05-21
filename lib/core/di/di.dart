import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide StyleManager;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker/talker.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/core/network/dio_client.dart';
import 'package:tap_map/core/services/deep_link_service.dart';
import 'package:tap_map/core/services/notification_service.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/core/websocket/websocket_service.dart';
import 'package:tap_map/main.dart';
import 'package:tap_map/router/app_router.dart';
import 'package:tap_map/src/features/auth/bloc/authorization_bloc.dart';
import 'package:tap_map/src/features/auth/data/authorization_repository.dart';
import 'package:tap_map/src/features/password_reset/data/password_reset_repository.dart';
import 'package:tap_map/src/features/registration/data/registration_repository.dart';
import 'package:tap_map/src/features/userFlow/chat/data/chat_repository.dart';
import 'package:tap_map/src/features/userFlow/map/icons/data/icons_repository.dart';
import 'package:tap_map/src/features/userFlow/map/styles/data/map_styles_repository.dart';
import 'package:tap_map/src/features/userFlow/map/widgets/config.dart';
import 'package:tap_map/src/features/userFlow/search_screen/data/search_repository.dart';
import 'package:tap_map/src/features/userFlow/user_profile/bloc/user_information_bloc.dart';
import 'package:tap_map/src/features/userFlow/user_profile/data/user_repository.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/data/repository/place_repository_impl.dart';
import 'package:tap_map/src/features/userFlow/map/point_detail/bloc/place_detail_bloc.dart';

final getIt = GetIt.instance;

Future<void> setup() async {
  // Регистрация навигатора
  getIt.registerSingleton<GlobalKey<NavigatorState>>(navigatorKey);

  // Регистрация SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Регистрация DioClient
  getIt.registerLazySingleton<DioClient>(() => DioClient());

  getIt.registerLazySingleton<ApiService>(() => ApiService(getIt<DioClient>()));

  getIt.registerLazySingleton<RegistrationRepositoryImpl>(
      () => RegistrationRepositoryImpl(apiService: getIt<ApiService>()));

  getIt.registerLazySingleton<AuthorizationRepositoryImpl>(
      () => AuthorizationRepositoryImpl(apiService: getIt<ApiService>()));

  getIt.registerLazySingleton<Talker>(() => Talker());

  getIt.registerLazySingleton<SharedPrefsRepository>(
      () => SharedPrefsRepository());

  getIt.registerLazySingleton<MapStyleRepository>(
      () => MapStyleRepositoryImpl(apiService: getIt<ApiService>()));

  getIt.registerLazySingleton<IconsRepository>(
      () => IconsRepositoryImpl(apiService: getIt<ApiService>()));

  getIt.registerLazySingleton<ResetPasswordRepositoryImpl>(
      () => ResetPasswordRepositoryImpl(apiService: getIt<ApiService>()));

  getIt.registerLazySingleton<SearchRepository>(
      () => SearchRepositoryImpl(apiService: getIt<ApiService>()));

  getIt.registerLazySingleton<UserRepository>(
      () => UserRepository(apiService: getIt<ApiService>()));

  getIt.registerFactory<UserBloc>(() => UserBloc(getIt<UserRepository>()));

  getIt.registerFactory<AuthorizationBloc>(
    () => AuthorizationBloc(getIt<AuthorizationRepositoryImpl>()),
  );

  // Place Detail
  getIt.registerLazySingleton<PlaceRepositoryImpl>(
          () => PlaceRepositoryImpl(getIt()));
  getIt.registerFactory(() => PlaceDetailBloc(getIt()));

  // Register ChatRepository
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepository(
      dioClient: getIt<DioClient>(),
      prefs: getIt<SharedPreferences>(),
    ),
  );

  // WebSocket Service
  getIt.registerFactoryParam<WebSocketService, String, void>(
    (jwtToken, _) => WebSocketService(jwtToken: jwtToken),
  );

  // Инициализация Mapbox
  MapboxOptions.setAccessToken(MapConfig.accessToken);

  // Инициализация NotificationService
  final notificationService = NotificationService();
  await notificationService.initialize();
  getIt.registerSingleton<NotificationService>(notificationService);

  // Инициализация DeepLinkService
  final router = appRouter;
  getIt.registerSingleton<GoRouter>(router);
  final deepLinkService = DeepLinkService(router);
  getIt.registerSingleton<DeepLinkService>(deepLinkService);
  await deepLinkService.initialize();
}
