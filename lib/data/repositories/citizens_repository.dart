import '../models/citizen.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class CitizensRepository {
  final _api = ApiService();

  Future<List<Citizen>> getCitizens({
    int page = 1,
    int limit = 30,
    String? search,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final response =
        await _api.get(ApiConstants.citizens, queryParameters: params);
    final data = response.data;
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['citizens'] is List) {
      list = data['citizens'] as List;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else {
      list = [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(Citizen.fromJson)
        .toList();
  }
}
