import '../models/dashboard_stats.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class DashboardRepository {
  final _api = ApiService();

  Future<DashboardStats> getDashboardStats({
    String? period,
    int? unitId,
  }) async {
    final params = <String, dynamic>{};
    if (period != null) params['period'] = period;
    if (unitId != null) params['unit_id'] = unitId;

    final response = await _api.get(ApiConstants.dashboard, params: params);
    return DashboardStats.fromJson(response.data as Map<String, dynamic>);
  }
}
