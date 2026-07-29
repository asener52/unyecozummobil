import '../models/audit_log.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class AuditRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> getAuditLogs({
    int page = 1,
    int limit = 30,
    String? entityType,
    String? userId,
    String? action,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (entityType != null) 'entity_type': entityType,
      if (userId != null) 'user_id': userId,
      if (action != null) 'action': action,
    };
    final response =
        await _api.get(ApiConstants.audit, queryParameters: params);
    final data = response.data;
    List<dynamic> list;
    int total = 0;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      list = data['logs'] as List? ?? data['data'] as List? ?? [];
      total = data['total'] as int? ?? list.length;
    } else {
      list = [];
    }
    return {
      'logs': list
          .whereType<Map<String, dynamic>>()
          .map(AuditLog.fromJson)
          .toList(),
      'total': total,
    };
  }
}
