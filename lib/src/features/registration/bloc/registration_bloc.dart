import 'package:bloc/bloc.dart';
import 'package:tap_map/src/features/registration/data/registration_repository.dart';

part 'registration_event.dart';
part 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final RegistrationRepository registrationRepository;
  RegistrationBloc(this.registrationRepository)
      : super(RegistrationStateInitial()) {
    on<RegistrationCreateAccountEvent>((event, emit) async {
      emit(RegistarationStateInProccess());
      final response = await registrationRepository.register(
        username: event.username,
        email: event.email,
        password1: event.password1,
        password2: event.password2,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(RegistarationStateSuccess());
      } else {
        emit(RegistarationStatenError(errorMessage: response.error));
      }
    });
  }
}
