import 'dart:convert';

import '../../data/models/user.dart';
import '../utils/storage.dart';

const String directLoginEmail = 'test@unye.bel.tr';

bool isDirectLoginUser(String? email) {
  final normalized = (email ?? '').trim().toLowerCase();
  return normalized == directLoginEmail;
}

bool shouldBypassOtp(String? email) => isDirectLoginUser(email);

User buildDirectLoginUser(String email) {
  return User(
    id: 'demo-test-user',
    email: email.trim().toLowerCase(),
    firstName: 'Test',
    lastName: 'Kullanıcı',
    role: 'unit_user',
    phone: '+905551234567',
    unitId: 'demo-unit',
    unitName: 'Demo Ünite',
    permissions: const {
      'dashboard:read': true,
      'requests:read': true,
      'requests:create': true,
    },
    isActive: true,
  );
}

String createDemoJwtToken() {
  final now = DateTime.now().toUtc();
  final expiresAt = now.add(const Duration(days: 365)).millisecondsSinceEpoch ~/ 1000;

  final header = {'alg': 'none', 'typ': 'JWT'};
  final payload = {
    'sub': 'demo-test-user',
    'email': directLoginEmail,
    'role': 'unit_user',
    'exp': expiresAt,
  };

  final encodedHeader = base64Url.encode(utf8.encode(jsonEncode(header)));
  final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
  return '$encodedHeader.$encodedPayload.demo-signature';
}

Future<void> persistDirectLoginSession(String email) async {
  final user = buildDirectLoginUser(email);
  await SecureStorage.saveToken(createDemoJwtToken());
  await SecureStorage.saveUser(jsonEncode(user.toJson()));
}
