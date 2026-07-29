import 'package:flutter/foundation.dart';
import '../../data/models/unit.dart';
import '../../data/repositories/units_repository.dart';
import '../../data/services/api_service.dart';

class UnitsProvider extends ChangeNotifier {
  final _repo = UnitsRepository();

  List<Unit> _units = [];
  bool _loading = false;
  String? _error;

  List<Unit> get units => _units;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchUnits() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _units = await _repo.getUnits();
    } catch (e) {
      _error = ApiService.parseError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> createUnit(Map<String, dynamic> data) async {
    try {
      final unit = await _repo.createUnit(data);
      _units.insert(0, unit);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiService.parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUnit(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _repo.updateUnit(id, data);
      final idx = _units.indexWhere((u) => u.id == id);
      if (idx >= 0) _units[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiService.parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUnit(String id) async {
    try {
      await _repo.deleteUnit(id);
      _units.removeWhere((u) => u.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiService.parseError(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
