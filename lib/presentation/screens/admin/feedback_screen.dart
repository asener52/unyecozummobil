import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/api_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _summary;
  List<dynamic> _feedbacks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      dynamic summaryData;
      dynamic feedbackData;
      try {
        final r = await _api.get(ApiConstants.feedbackSummary);
        summaryData = r.data;
      } catch (_) {}
      try {
        final r = await _api.get(ApiConstants.feedback);
        feedbackData = r.data;
      } catch (_) {}
      setState(() {
        _summary = summaryData is Map<String, dynamic> ? summaryData : null;
        _feedbacks = feedbackData is List ? feedbackData : (feedbackData?['data'] ?? feedbackData?['feedbacks'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = ApiService.parseError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geri Bildirim'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_summary != null) _buildSummary(),
                      const SizedBox(height: 16),
                      if (_feedbacks.isNotEmpty) ...[
                        const Text('Son Geri Bildirimler',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._feedbacks.map(_buildFeedbackCard),
                      ] else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('Geri bildirim verisi bulunamadı'),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Tekrar Dene')),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final avg = _summary?['average'] ?? _summary?['avg'];
    final total = _summary?['total'] ?? _summary?['count'];
    final positive = _summary?['positive'];
    final negative = _summary?['negative'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('Genel Memnuniyet',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            avg != null ? avg.toStringAsFixed(1) : '-',
            style: const TextStyle(
                color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
          ),
          const Text('/ 5', style: TextStyle(color: Colors.white60, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _summaryPill('Toplam', total?.toString() ?? '-', Colors.white),
              _summaryPill('Olumlu', positive?.toString() ?? '-', Colors.greenAccent),
              _summaryPill('Olumsuz', negative?.toString() ?? '-', Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildFeedbackCard(dynamic fb) {
    final rating = fb['rating'] ?? fb['score'];
    final message = fb['message'] ?? fb['comment'] ?? fb['text'] ?? '';
    final source = fb['source'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (rating != null)
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < (rating as num).round()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  ),
                const Spacer(),
                if (source.toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(source.toString(),
                        style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen)),
                  ),
              ],
            ),
            if (message.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(message.toString()),
            ],
          ],
        ),
      ),
    );
  }
}
