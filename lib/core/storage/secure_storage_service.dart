import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage] for the JWT + raw session
/// payload. Never store auth data in `shared_preferences` (insecure). Copied
/// pattern-for-pattern from Dad-mobile/lib/core/storage/secure_storage_service.dart.
class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _userInfoKey = 'auth_user_info';

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  /// Raw JSON string of the login response (id, name, role, organisation, ...).
  Future<void> saveUserInfo(String userInfoJson) =>
      _storage.write(key: _userInfoKey, value: userInfoJson);

  Future<String?> readUserInfo() => _storage.read(key: _userInfoKey);

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userInfoKey);
  }
}
