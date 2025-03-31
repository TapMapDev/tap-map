import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:talker/talker.dart';
import 'package:tap_map/core/network/api_service.dart';
import 'package:tap_map/core/network/dio_client.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/main.dart';
import 'package:tap_map/src/features/auth/data/authorization_repository.dart';
import 'package:tap_map/src/features/password_reset/data/password_reset_repository.dart';
import 'package:tap_map/src/features/registration/data/registration_repository.dart';
import 'package:tap_map/src/features/userFlow/map/icons/data/icons_repository.dart';
import 'package:tap_map/src/features/userFlow/map/styles/data/map_styles_repository.dart';
import 'package:tap_map/src/features/userFlow/search_screen/data/search_repository.dart';


final GetIt getIt = GetIt.instance;

void setup() {
  // Регистрация навигатора
  getIt.registerSingleton<GlobalKey<NavigatorState>>(navigatorKey);

  // Регистрация DioClient
  getIt.registerLazySingleton<DioClient>(() => DioClient());

  // Регистрация ApiService
  getIt.registerLazySingleton<ApiService>(() => ApiService(getIt<DioClient>()));

  // Регистрации Registaration

  getIt.registerLazySingleton<RegistrationRepositoryImpl>(
      () => RegistrationRepositoryImpl(apiService: getIt<ApiService>()));

  getIt.registerLazySingleton<AuthorizationRepositoryImpl>(
      () => AuthorizationRepositoryImpl(apiService: getIt<ApiService>()));

  getIt.registerLazySingleton<Talker>(() => Talker());

  getIt.registerLazySingleton<SharedPrefsRepository>(
      () => SharedPrefsRepository());
  // изменение стилей карты
  getIt.registerLazySingleton<MapStyleRepository>(
      () => MapStyleRepositoryImpl(apiService: getIt<ApiService>()));

  // подключение стилей иконок
  getIt.registerLazySingleton<IconsRepository>(
      () => IconsRepositoryImpl(apiService: getIt<ApiService>()));

  getIt.registerLazySingleton<ResetPasswordRepositoryImpl>(
      () => ResetPasswordRepositoryImpl(apiService: getIt<ApiService>()));

  getIt.registerLazySingleton<SearchRepository>(
      () => SearchRepositoryImpl(apiService: getIt<ApiService>()));
}
