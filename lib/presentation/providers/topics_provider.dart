import 'package:flutter/foundation.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/topics_repository.dart';
import '../../data/services/api_service.dart';

class TopicsProvider extends ChangeNotifier {
  final _repo = TopicsRepository();

  List<Topic> _topics = [];
  bool _loading = false;
  String? _error;

  List<Topic> get topics => _topics;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchTopics() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _topics = await _repo.getTopics();
    } catch (e) {
      _error = ApiService.parseError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> createTopic(Map<String, dynamic> data) async {
    try {
      final topic = await _repo.createTopic(data);
      _topics.insert(0, topic);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiService.parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTopic(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _repo.updateTopic(id, data);
      final idx = _topics.indexWhere((t) => t.id == id);
      if (idx >= 0) _topics[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiService.parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTopic(String id) async {
    try {
      await _repo.deleteTopic(id);
      _topics.removeWhere((t) => t.id == id);
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
