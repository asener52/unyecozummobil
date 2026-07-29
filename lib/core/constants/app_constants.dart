class AppConstants {
  static const String appName = 'Ünye Çözüm Merkezi';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';
  static const String baseUrlKey = 'base_url';

  // İş akışı: pending → in_progress → resolved → approved
  static const Map<String, String> requestStatuses = {
    'pending':     'Beklemede',
    'in_progress': 'İşleme Alındı',
    'resolved':    'Onay Bekliyor',
    'approved':    'Onaylandı',
    'returned':    'İade Edildi',
    'rejected':    'Reddedildi',
    'cancelled':   'İptal',
  };

  static const Map<String, String> statusColors = {
    'pending':     '#faad14',
    'in_progress': '#fa8c16',
    'resolved':    '#13c2c2',
    'approved':    '#52c41a',
    'returned':    '#722ed1',
    'rejected':    '#ff4d4f',
    'cancelled':   '#8c8c8c',
  };

  // Priorities
  static const Map<String, String> priorities = {
    'low': 'Düşük',
    'medium': 'Orta',
    'high': 'Yüksek',
    'urgent': 'Acil',
  };

  // Pagination
  static const int pageSize = 20;
}
