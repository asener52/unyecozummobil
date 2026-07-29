import 'dart:convert';
import '../models/user.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/storage.dart';

class AuthRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> login(String email, String password,
      {bool rememberMe = true}) async {
    final response = await _api.post(
      ApiConstants.login,
      data: {'email': email, 'password': password, 'rememberMe': rememberMe},
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String?;
    final userJson = data['user'] as Map<String, dynamic>?;

    if (token != null) await SecureStorage.saveToken(token);
    // Kullanıcı verisi SecureStorage'a (şifreli)
    if (userJson != null) await SecureStorage.saveUser(jsonEncode(userJson));

    return data;
  }

  /// E-posta + şifre doğrula → kayıtlı telefona SMS OTP gönder.
  Future<Map<String, dynamic>> loginWithEmailAndRequestOtp(
      String email, String password) async {
    final response = await _api.post(
      ApiConstants.loginWithOtp,
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Telefon numarasına OTP gönder.
  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final response = await _api.post(
      ApiConstants.requestOtp,
      data: {'phone': phone},
    );
    return response.data as Map<String, dynamic>;
  }

  /// OTP kodu doğrula ve JWT al.
  Future<Map<String, dynamic>> verifyOtp(String otpToken, String code,
      {bool rememberMe = true}) async {
    final response = await _api.post(
      ApiConstants.verifyOtp,
      data: {'otp_token': otpToken, 'code': code, 'rememberMe': rememberMe},
    );
    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String?;
    final userJson = data['user'] as Map<String, dynamic>?;

    if (token != null) await SecureStorage.saveToken(token);
    if (userJson != null) await SecureStorage.saveUser(jsonEncode(userJson));
    return data;
  }

  Future<User> getMe() async {
    final response = await _api.get(ApiConstants.me);
    final data = response.data as Map<String, dynamic>;
    final userJson = data.containsKey('user')
        ? data['user'] as Map<String, dynamic>
        : data;
    // Güncel kullanıcı bilgisini güvenli depoya kaydet
    await SecureStorage.saveUser(jsonEncode(userJson));
    return User.fromJson(userJson);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post(
      ApiConstants.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  /// Sunucu Redis oturumunu kapat, ardından yerel depoyu temizle.
  Future<void> logout() async {
    try {
      await _api.post(ApiConstants.logout);
    } catch (_) {
      // Ağ hatası olsa bile yerel temizlik yapılır
    }
    await SecureStorage.clearAll();
  }

  /// Güvenli depodan önbelleğe alınmış kullanıcıyı okur.
  Future<User?> getCachedUser() async {
    final userJson = await SecureStorage.getUser();
    if (userJson == null) return null;
    try {
      return User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
