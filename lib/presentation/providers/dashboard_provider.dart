import 'package:flutter/foundation.dart';
import '../../data/models/dashboard_stats.dart';
import '../../data/repositories/dashboard_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final _repo = DashboardRepository();

  DashboardStats? _stats;
  bool _loading = false;
  String? _error;
  String _period = '30d';

  DashboardStats? get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;
  String get period => _period;

  Future<void> fetchStats({String? period}) async {
    if (period != null) _period = period;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _repo.getDashboardStats(period: _period);
    } catch (e) {
      _error = 'İstatistikler yüklenemedi';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
