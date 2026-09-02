import 'package:equatable/equatable.dart';
import 'package:picklog/features/auth/auth_response.dart';

/// Base class for SignUp states.
sealed class SignUpState extends Equatable {
  const SignUpState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any sign-up attempt.
final class SignUpInitial extends SignUpState {
  const SignUpInitial();
}

/// State when sign-up is in progress.
final class SignUpLoading extends SignUpState {
  const SignUpLoading();
}

/// State when sign-up is successful.
final class SignUpSuccess extends SignUpState {
  const SignUpSuccess(this.authResponse);
  final AuthResponse authResponse;

  @override
  List<Object?> get props => [authResponse];
}

/// State when sign-up fails.
final class SignUpError extends SignUpState {
  const SignUpError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Emitted when submission is attempted without accepting the Privacy Policy
/// and Terms. The UI surfaces a localized prompt; the message is intentionally
/// not carried here so it can be localized at the presentation layer.
final class SignUpTermsNotAccepted extends SignUpState {
  const SignUpTermsNotAccepted();
}
