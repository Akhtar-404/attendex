import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _s = FlutterSecureStorage();

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kRole = 'role';

  static Future<void> save({
    required String access,
    required String refresh,
    required String role,
  }) async {
    await _s.write(key: _kAccess, value: access);
    await _s.write(key: _kRefresh, value: refresh);
    await _s.write(key: _kRole, value: role);
  }

  static Future<String?> readAccess() => _s.read(key: _kAccess);
  static Future<String?> readRefresh() => _s.read(key: _kRefresh);
  static Future<String?> readRole() => _s.read(key: _kRole);

  static Future<void> clear() async {
    await _s.delete(key: _kAccess);
    await _s.delete(key: _kRefresh);
    await _s.delete(key: _kRole);
  }
}
