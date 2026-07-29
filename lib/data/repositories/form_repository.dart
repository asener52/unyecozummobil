import '../models/form_template.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class FormRepository {
  final _api = ApiService();

  Future<List<FormTemplate>> getPublicForms() async {
    final response = await _api.get(ApiConstants.publicForms);
    final data = response.data;
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      list = (data['forms'] ?? data['data'] ?? []) as List<dynamic>;
    } else {
      list = [];
    }
    return list
        .map((e) => FormTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FormTemplate> getPublicForm(String id) async {
    final response = await _api.get('${ApiConstants.publicForms}/$id');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      // Response: { form: {...}, fields: [...] }
      if (data.containsKey('form')) {
        final formMap = data['form'] as Map<String, dynamic>;
        final fieldsList = data['fields'] as List<dynamic>? ?? [];
        return FormTemplate.fromJson({...formMap, 'fields': fieldsList});
      }
      return FormTemplate.fromJson(data);
    }
    throw Exception('Geçersiz form verisi');
  }

  Future<List<Topic>> getPublicTopics() async {
    final response = await _api.get(ApiConstants.publicTopics);
    final data = response.data;
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      list = (data['topics'] ?? data['data'] ?? []) as List<dynamic>;
    } else {
      list = [];
    }
    return list
        .map((e) => Topic.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
