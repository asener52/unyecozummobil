import 'package:flutter/foundation.dart';
import '../../data/models/citizen.dart';
import '../../data/repositories/citizens_repository.dart';
import '../../data/services/api_service.dart';

class CitizensProvider extends ChangeNotifier {
  final _repo = CitizensRepository();

  List<Citizen> _citizens = [];
  bool _loading = false;
  String? _error;
  String? _searchQuery;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  List<Citizen> get citizens => _citizens;
  bool get loading => _loading;
  String? get error => _error;
  bool get loadingMore => _loadingMore;

  Future<void> fetchCitizens({String? search}) async {
    _searchQuery = search;
    _page = 1;
    _hasMore = true;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.getCitizens(page: 1, search: search);
      _citizens = result;
      _hasMore = result.length >= 30;
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
      final result =
          await _repo.getCitizens(page: _page, search: _searchQuery);
      _citizens.addAll(result);
      _hasMore = result.length >= 30;
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
