import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/api_service.dart';
import '../../../core/utils/app_date_utils.dart';

class SurveysScreen extends StatefulWidget {
  const SurveysScreen({super.key});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _surveys = [];
  Map<String, dynamic>? _stats;

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
      final res = await Future.wait([
        _api.get(ApiConstants.surveys),
        _api.get(ApiConstants.surveysStats),
      ]);
      final surveysData = res[0].data;
      final statsData = res[1].data;
      setState(() {
        _surveys = (surveysData is List)
            ? surveysData
            : (surveysData['surveys'] ?? surveysData['data'] ?? []);
        _stats = statsData is Map<String, dynamic> ? statsData : null;
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
        title: const Text('Memnuniyet Anketleri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    slivers: [
                      if (_stats != null)
                        SliverToBoxAdapter(child: _buildStats()),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _buildSurveyCard(_surveys[i]),
                          childCount: _surveys.length,
                        ),
                      ),
                      if (_surveys.isEmpty)
                        const SliverFillRemaining(
                          child: Center(
                            child: Text('Henüz anket verisi yok'),
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

  Widget _buildStats() {
    final avg = _stats?['average_rating'] ?? _stats?['avg_rating'];
    final total = _stats?['total'] ?? _stats?['count'];
    final positive = _stats?['positive'] ?? _stats?['positive_count'];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _statBox('Ortalama', avg != null ? avg.toStringAsFixed(1) : '-', Icons.star_rounded, Colors.amber),
          _statBox('Toplam', total?.toString() ?? '-', Icons.poll_rounded, AppTheme.primaryGreen),
          _statBox('Olumlu', positive?.toString() ?? '-', Icons.thumb_up_rounded, AppTheme.successColor),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSurveyCard(dynamic survey) {
    final rating = survey['rating'] ?? survey['score'];
    final comment = survey['comment'] ?? survey['feedback'] ?? '';
    final date = survey['created_at'] ?? survey['sent_at'];
    final trackingNo = survey['tracking_no'] ?? survey['request_tracking_no'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (rating != null)
                  Row(
                    children: List.generate(5, (i) => Icon(
                      i < (rating as num).round() ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 18,
                    )),
                  ),
                const Spacer(),
                if (date != null)
                  Text(
                    AppDateUtils.formatDate(date.toString()),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                  ),
              ],
            ),
            if (comment.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(comment.toString(), style: const TextStyle(fontSize: 14)),
            ],
            if (trackingNo.toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Talep: $trackingNo',
                style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
