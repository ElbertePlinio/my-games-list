import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/features/auth/auth_repository.dart';
import 'package:picklog/features/auth/sign_in/bloc/sign_in_event.dart';
import 'package:picklog/features/auth/sign_in/bloc/sign_in_state.dart';
import 'package:picklog/features/auth/sign_in/sign_in_request.dart';
import 'package:picklog/features/legal/legal_constants.dart';

/// BLoC that handles sign-in business logic.
class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc(this._authRepository) : super(const SignInInitial()) {
    on<SignInSubmitted>(_onSignInSubmitted);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
  }
  final AuthRepository _authRepository;

  Future<void> _onSignInSubmitted(
    SignInSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    emit(const SignInLoading());

    try {
      final request = SignInRequest(
        email: event.email,
        password: event.password,
      );

      final authResponse = await _authRepository.signIn(request);

      emit(SignInSuccess(authResponse));
    } catch (e) {
      emit(SignInError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<SignInState> emit,
  ) async {
    emit(const SignInLoading());
    try {
      // Google sign-in can create an account, so the API requires the accepted
      // consent version. The sign-in screen surfaces the Privacy Policy / Terms
      // links next to the social buttons; tapping Continue with Google is the
      // acceptance, mirroring common social-auth consent UX.
      final authResponse = await _authRepository.signInWithGoogle(
        consentVersion: kConsentVersion,
      );
      emit(SignInSuccess(authResponse));
    } catch (e) {
      emit(SignInError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
