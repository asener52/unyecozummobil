import '../models/unit.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class UnitsRepository {
  final _api = ApiService();

  Future<List<Unit>> getUnits() async {
    final response = await _api.get(ApiConstants.units);
    final data = response.data;
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['units'] is List) {
      list = data['units'] as List;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else {
      list = [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(Unit.fromJson)
        .toList();
  }

  Future<Unit> createUnit(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConstants.units, data: data);
    final res = response.data as Map<String, dynamic>;
    return Unit.fromJson(res['unit'] as Map<String, dynamic>? ?? res);
  }

  Future<Unit> updateUnit(String id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiConstants.units}/$id', data: data);
    final res = response.data as Map<String, dynamic>;
    return Unit.fromJson(res['unit'] as Map<String, dynamic>? ?? res);
  }

  Future<void> deleteUnit(String id) async {
    await _api.delete('${ApiConstants.units}/$id');
  }
}
