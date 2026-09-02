import 'package:equatable/equatable.dart';
import 'package:picklog/features/auth/auth_response.dart';

/// Base class for SignIn states.
sealed class SignInState extends Equatable {
  const SignInState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any sign-in attempt.
final class SignInInitial extends SignInState {
  const SignInInitial();
}

/// State when sign-in is in progress.
final class SignInLoading extends SignInState {
  const SignInLoading();
}

/// State when sign-in is successful.
final class SignInSuccess extends SignInState {
  const SignInSuccess(this.authResponse);
  final AuthResponse authResponse;

  @override
  List<Object?> get props => [authResponse];
}

/// State when sign-in fails.
final class SignInError extends SignInState {
  const SignInError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
