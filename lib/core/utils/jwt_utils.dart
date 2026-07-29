import 'dart:convert';

class JwtUtils {
  /// JWT token'ın süresi dolmuş mu?
  /// Şüphe durumunda fail-closed: hata veya exp yoksa expired sayılır.
  static bool isExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      String payload = parts[1];
      payload += '=' * ((4 - payload.length % 4) % 4);

      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;

      final exp = map['exp'] as int?;
      // exp claim yoksa → süresi dolmuş say (fail-closed)
      if (exp == null) return true;

      final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expDate);
    } catch (_) {
      // Parse hatası → fail-closed: süresi dolmuş say
      return true;
    }
  }

  /// Token geçerli (süresi dolmamış) mı?
  static bool isValid(String? token) {
    if (token == null || token.isEmpty) return false;
    return !isExpired(token);
  }
}
