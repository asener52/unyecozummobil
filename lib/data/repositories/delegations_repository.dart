import '../models/delegation.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class DelegationsRepository {
  final _api = ApiService();

  Future<List<Delegation>> getDelegations() async {
    final response = await _api.get(ApiConstants.delegations);
    final data = response.data;
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['delegations'] is List) {
      list = data['delegations'] as List;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else {
      list = [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(Delegation.fromJson)
        .toList();
  }

  Future<Delegation> createDelegation(Map<String, dynamic> data) async {
    final response =
        await _api.post(ApiConstants.delegations, data: data);
    final res = response.data as Map<String, dynamic>;
    return Delegation.fromJson(
        res['delegation'] as Map<String, dynamic>? ?? res);
  }

  Future<void> deleteDelegation(String id) async {
    await _api.delete('${ApiConstants.delegations}/$id');
  }
}
