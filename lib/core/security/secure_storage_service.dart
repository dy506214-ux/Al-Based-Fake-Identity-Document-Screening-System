import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageProvider = Provider((ref) => SecureStorageService());

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';

  static const _themeKey = 'app_theme_mode';

  static const _userKey = 'auth_user';
  static const _rememberMeKey = 'remember_me';
  static const _savedEmailKey = 'saved_email';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _tokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveUser(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  Future<String?> getUser() async {
    return await _storage.read(key: _userKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }

  Future<void> saveRememberMe({required bool rememberMe, String? email}) async {
    await _storage.write(key: _rememberMeKey, value: rememberMe ? 'true' : 'false');
    if (rememberMe && email != null && email.isNotEmpty) {
      await _storage.write(key: _savedEmailKey, value: email);
    } else {
      await _storage.delete(key: _savedEmailKey);
    }
  }

  Future<bool> getRememberMe() async {
    final val = await _storage.read(key: _rememberMeKey);
    return val != 'false';
  }

  Future<String?> getSavedEmail() async {
    return await _storage.read(key: _savedEmailKey);
  }

  Future<void> saveTheme(String themeName) async {
    await _storage.write(key: _themeKey, value: themeName);
  }

  Future<String?> getTheme() async {
    return await _storage.read(key: _themeKey);
  }
}
