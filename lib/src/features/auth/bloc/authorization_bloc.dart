import 'package:bloc/bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/src/features/auth/data/authorization_repository.dart';

part 'authorization_event.dart';
part 'authorization_state.dart';

class AuthorizationBloc extends Bloc<AuthorizationEvent, AuthorizationState> {
  final AuthorizationRepositoryImpl authorizationRepositoryImpl;
  final SharedPrefsRepository _prefs = GetIt.I<SharedPrefsRepository>();

  AuthorizationBloc(this.authorizationRepositoryImpl)
      : super(AuthorizationInitial()) {
    on<AuthorizationSignInWithEmailPressedEvent>((event, emit) async {
      emit(AuthorizationInProcess());
      try {
        final response = await authorizationRepositoryImpl.authorize(
          login: event.login,
          password: event.password,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (response.accessToken != null && response.refreshToken != null) {
            emit(AuthorizationSuccess());
          } else {
            emit(AuthorizationFailed(
              errorMessage: response.message ?? 'Ошибка авторизации',
            ));
          }
        } else {
          emit(AuthorizationFailed(
            errorMessage: response.message ?? 'Ошибка авторизации',
          ));
        }
      } catch (e) {
        emit(AuthorizationFailed(errorMessage: 'Произошла ошибка: $e'));
      }
    });
    on<RefreshTokensEvent>((event, emit) async {
      emit(AuthorizationInProcess());
      try {
        await authorizationRepositoryImpl.initialize();
        emit(AuthorizationSuccess());
      } catch (e) {
        emit(AuthorizationFailed(
            errorMessage: 'Ошибка при обновлении токенов: $e'));
      }
    });
  }
}
