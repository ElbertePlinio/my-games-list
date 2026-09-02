import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:picklog/core/data/services/storage/token_storage.dart';

/// [TokenStorage] backed by platform-secure storage: Keychain on iOS,
/// Keystore-encrypted storage on Android, and Web Crypto on web.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const String _tokenKey = 'auth_token';

  @override
  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<String?> read() => _storage.read(key: _tokenKey);

  @override
  Future<void> delete() => _storage.delete(key: _tokenKey);
}
