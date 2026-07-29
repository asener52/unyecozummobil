class DashboardStats {
  final int total;
  final int newCount;
  final int inProgress;
  final int resolved;
  final int closed;
  final int rejected;
  final int pending;
  final double resolutionRate;
  final double avgResolutionHours;
  final int overdueCount;
  final List<UnitStat> unitStats;
  final List<DailyStat> dailyStats;
  final List<TopicStat> topicStats;
  final List<Map<String, dynamic>> recentRequests;

  const DashboardStats({
    this.total = 0,
    this.newCount = 0,
    this.inProgress = 0,
    this.resolved = 0,
    this.closed = 0,
    this.rejected = 0,
    this.pending = 0,
    this.resolutionRate = 0,
    this.avgResolutionHours = 0,
    this.overdueCount = 0,
    this.unitStats = const [],
    this.dailyStats = const [],
    this.topicStats = const [],
    this.recentRequests = const [],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    // Backend: { summary:{pending,in_progress,resolved,rejected,returned,total}, recentRequests:[...] }
    final summary = json['summary'] as Map<String, dynamic>? ?? json;
    final tot = _toInt(summary['total']);
    final res = _toInt(summary['resolved']);
    return DashboardStats(
      total: tot,
      newCount: _toInt(summary['pending']),
      inProgress: _toInt(summary['in_progress']),
      resolved: res,
      closed: _toInt(summary['returned']),
      rejected: _toInt(summary['rejected']),
      pending: 0,
      resolutionRate: tot > 0 ? (res / tot * 100) : 0.0,
      avgResolutionHours: 0,
      overdueCount: 0,
      unitStats: const [],
      dailyStats: const [],
      topicStats: const [],
      recentRequests: (json['recentRequests'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

class UnitStat {
  final String unitName;
  final int total;
  final int resolved;
  final int pending;

  const UnitStat({
    required this.unitName,
    required this.total,
    required this.resolved,
    required this.pending,
  });

  factory UnitStat.fromJson(Map<String, dynamic> json) {
    return UnitStat(
      unitName: json['unit_name'] as String? ?? '',
      total: DashboardStats._toInt(json['total']),
      resolved: DashboardStats._toInt(json['resolved']),
      pending: DashboardStats._toInt(json['pending']),
    );
  }
}

class DailyStat {
  final String date;
  final int count;
  final int resolved;

  const DailyStat({
    required this.date,
    required this.count,
    required this.resolved,
  });

  factory DailyStat.fromJson(Map<String, dynamic> json) {
    return DailyStat(
      date: json['date'] as String? ?? '',
      count: DashboardStats._toInt(json['count']),
      resolved: DashboardStats._toInt(json['resolved']),
    );
  }
}

class TopicStat {
  final String topicName;
  final int count;

  const TopicStat({
    required this.topicName,
    required this.count,
  });

  factory TopicStat.fromJson(Map<String, dynamic> json) {
    return TopicStat(
      topicName: json['topic_name'] as String? ?? '',
      count: DashboardStats._toInt(json['count']),
    );
  }
}
