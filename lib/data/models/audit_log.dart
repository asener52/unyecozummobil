class AuditLog {
  final String id;
  final String action;
  final String entityType;
  final String? entityId;
  final String? userId;
  final String? userName;
  final Map<String, dynamic>? changes;
  final String createdAt;

  const AuditLog({
    required this.id,
    required this.action,
    required this.entityType,
    this.entityId,
    this.userId,
    this.userName,
    this.changes,
    required this.createdAt,
  });

  String get actionLabel {
    switch (action) {
      case 'create':
        return 'Oluşturuldu';
      case 'update':
        return 'Güncellendi';
      case 'delete':
        return 'Silindi';
      case 'login':
        return 'Giriş Yapıldı';
      case 'logout':
        return 'Çıkış Yapıldı';
      case 'status_change':
        return 'Durum Değiştirildi';
      case 'assign':
        return 'Atandı';
      default:
        return action;
    }
  }

  String get entityLabel {
    switch (entityType) {
      case 'request':
        return 'Talep';
      case 'user':
        return 'Kullanıcı';
      case 'unit':
        return 'Birim';
      case 'form':
        return 'Form';
      case 'role':
        return 'Rol';
      default:
        return entityType;
    }
  }

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id']?.toString() ?? '',
      action: json['action'] as String? ?? '',
      entityType: json['entity_type'] as String? ?? '',
      entityId: json['entity_id']?.toString(),
      userId: json['user_id']?.toString(),
      userName: json['user_name'] as String? ??
          json['user']?['name'] as String?,
      changes: json['changes'] is Map
          ? Map<String, dynamic>.from(json['changes'] as Map)
          : null,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
