class Delegation {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final String startDate;
  final String endDate;
  final List<String> permissions;
  final String? reason;
  final bool isActive;
  final String? createdAt;

  const Delegation({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.startDate,
    required this.endDate,
    required this.permissions,
    this.reason,
    this.isActive = true,
    this.createdAt,
  });

  bool get isCurrentlyActive {
    if (!isActive) return false;
    final now = DateTime.now();
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      return now.isAfter(start) && now.isBefore(end);
    } catch (_) {
      return false;
    }
  }

  factory Delegation.fromJson(Map<String, dynamic> json) {
    final perms = json['permissions'];
    List<String> permList = [];
    if (perms is List) {
      permList = perms.map((e) => e.toString()).toList();
    } else if (perms is String) {
      permList = [perms];
    }

    return Delegation(
      id: json['id']?.toString() ?? '',
      fromUserId: json['from_user_id']?.toString() ?? '',
      fromUserName: json['from_user_name'] as String? ??
          json['from_user']?['name'] as String? ?? '',
      toUserId: json['to_user_id']?.toString() ?? '',
      toUserName: json['to_user_name'] as String? ??
          json['to_user']?['name'] as String? ?? '',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      permissions: permList,
      reason: json['reason'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
    );
  }
}
