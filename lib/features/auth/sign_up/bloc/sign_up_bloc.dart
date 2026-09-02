import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/features/auth/auth_repository.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_event.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_state.dart';
import 'package:picklog/features/auth/sign_up/sign_up_request.dart';
import 'package:picklog/features/legal/legal_constants.dart';

/// BLoC that handles sign-up business logic.
class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  SignUpBloc(this._authRepository) : super(const SignUpInitial()) {
    on<SignUpSubmitted>(_onSignUpSubmitted);
  }
  final AuthRepository _authRepository;

  Future<void> _onSignUpSubmitted(
    SignUpSubmitted event,
    Emitter<SignUpState> emit,
  ) async {
    // Consent is mandatory: refuse to create an account (and to send the
    // request) unless the Privacy Policy and Terms were accepted. The UI also
    // disables the button, so this is the authoritative guard.
    if (!event.acceptedTerms) {
      emit(const SignUpTermsNotAccepted());
      return;
    }

    emit(const SignUpLoading());

    try {
      final request = SignUpRequest(
        email: event.email,
        password: event.password,
        username: event.username,
        consentVersion: kConsentVersion,
      );

      final authResponse = await _authRepository.signUp(request);

      emit(SignUpSuccess(authResponse));
    } catch (e) {
      emit(SignUpError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
