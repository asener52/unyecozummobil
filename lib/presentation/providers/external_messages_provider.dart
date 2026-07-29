import 'package:flutter/foundation.dart';
import '../../data/models/external_message.dart';
import '../../data/repositories/external_messages_repository.dart';
import '../../data/services/api_service.dart';

class ExternalMessagesProvider extends ChangeNotifier {
  final _repo = ExternalMessagesRepository();

  List<ExternalMessage> _messages = [];
  bool _loading = false;
  String? _error;
  String? _sourceFilter;

  List<ExternalMessage> get messages => _messages;
  bool get loading => _loading;
  String? get error => _error;
  String? get sourceFilter => _sourceFilter;

  Future<void> fetchMessages({String? source}) async {
    _sourceFilter = source;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _messages = await _repo.getMessages(source: source);
    } catch (e) {
      _error = ApiService.parseError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> markAsRead(String id) async {
    try {
      await _repo.markAsRead(id);
      final idx = _messages.indexWhere((m) => m.id == id);
      if (idx >= 0) {
        final m = _messages[idx];
        _messages[idx] = ExternalMessage(
          id: m.id,
          source: m.source,
          senderName: m.senderName,
          senderContact: m.senderContact,
          content: m.content,
          status: 'read',
          linkedRequestId: m.linkedRequestId,
          linkedTrackingNumber: m.linkedTrackingNumber,
          createdAt: m.createdAt,
        );
        notifyListeners();
      }
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
