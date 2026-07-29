import 'package:dio/dio.dart';
import '../models/request.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';

class RequestRepository {
  final _api = ApiService();

  Future<Map<String, dynamic>> getRequests({
    int page = 1,
    int? limit,
    String? status,
    String? search,
    String? unitId,
    bool? assignedToMe,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit ?? AppConstants.pageSize,
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (unitId != null) params['unit_id'] = unitId;
    if (assignedToMe == true) params['my_only'] = true;

    final response = await _api.get(ApiConstants.requests, params: params);
    final data = response.data as Map<String, dynamic>;
    final rows = (data['requests'] ?? data['data'] ?? data['rows']) as List<dynamic>? ?? [];

    return {
      'requests': rows
          .map((e) => RequestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      'total': (data['total'] as num?)?.toInt() ?? rows.length,
      'page': page,
    };
  }

  Future<RequestModel> getRequest(String id) async {
    final response = await _api.get('${ApiConstants.requests}/$id');
    return RequestModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RequestModel> trackRequest(String trackingNumber) async {
    final response = await _api.get('${ApiConstants.trackRequest}/$trackingNumber');
    return RequestModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Returns the tracking number from the backend response
  Future<String> createRequest({
    required Map<String, dynamic> data,
  }) async {
    final response = await _api.post(ApiConstants.requests, data: data);
    final body = response.data;
    if (body is Map) {
      return body['tracking_number']?.toString() ?? '';
    }
    return '';
  }

  /// Returns the tracking number from the backend response
  Future<String> createRequestMultipart(FormData formData) async {
    final response = await _api.postMultipart(
      ApiConstants.requests,
      formData: formData,
    );
    final body = response.data;
    if (body is Map) {
      return body['tracking_number']?.toString() ?? '';
    }
    return '';
  }

  Future<void> updateStatus({
    required String requestId,
    required String status,
    String? note,
  }) async {
    await _api.patch(
      '${ApiConstants.requests}/$requestId/status',
      data: {
        'status': status,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }

  Future<void> assignRequest({
    required String requestId,
    String? unitId,
    String? userId,
  }) async {
    await _api.patch(
      '${ApiConstants.requests}/$requestId/assign',
      data: {
        if (unitId != null) 'unit_id': unitId,
        if (userId != null) 'user_id': userId,
      },
    );
  }

  Future<void> addNote({
    required String requestId,
    required String note,
    bool isInternal = true,
  }) async {
    await _api.post(
      '${ApiConstants.requests}/$requestId/note',
      data: {
        'note': note,
        'is_internal': isInternal,
      },
    );
  }

  /// Talebi okundu olarak işaretler (web ile senkronize edilir).
  Future<void> markAsRead(String requestId) async {
    try {
      await _api.patch('${ApiConstants.requests}/$requestId/mark-read');
    } catch (_) {}
  }

  /// Mevcut talebe dosya ekler. [filePaths] yerel dosya yolları listesi.
  Future<List<Map<String, dynamic>>> uploadAttachments({
    required String requestId,
    required List<String> filePaths,
  }) async {
    final formData = FormData.fromMap({
      'files': await Future.wait(
        filePaths.map((p) => MultipartFile.fromFile(p)),
      ),
    });
    final response = await _api.postMultipart(
      '${ApiConstants.requests}/$requestId/attachments',
      formData: formData,
    );
    final data = response.data;
    if (data is Map && data['uploaded'] is List) {
      return List<Map<String, dynamic>>.from(data['uploaded'] as List);
    }
    return [];
  }
}
