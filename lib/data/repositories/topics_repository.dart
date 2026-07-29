import '../models/topic.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class TopicsRepository {
  final _api = ApiService();

  Future<List<Topic>> getTopics() async {
    final response = await _api.get(ApiConstants.topics);
    final data = response.data;
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['topics'] is List) {
      list = data['topics'] as List;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else {
      list = [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(Topic.fromJson)
        .toList();
  }

  Future<Topic> createTopic(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConstants.topics, data: data);
    final res = response.data as Map<String, dynamic>;
    return Topic.fromJson(res['topic'] as Map<String, dynamic>? ?? res);
  }

  Future<Topic> updateTopic(String id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiConstants.topics}/$id', data: data);
    final res = response.data as Map<String, dynamic>;
    return Topic.fromJson(res['topic'] as Map<String, dynamic>? ?? res);
  }

  Future<void> deleteTopic(String id) async {
    await _api.delete('${ApiConstants.topics}/$id');
  }
}
