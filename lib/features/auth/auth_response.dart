import 'package:equatable/equatable.dart';
import 'package:picklog/features/auth/user_model.dart';

/// Response model for authentication operations (signin/signup).
class AuthResponse extends Equatable {
  const AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;
    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(userJson),
    );
  }
  final String token;
  final User user;

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': {'id': user.id, 'email': user.email, 'username': user.username},
    };
  }

  @override
  List<Object?> get props => [token, user];
}
