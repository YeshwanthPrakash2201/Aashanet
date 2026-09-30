import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _tokenKey = 'access_token';
  static const String _usernameKey = 'username';
  static const String _roleKey = 'role';
  static const String _fullNameKey = 'full_name';

  static Future<void> saveSession({
    required String accessToken,
    required String username,
    required String role,
    required String fullName,
  }) async {
    await _storage.write(key: _tokenKey, value: accessToken);
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _fullNameKey, value: fullName);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  static Future<String?> getFullName() async {
    return await _storage.read(key: _fullNameKey);
  }

  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}