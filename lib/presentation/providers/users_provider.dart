import 'package:flutter/foundation.dart';
import '../../data/models/staff_user.dart';
import '../../data/repositories/users_repository.dart';
import '../../data/services/api_service.dart';

class UsersProvider extends ChangeNotifier {
  final _repo = UsersRepository();

  List<StaffUser> _users = [];
  bool _loading = false;
  String? _error;
  String? _searchQuery;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  List<StaffUser> get users => _users;
  bool get loading => _loading;
  String? get error => _error;
  bool get loadingMore => _loadingMore;

  Future<void> fetchUsers({String? search}) async {
    _searchQuery = search;
    _page = 1;
    _hasMore = true;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.getUsers(page: 1, search: search);
      _users = result;
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
          await _repo.getUsers(page: _page, search: _searchQuery);
      _users.addAll(result);
      _hasMore = result.length >= 30;
    } catch (_) {
      _page--;
    }
    _loadingMore = false;
    notifyListeners();
  }

  Future<bool> toggleActive(String id, bool isActive) async {
    try {
      await _repo.toggleUserActive(id, isActive);
      final idx = _users.indexWhere((u) => u.id == id);
      if (idx >= 0) {
        final u = _users[idx];
        _users[idx] = StaffUser(
          id: u.id,
          email: u.email,
          firstName: u.firstName,
          lastName: u.lastName,
          phone: u.phone,
          roleName: u.roleName,
          roleDisplayName: u.roleDisplayName,
          unitId: u.unitId,
          unitName: u.unitName,
          isActive: isActive,
          isLdap: u.isLdap,
          createdAt: u.createdAt,
        );
      }
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
