import 'package:flutter/foundation.dart';
import '../../data/models/delegation.dart';
import '../../data/repositories/delegations_repository.dart';
import '../../data/services/api_service.dart';

class DelegationsProvider extends ChangeNotifier {
  final _repo = DelegationsRepository();

  List<Delegation> _delegations = [];
  bool _loading = false;
  String? _error;

  List<Delegation> get delegations => _delegations;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchDelegations() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _delegations = await _repo.getDelegations();
    } catch (e) {
      _error = ApiService.parseError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> createDelegation(Map<String, dynamic> data) async {
    try {
      final d = await _repo.createDelegation(data);
      _delegations.insert(0, d);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiService.parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDelegation(String id) async {
    try {
      await _repo.deleteDelegation(id);
      _delegations.removeWhere((d) => d.id == id);
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
