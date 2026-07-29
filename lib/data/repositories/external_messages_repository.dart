import '../models/external_message.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class ExternalMessagesRepository {
  final _api = ApiService();

  Future<List<ExternalMessage>> getMessages({
    int page = 1,
    int limit = 30,
    String? source,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (source != null) 'source': source,
      if (status != null) 'status': status,
    };
    final response =
        await _api.get(ApiConstants.externalMessages, queryParameters: params);
    final data = response.data;
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['messages'] is List) {
      list = data['messages'] as List;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else {
      list = [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(ExternalMessage.fromJson)
        .toList();
  }

  Future<void> convertToRequest(String messageId, Map<String, dynamic> data) async {
    await _api.post(
        '${ApiConstants.externalMessages}/$messageId/convert', data: data);
  }

  Future<void> markAsRead(String messageId) async {
    await _api.put('${ApiConstants.externalMessages}/$messageId/read');
  }
}
