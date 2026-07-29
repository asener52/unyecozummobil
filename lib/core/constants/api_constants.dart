class ApiConstants {
  // Backend URL
  static const String baseUrl = 'https://cozum.unye.bel.tr/api';

  // Auth
  static const String login = '/auth/login';
  static const String loginWithOtp = '/auth/login-with-otp';
  static const String requestOtp = '/auth/request-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';
  static const String logout = '/auth/logout';

  // Anketler
  static const String surveys = '/surveys';
  static const String surveysStats = '/surveys/stats';

  // SLA
  static const String slaAlerts = '/sla/alerts';

  // Bildirim kuralları
  static const String notificationRules = '/notification-rules';
  static const String notificationTemplates = '/templates';

  // Public (vatandaş)
  static const String publicForms = '/forms/public';
  static const String publicTopics = '/topics/public';
  static const String submitRequest = '/requests';
  static const String trackRequest = '/requests/track';

  // Admin - Talepler
  static const String requests = '/requests';
  static const String requestStatus = '/requests/{id}/status';
  static const String requestAssign = '/requests/{id}/assign';
  static const String requestNote = '/requests/{id}/note';

  // Dashboard
  static const String dashboard = '/dashboard';
  static const String reports = '/reports';

  // Kullanıcılar
  static const String users = '/users';
  static const String units = '/units';

  // Bildirimler
  static const String notifications = '/notifications';

  // Görevler
  static const String myTasks = '/requests?assignedToMe=true';

  // SLA
  static const String slaMetrics = '/sla/metrics';
  static const String slaRules = '/sla';

  // Geri bildirim
  static const String feedbackSummary = '/feedback/summary';
  static const String feedback = '/feedback';

  // Konular (Topics)
  static const String topics = '/topics';

  // Vatandaşlar
  static const String citizens = '/citizens';

  // Delegasyonlar
  static const String delegations = '/delegations';

  // Dış mesajlar (WhatsApp/Email)
  static const String externalMessages = '/external';

  // Denetim kaydı
  static const String audit = '/audit';

  // Formlar
  static const String forms = '/forms';

  // PBX
  static const String pbxCallAndConnect = '/pbx/call-and-connect';

  // Roller
  static const String roles = '/roles';

  // Bilgi tabanı
  static const String knowledgeBase = '/knowledge-base';

  // Timeout süreleri
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 30000;
}
