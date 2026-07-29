import '../models/staff_user.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class UsersRepository {
  final _api = ApiService();

  Future<List<StaffUser>> getUsers({
    int page = 1,
    int limit = 30,
    String? search,
    bool? isActive,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (isActive != null) 'is_active': isActive,
    };
    final response = await _api.get(ApiConstants.users, queryParameters: params);
    final data = response.data;
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['users'] is List) {
      list = data['users'] as List;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else {
      list = [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(StaffUser.fromJson)
        .toList();
  }

  Future<StaffUser> getUser(String id) async {
    final response = await _api.get('${ApiConstants.users}/$id');
    final data = response.data as Map<String, dynamic>;
    return StaffUser.fromJson(data['user'] as Map<String, dynamic>? ?? data);
  }

  Future<StaffUser> createUser(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConstants.users, data: data);
    final res = response.data as Map<String, dynamic>;
    return StaffUser.fromJson(res['user'] as Map<String, dynamic>? ?? res);
  }

  Future<StaffUser> updateUser(String id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiConstants.users}/$id', data: data);
    final res = response.data as Map<String, dynamic>;
    return StaffUser.fromJson(res['user'] as Map<String, dynamic>? ?? res);
  }

  Future<void> toggleUserActive(String id, bool isActive) async {
    await _api.put('${ApiConstants.users}/$id', data: {'is_active': isActive});
  }

  Future<void> resetPassword(String id, String newPassword) async {
    await _api.post('${ApiConstants.users}/$id/reset-password',
        data: {'new_password': newPassword});
  }
}
