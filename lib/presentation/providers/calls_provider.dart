import 'package:flutter/foundation.dart';
import '../../data/services/api_service.dart';

class CallModel {
  final String id;
  final String? callerNumber;
  final String? calleeNumber;
  final String callDirection; // 'inbound' | 'outbound'
  final String callStatus;    // 'answered' | 'no_answer' | 'busy'
  final int? durationSeconds;
  final String? startedAt;
  final String? answeredByName;
  final String? linkedRequest;
  final String? notes;

  const CallModel({
    required this.id,
    this.callerNumber,
    this.calleeNumber,
    this.callDirection = 'inbound',
    this.callStatus = 'answered',
    this.durationSeconds,
    this.startedAt,
    this.answeredByName,
    this.linkedRequest,
    this.notes,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id']?.toString() ?? '',
      callerNumber: json['caller_number'] as String?,
      calleeNumber: json['callee_number'] as String?,
      callDirection: json['call_direction'] as String? ?? 'inbound',
      callStatus: json['call_status'] as String? ?? 'answered',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      startedAt: json['started_at'] as String?,
      answeredByName: json['answered_by_name'] as String?,
      linkedRequest: json['linked_request'] as String?,
      notes: json['notes'] as String?,
    );
  }

  String get displayNumber {
    if (callDirection == 'inbound') return callerNumber ?? '-';
    return calleeNumber ?? '-';
  }

  String get directionLabel =>
      callDirection == 'inbound' ? 'Gelen' : 'Giden';

  String get statusLabel {
    switch (callStatus) {
      case 'answered':
        return 'Cevaplandı';
      case 'no_answer':
        return 'Cevapsız';
      case 'busy':
        return 'Meşgul';
      default:
        return callStatus;
    }
  }

  String get durationLabel {
    if (durationSeconds == null || durationSeconds == 0) return '-';
    final m = durationSeconds! ~/ 60;
    final s = durationSeconds! % 60;
    return m > 0 ? '${m}d ${s}s' : '${s}s';
  }
}

class CallsProvider extends ChangeNotifier {
  final _api = ApiService();

  List<CallModel> _calls = [];
  int _total = 0;
  int _page = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  String _search = '';

  List<CallModel> get calls => _calls;
  int get total => _total;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  bool get hasMore => _calls.length < _total;

  Future<void> fetchCalls({bool reset = true}) async {
    if (reset) {
      _page = 1;
      _loading = true;
      _error = null;
      notifyListeners();
    } else {
      if (_loadingMore) return;
      _loadingMore = true;
      notifyListeners();
    }

    try {
      final params = <String, dynamic>{
        'page': _page,
        'limit': 30,
        if (_search.isNotEmpty) 'search': _search,
      };
      final resp = await _api.get('/calls', params: params);
      final data = resp.data as Map<String, dynamic>;
      final rawList = (data['data'] ?? data['calls'] ?? data['rows'] ?? []) as List<dynamic>;
      final rows = rawList
          .map((e) => CallModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (reset) {
        _calls = rows;
      } else {
        _calls = [..._calls, ...rows];
      }
      _total = (data['total'] as num?)?.toInt() ?? rows.length;
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
    await fetchCalls(reset: false);
  }

  void setSearch(String value) {
    _search = value;
    fetchCalls();
  }
}
