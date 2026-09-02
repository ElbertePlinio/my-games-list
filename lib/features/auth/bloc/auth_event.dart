import 'package:equatable/equatable.dart';
import 'package:picklog/features/auth/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to set authenticated state with a user from API response
class AuthUserAuthenticated extends AuthEvent {
  const AuthUserAuthenticated(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthStateLoaded extends AuthEvent {
  const AuthStateLoaded();
}
