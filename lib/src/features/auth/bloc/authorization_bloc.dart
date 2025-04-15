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
      final response = await authorizationRepositoryImpl.authorize(
          login: event.login, password: event.password);
      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(AuthorizationSuccess());
      } else {
        emit(AuthorizationFailed(errorMessage: response.message));
      }
    });
    on<CheckAuthorizationEvent>((event, emit) async {
      try {
        final isAuthorized = await authorizationRepositoryImpl.isAuthorized();
        if (isAuthorized) {
          emit(AuthorizedState()); // Авторизован
        } else {
          emit(UnAuthorizedState()); // Не авторизован
        }
      } catch (e) {
        emit(UnAuthorizedState()); // Ошибка или не авторизован
      }
    });
    on<LogoutEvent>((event, emit) async {
      try {
        await authorizationRepositoryImpl.logout();
        await _prefs.clear(); // Очищаем все данные
        emit(UnAuthorizedState());
      } catch (e) {
        emit(AuthorizationFailed(errorMessage: 'Ошибка при выходе: $e'));
      }
    });
  }
}
