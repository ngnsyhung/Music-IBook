import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _roleKey = 'role';
  static const _nameKey = 'full_name';

  Future<void> saveAuth({
    required String token,
    required String role,
    required String fullName,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _nameKey, value: fullName);
  }

  Future<String?> get token => _storage.read(key: _tokenKey);
  Future<String?> get role => _storage.read(key: _roleKey);
  Future<String?> get fullName => _storage.read(key: _nameKey);

  Future<void> clear() async => _storage.deleteAll();
}
