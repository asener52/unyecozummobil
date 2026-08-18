import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_service.dart';
import '../../data/services/biometric_service.dart';
import '../../core/utils/jwt_utils.dart';
import '../../core/utils/storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

enum BiometricPromptState { none, prompted, success, failed }

class AuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();
  bool _disposed = false;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;
  bool _loading = false;
  bool _biometricValidating = false;

  String? _pendingOtpToken;
  String? _pendingPhoneMasked;

  bool _biometricAvailable = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get loading => _loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnabled => LocalStorage.isBiometricEnabled();
  /// Biyometrik giriş sonrası sunucu doğrulaması hâlâ devam ediyor mu?
  bool get biometricValidating => _biometricValidating;

  String? get pendingOtpToken => _pendingOtpToken;
  String? get pendingPhoneMasked => _pendingPhoneMasked;

  // ── Başlangıç kontrolü ────────────────────────────────────────────────────

  /// Uygulama başladığında çağrılır; aynı zamanda sunucu tarafından
  /// oturum sonlandırıldığında (başka cihaz girişi vb.) otomatik çıkış için
  /// ApiService callback'ini register eder.
  void _registerSessionExpiredCallback() {
    ApiService.onSessionExpired = () {
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    };
  }

  Future<void> checkAuth() async {
    _registerSessionExpiredCallback();
    _biometricAvailable = await BiometricService.isAvailable();

    final token = await SecureStorage.getToken();

    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    if (JwtUtils.isExpired(token)) {
      await SecureStorage.clearAll();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // Önbellekten kullanıcıyı yükle (async — SecureStorage)
    _user = await _repo.getCachedUser();

    if (_user != null) {
      // Kullanıcı önbellekte var → anında authenticated göster,
      // arka planda sunucu doğrulaması yap
      _status = AuthStatus.authenticated;
      notifyListeners();
      _validateTokenInBackground(token);
    } else {
      // Önbellekte kullanıcı yok ama token geçerli →
      // sunucudan çek, sonuç gelene kadar unknown (splash) ekranında bekle
      try {
        _user = await _repo.getMe();
        _status = AuthStatus.authenticated;
      } catch (e) {
        final isAuthError = e is DioException &&
            (e.response?.statusCode == 401 || e.response?.statusCode == 403);
        if (isAuthError) {
          await SecureStorage.clearAll();
          _status = AuthStatus.unauthenticated;
        } else {
          // Ağ hatası → token geçerli kabul et, authenticated yap
          _status = AuthStatus.authenticated;
        }
      }
      notifyListeners();
    }
  }

  void _validateTokenInBackground(String token) {
    _repo.getMe().timeout(const Duration(seconds: 10)).then((user) {
      if (_disposed) return;
      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
    }).catchError((e) {
      if (_disposed) return;
      final isAuthError = e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403);
      if (isAuthError) {
        SecureStorage.clearAll();
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
      }
      // Ağ/timeout hatası → oturumu koru
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ── Telefon OTP Girişi ────────────────────────────────────────────────────

  /// E-posta + şifre ile giriş başlat → telefona SMS OTP gönder.
  /// Test hesabı için backend bypass_otp:true + token döndürür, OTP adımı atlanır.
  Future<bool> loginWithEmailRequestOtp(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _repo.loginWithEmailAndRequestOtp(email, password);

      // Backend OTP olmadan doğrudan token döndürdü (test/mağaza inceleme hesabı)
      if (data['bypass_otp'] == true || data['token'] != null) {
        final userJson = data['user'] as Map<String, dynamic>?;
        _user = userJson != null ? User.fromJson(userJson) : null;
        _pendingOtpToken = null;
        _pendingPhoneMasked = null;
        _status = AuthStatus.authenticated;
        _loading = false;
        notifyListeners();
        return true;
      }

      _pendingOtpToken = data['otp_token'] as String?;
      _pendingPhoneMasked = data['phone_masked'] as String?;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiService.parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestOtp(String phone) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _repo.requestOtp(phone);

      // Backend OTP olmadan doğrudan token döndürdü (test hesabına bağlı telefon)
      if (data['bypass_otp'] == true || data['token'] != null) {
        final userJson = data['user'] as Map<String, dynamic>?;
        _user = userJson != null ? User.fromJson(userJson) : null;
        _pendingOtpToken = null;
        _pendingPhoneMasked = null;
        _status = AuthStatus.authenticated;
        _loading = false;
        notifyListeners();
        return true;
      }

      _pendingOtpToken = data['otp_token'] as String?;
      _pendingPhoneMasked = data['phone_masked'] as String?;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiService.parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String code, {bool rememberMe = true}) async {
    if (_pendingOtpToken == null) {
      _error = 'Geçerli bir OTP isteği bulunamadı';
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _repo.verifyOtp(_pendingOtpToken!, code, rememberMe: rememberMe);
      final userJson = data['user'] as Map<String, dynamic>?;
      if (userJson != null) _user = User.fromJson(userJson);
      _pendingOtpToken = null;
      _pendingPhoneMasked = null;
      _status = AuthStatus.authenticated;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiService.parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void clearOtpState() {
    _pendingOtpToken = null;
    _pendingPhoneMasked = null;
    _error = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password, {bool rememberMe = true}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _repo.login(email, password, rememberMe: rememberMe);
      final userJson = data['user'] as Map<String, dynamic>?;
      if (userJson != null) _user = User.fromJson(userJson);
      _status = AuthStatus.authenticated;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiService.parseError(e);
      _status = AuthStatus.unauthenticated;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Biyometrik ────────────────────────────────────────────────────────────

  /// Parmak izi ile giriş.
  /// Token doğrulanana kadar _biometricValidating=true — kritik işlemler bu süre bloklanabilir.
  Future<bool> loginWithBiometric() async {
    if (!_biometricAvailable) return false;

    final success = await BiometricService.authenticate(
      reason: 'Ünye Çözüm Merkezi\'ne giriş için kimliğinizi doğrulayın',
    );
    if (!success) return false;

    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) return false;
    if (JwtUtils.isExpired(token)) {
      await SecureStorage.clearAll();
      return false;
    }

    // Önce önbellekten yükle, UI'yı açık tut
    _user = await _repo.getCachedUser();
    _status = AuthStatus.authenticated;
    _biometricValidating = true;
    notifyListeners();

    // Sunucu doğrulaması tamamlanana kadar validating bayrağı açık
    try {
      final freshUser = await _repo.getMe();
      _user = freshUser;
      _biometricValidating = false;
      notifyListeners();
    } catch (e) {
      _biometricValidating = false;
      final isAuthError = e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403);
      if (isAuthError) {
        await SecureStorage.clearAll();
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
        return false;
      }
      // Ağ hatası → oturumu koru, validating kapat
      notifyListeners();
    }

    return true;
  }

  /// Login ekranı açıldığında çağrılır; cihaz biyometrik durumunu tazeler.
  Future<void> refreshBiometricAvailability() async {
    final available = await BiometricService.isAvailable();
    if (available != _biometricAvailable) {
      _biometricAvailable = available;
      notifyListeners();
    }
  }

  Future<void> enableBiometric() async {
    await LocalStorage.setBiometricEnabled(true);
    notifyListeners();
  }

  Future<void> disableBiometric() async {
    await LocalStorage.setBiometricEnabled(false);
    notifyListeners();
  }

  // ── Şifre değiştir ───────────────────────────────────────────────────────

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiService.parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
