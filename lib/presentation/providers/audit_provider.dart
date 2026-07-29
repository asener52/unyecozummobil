import 'package:flutter/foundation.dart';
import '../../data/models/audit_log.dart';
import '../../data/repositories/audit_repository.dart';
import '../../data/services/api_service.dart';

class AuditProvider extends ChangeNotifier {
  final _repo = AuditRepository();

  List<AuditLog> _logs = [];
  bool _loading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  int _total = 0;

  List<AuditLog> get logs => _logs;
  bool get loading => _loading;
  String? get error => _error;
  bool get loadingMore => _loadingMore;
  int get total => _total;

  Future<void> fetchLogs({String? entityType, String? action}) async {
    _page = 1;
    _hasMore = true;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.getAuditLogs(
          page: 1, entityType: entityType, action: action);
      _logs = result['logs'] as List<AuditLog>;
      _total = result['total'] as int;
      _hasMore = _logs.length >= 30;
    } catch (e) {
      _error = ApiService.parseError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    _page++;
    notifyListeners();
    try {
      final result = await _repo.getAuditLogs(page: _page);
      final newLogs = result['logs'] as List<AuditLog>;
      _logs.addAll(newLogs);
      _hasMore = newLogs.length >= 30;
    } catch (_) {
      _page--;
    }
    _loadingMore = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
