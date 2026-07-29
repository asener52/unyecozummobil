import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/api_service.dart';

class SlaScreen extends StatefulWidget {
  const SlaScreen({super.key});

  @override
  State<SlaScreen> createState() => _SlaScreenState();
}

class _SlaScreenState extends State<SlaScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _rules = [];
  Map<String, dynamic>? _metrics;

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
      dynamic rulesData;
      dynamic metricsData;
      try {
        final r = await _api.get(ApiConstants.slaRules);
        rulesData = r.data;
      } catch (_) {}
      try {
        final r = await _api.get(ApiConstants.slaMetrics);
        metricsData = r.data;
      } catch (_) {}
      setState(() {
        _rules = rulesData is List ? rulesData : (rulesData?['rules'] ?? rulesData?['data'] ?? []);
        _metrics = metricsData is Map<String, dynamic> ? metricsData : null;
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
        title: const Text('SLA Paneli'),
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
                      if (_metrics != null) _buildMetrics(),
                      const SizedBox(height: 16),
                      const Text(
                        'SLA Kuralları',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._rules.map(_buildRuleCard),
                      if (_rules.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('SLA kuralı tanımlı değil'),
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

  Widget _buildMetrics() {
    final onTime = _metrics?['on_time'] ?? _metrics?['completed_on_time'];
    final overdue = _metrics?['overdue'] ?? _metrics?['overdue_count'];
    final rate = _metrics?['compliance_rate'] ?? _metrics?['sla_rate'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SLA Özeti',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricBox('Zamanında', onTime?.toString() ?? '-', AppTheme.successColor),
              _metricBox('Gecikmiş', overdue?.toString() ?? '-', AppTheme.errorColor),
              _metricBox(
                'Uyum Oranı',
                rate != null ? '${rate.toStringAsFixed(1)}%' : '-',
                AppTheme.primaryGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRuleCard(dynamic rule) {
    final name = rule['name'] ?? rule['title'] ?? 'Kural';
    final hours = rule['response_hours'] ?? rule['hours'] ?? rule['deadline_hours'];
    final priority = rule['priority'] ?? '';
    final isActive = rule['is_active'] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? AppTheme.primaryGreen.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          child: Icon(
            Icons.timer_rounded,
            color: isActive ? AppTheme.primaryGreen : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(name.toString()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hours != null)
              Text('Süre: $hours saat',
                  style: const TextStyle(fontSize: 12)),
            if (priority.toString().isNotEmpty)
              Text('Öncelik: $priority',
                  style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.successColor.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isActive ? 'Aktif' : 'Pasif',
            style: TextStyle(
              fontSize: 11,
              color: isActive ? AppTheme.successColor : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
