import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:tap_map/src/features/auth/data/authorization_repository.dart';


part 'authorization_event.dart';
part 'authorization_state.dart';

class AuthorizationBloc extends Bloc<AuthorizationEvent, AuthorizationState> {
  final AuthorizationRepositoryImpl authorizationRepositoryImpl;
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
        final isAuthorized = await authorizationRepositoryImpl.isAuth orized();
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
      await authorizationRepositoryImpl.logout();
      emit(UnAuthorizedState());
    });
  }
}
