import 'package:bloc/bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';
import 'package:tap_map/core/shared_prefs/shared_prefs_repo.dart';
import 'package:tap_map/src/features/auth/data/authorization_repository.dart';
import 'package:talker/talker.dart';

part 'authorization_event.dart';
part 'authorization_state.dart';

class AuthorizationBloc extends Bloc<AuthorizationEvent, AuthorizationState> {
  final AuthorizationRepositoryImpl authorizationRepositoryImpl;
  final SharedPrefsRepository _prefs = GetIt.I<SharedPrefsRepository>();
  final Talker _talker = GetIt.I<Talker>();

  AuthorizationBloc(this.authorizationRepositoryImpl)
      : super(AuthorizationInitial()) {
    on<AuthorizationSignInWithEmailPressedEvent>((event, emit) async {
      emit(AuthorizationInProcess());
      _talker.info('Starting authorization process for login: ${event.login}');
      try {
        final response = await authorizationRepositoryImpl.authorize(
          login: event.login,
          password: event.password,
        );

        _talker.info(
            'Authorization response received. Status code: ${response.statusCode}');
        _talker.info('Access token present: ${response.accessToken != null}');
        _talker.info('Refresh token present: ${response.refreshToken != null}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (response.accessToken != null && response.refreshToken != null) {
            _talker.info('Saving access token...');
            await _prefs.saveAccessToken(response.accessToken!);
            _talker.info('Access token saved successfully');

            _talker.info('Saving refresh token...');
            await _prefs.saveRefreshToken(response.refreshToken!);
            _talker.info('Refresh token saved successfully');

            // Verify tokens were saved
            final savedAccessToken = await _prefs.getAccessToken();
            final savedRefreshToken = await _prefs.getRefreshToken();
            _talker.info(
                'Verification - Access token saved: ${savedAccessToken != null}');
            _talker.info(
                'Verification - Refresh token saved: ${savedRefreshToken != null}');

            emit(AuthorizationSuccess());
            _talker.info('Authorization completed successfully');
          } else {
            _talker.error('Tokens missing in response');
            emit(AuthorizationFailed(
              errorMessage: response.message ?? 'Ошибка авторизации',
            ));
          }
        } else {
          _talker.error(
              'Authorization failed with status code: ${response.statusCode}');
          emit(AuthorizationFailed(
            errorMessage: response.message ?? 'Ошибка авторизации',
          ));
        }
      } catch (e) {
        _talker.error('Authorization error: $e');
        emit(AuthorizationFailed(errorMessage: 'Произошла ошибка: $e'));
      }
    });
    on<RefreshTokensEvent>((event, emit) async {
      emit(AuthorizationInProcess());
      _talker.info('Starting token refresh process');
      try {
        await authorizationRepositoryImpl.initialize();
        _talker.info('Token refresh completed successfully');
        emit(AuthorizationSuccess());
      } catch (e) {
        _talker.error('Token refresh error: $e');
        emit(AuthorizationFailed(
            errorMessage: 'Ошибка при обновлении токенов: $e'));
      }
    });
    
    // Обработчик для авторизации через Google
    on<AuthorizationSignInWithGooglePressedEvent>((event, emit) async {
      emit(AuthorizationInProcess());
      _talker.info('Starting Google authorization process');
      try {
        final response = await authorizationRepositoryImpl.signInWithGoogle();
        _talker.info('Google authorization response received. Status code: ${response.statusCode}');
        
        // Обработка ответа аналогично email/password
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (response.accessToken != null && response.refreshToken != null) {
            _talker.info('Tokens received, authorizing user');
            emit(AuthorizationSuccess());
          } else {
            _talker.error('Tokens missing in Google auth response');
            emit(AuthorizationFailed(
              errorMessage: response.message ?? 'Ошибка авторизации через Google',
            ));
          }
        } else {
          _talker.error('Google authorization failed with status code: ${response.statusCode}');
          emit(AuthorizationFailed(
            errorMessage: response.message ?? 'Ошибка авторизации через Google',
          ));
        }
      } catch (e) {
        _talker.error('Google authorization error: $e');
        emit(AuthorizationFailed(errorMessage: 'Ошибка авторизации через Google: $e'));
      }
    });
    
    // Обработчик для авторизации через Facebook
    on<AuthorizationSignInWithFacebookPressedEvent>((event, emit) async {
      emit(AuthorizationInProcess());
      _talker.info('Starting Facebook authorization process');
      try {
        final response = await authorizationRepositoryImpl.signInWithFacebook();
        _talker.info('Facebook authorization response received. Status code: ${response.statusCode}');
        
        // Обработка ответа аналогично email/password
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (response.accessToken != null && response.refreshToken != null) {
            _talker.info('Tokens received, authorizing user');
            emit(AuthorizationSuccess());
          } else {
            _talker.error('Tokens missing in Facebook auth response');
            emit(AuthorizationFailed(
              errorMessage: response.message ?? 'Ошибка авторизации через Facebook',
            ));
          }
        } else {
          _talker.error('Facebook authorization failed with status code: ${response.statusCode}');
          emit(AuthorizationFailed(
            errorMessage: response.message ?? 'Ошибка авторизации через Facebook',
          ));
        }
      } catch (e) {
        _talker.error('Facebook authorization error: $e');
        emit(AuthorizationFailed(errorMessage: 'Ошибка авторизации через Facebook: $e'));
      }
    });
  }
}
