import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Token ve hassas veri saklama — yalnızca FlutterSecureStorage (Android Keystore / iOS Keychain).
/// SharedPreferences'a plaintext fallback YOKTUR.
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _userKey = 'auth_user_secure';

  /// Token kaydeder. SecureStorage başarısız olursa hata fırlatır — fallback yok.
  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  /// Token okur. SecureStorage başarısız olursa null döner (giriş ekranına yönlendir).
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: AppConstants.tokenKey);
    } catch (e) {
      if (kDebugMode) debugPrint('[SecureStorage] token okunamadı: $e');
      return null;
    }
  }

  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: AppConstants.tokenKey);
    } catch (_) {}
  }

  /// Kullanıcı bilgisini güvenli depoya yazar.
  static Future<void> saveUser(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  /// Kullanıcı bilgisini güvenli depodan okur.
  static Future<String?> getUser() async {
    try {
      return await _storage.read(key: _userKey);
    } catch (_) {
      return null;
    }
  }

  /// Tüm hassas verileri temizler (logout).
  /// SharedPreferences'taki UI tercihleri (biyometrik vb.) korunur.
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}

class LocalStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  static Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  /// Tüm SharedPreferences içeriğini temizler.
  static Future<void> clear() async {
    await _prefs?.clear();
  }

  // ── Biyometrik ayarı (hassas değil, sadece UI tercihi) ──────────────────
  static const _biometricKey = 'biometric_enabled';

  static bool isBiometricEnabled() =>
      _prefs?.getBool(_biometricKey) ?? false;

  static Future<void> setBiometricEnabled(bool value) async =>
      _prefs?.setBool(_biometricKey, value);
}
