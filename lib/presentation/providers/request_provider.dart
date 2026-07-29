import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/request.dart';
import '../../data/repositories/request_repository.dart';
import '../../data/services/api_service.dart';
import '../../core/utils/storage.dart';

class RequestProvider extends ChangeNotifier {
  final _repo = RequestRepository();
  final String storagePrefix;

  RequestProvider({
    this.storagePrefix = 'req',
    bool defaultAssignedToMe = false,
  }) {
    _assignedToMe = defaultAssignedToMe;
    _loadPersistedFilters();
  }

  List<RequestModel> _requests = [];
  RequestModel? _selectedRequest;
  int _total = 0;
  int _page = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  String? _statusFilter;
  String? _searchQuery;
  bool _assignedToMe = false;

  Timer? _pollTimer;
  int _lastKnownTotal = -1;
  int _newRequestCount = 0;

  List<RequestModel> get requests => _requests;
  RequestModel? get selectedRequest => _selectedRequest;
  int get total => _total;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  String? get statusFilter => _statusFilter;
  String? get searchQuery => _searchQuery;
  bool get assignedToMe => _assignedToMe;
  bool get hasMore => _requests.length < _total;
  int get newRequestCount => _newRequestCount;

  void _loadPersistedFilters() {
    final v = LocalStorage.getString('${storagePrefix}_sf');
    if (v != null) {
      _statusFilter = v.isEmpty ? null : v;
    }
  }

  void _persist() {
    LocalStorage.setString('${storagePrefix}_sf', _statusFilter ?? '');
  }

  void startPolling({int intervalSeconds = 30}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      _checkForNewRequests();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void clearNewCount() {
    _newRequestCount = 0;
    notifyListeners();
  }

  Future<void> _checkForNewRequests() async {
    try {
      final result = await _repo.getRequests(page: 1);
      final latestTotal = (result['total'] as num?)?.toInt() ?? 0;
      if (_lastKnownTotal < 0) {
        _lastKnownTotal = latestTotal;
      } else if (latestTotal > _lastKnownTotal) {
        _newRequestCount += latestTotal - _lastKnownTotal;
        _lastKnownTotal = latestTotal;
        notifyListeners();
      } else {
        _lastKnownTotal = latestTotal;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchRequests({bool reset = true}) async {
    if (reset && _loading) return;
    if (!reset && (_loading || _loadingMore)) return;

    if (reset) {
      _page = 1;
      _requests = [];
    }

    _loading = reset;
    _loadingMore = !reset;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.getRequests(
        page: _page,
        status: _statusFilter,
        search: _searchQuery,
        assignedToMe: _assignedToMe ? true : null,
      );
      final newRequests = result['requests'] as List<RequestModel>;
      _total = (result['total'] as num?)?.toInt() ?? 0;
      if (_lastKnownTotal < 0) _lastKnownTotal = _total;

      if (reset) {
        _requests = newRequests;
      } else {
        _requests = [..._requests, ...newRequests];
      }
    } catch (e) {
      _error = ApiService.parseError(e);
    } finally {
      _loading = false;
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || _loadingMore) return;
    _page++;
    await fetchRequests(reset: false);
  }

  Future<void> fetchRequest(String id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedRequest = await _repo.getRequest(id);
    } catch (e) {
      _error = ApiService.parseError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<RequestModel?> trackRequest(String trackingNumber) async {
    try {
      return await _repo.trackRequest(trackingNumber);
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateStatus({
    required String requestId,
    required String status,
    String? note,
  }) async {
    try {
      await _repo.updateStatus(
        requestId: requestId,
        status: status,
        note: note,
      );
      if (_selectedRequest?.id == requestId) {
        _selectedRequest = await _repo.getRequest(requestId);
      }
      _requests = _requests.map((r) {
        if (r.id == requestId) {
          return RequestModel.fromJson({
            ...r.toJsonSimple(),
            'status': status,
          });
        }
        return r;
      }).toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> assignRequest({
    required String requestId,
    String? unitId,
    String? userId,
  }) async {
    try {
      await _repo.assignRequest(
          requestId: requestId, unitId: unitId, userId: userId);
      _selectedRequest = await _repo.getRequest(requestId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addNote({
    required String requestId,
    required String note,
  }) async {
    try {
      await _repo.addNote(requestId: requestId, note: note);
      if (_selectedRequest?.id == requestId) {
        _selectedRequest = await _repo.getRequest(requestId);
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> uploadAttachments({
    required String requestId,
    required List<String> filePaths,
  }) async {
    try {
      await _repo.uploadAttachments(requestId: requestId, filePaths: filePaths);
      if (_selectedRequest?.id == requestId) {
        _selectedRequest = await _repo.getRequest(requestId);
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static const _keep = Object();

  void setFilter({
    Object? status = _keep,
    Object? search = _keep,
    bool? assignedToMe,
  }) {
    if (!identical(status, _keep)) _statusFilter = status as String?;
    if (!identical(search, _keep)) _searchQuery = search as String?;
    if (assignedToMe != null) _assignedToMe = assignedToMe;
    _persist();
    fetchRequests();
  }

  void clearFilters() {
    _statusFilter = null;
    _searchQuery = null;
    _assignedToMe = false;
    _persist();
    fetchRequests();
  }

  void clearSelected() {
    _selectedRequest = null;
  }
}

extension _RequestModelExt on RequestModel {
  Map<String, dynamic> toJsonSimple() => {
        'id': id,
        'tracking_number': trackingNumber,
        'subject': subject,
        'status': status,
        'priority': priority,
        'citizen_name': applicantName,
        'citizen_phone': applicantPhone,
        'citizen_email': applicantEmail,
        'form_id': formId,
        'form_name': formName,
        'assigned_unit_id': unitId,
        'unit_name': unitName,
        'assigned_user_id': assignedTo,
        'assigned_user_name': assignedName,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'resolved_at': resolvedAt,
      };
}
