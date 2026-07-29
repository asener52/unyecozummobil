import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/dashboard_stats.dart';
import '../../../data/services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _period = '30d';

  // Detaylı rapor verileri
  final _api = ApiService();
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _byUnit = [];
  List<Map<String, dynamic>> _byUser = [];
  List<Map<String, dynamic>> _overdueList = [];
  bool _loadingDetail = false;
  String? _detailError;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchStats(period: _period);
      _fetchDetailedReports();
    });
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String get _startDate {
    final now = DateTime.now();
    int days;
    switch (_period) {
      case '7d': days = 7; break;
      case '90d': days = 90; break;
      case '365d': days = 365; break;
      default: days = 30;
    }
    return now.subtract(Duration(days: days)).toIso8601String().substring(0, 10);
  }

  String get _endDate => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> _fetchDetailedReports() async {
    setState(() { _loadingDetail = true; _detailError = null; });
    try {
      final params = {'start_date': _startDate, 'end_date': _endDate};
      final results = await Future.wait([
        _api.get('/reports/summary', params: params),
        _api.get('/reports/by-unit', params: params),
        _api.get('/reports/by-user', params: params),
        _api.get('/reports/overdue'),
      ]);
      setState(() {
        _summary = results[0].data as Map<String, dynamic>?;
        _byUnit = List<Map<String, dynamic>>.from(results[1].data as List? ?? []);
        _byUser = List<Map<String, dynamic>>.from(results[2].data as List? ?? []);
        _overdueList = List<Map<String, dynamic>>.from(results[3].data as List? ?? []);
        _loadingDetail = false;
      });
    } catch (e) {
      setState(() { _detailError = ApiService.parseError(e); _loadingDetail = false; });
    }
  }

  void _changePeriod(String p) {
    setState(() => _period = p);
    context.read<DashboardProvider>().fetchStats(period: p);
    _fetchDetailedReports();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar & Analitik'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today_rounded),
            onSelected: _changePeriod,
            itemBuilder: (_) => [
              const PopupMenuItem(value: '7d', child: Text('Son 7 Gün')),
              const PopupMenuItem(value: '30d', child: Text('Son 30 Gün')),
              const PopupMenuItem(value: '90d', child: Text('Son 90 Gün')),
              const PopupMenuItem(value: '365d', child: Text('Son 1 Yıl')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              prov.fetchStats(period: _period);
              _fetchDetailedReports();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Genel Bakış'),
            Tab(text: 'Birim'),
            Tab(text: 'Personel'),
            Tab(text: 'Süresi Geçen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // TAB 1 — Genel Bakış
          prov.loading
              ? const Center(child: CircularProgressIndicator())
              : prov.error != null
                  ? _ErrorView(message: prov.error!, onRetry: () => prov.fetchStats(period: _period))
                  : prov.stats == null
                      ? const _EmptyState()
                      : _OverviewTab(stats: prov.stats!, summary: _summary, period: _period),

          // TAB 2 — Birim Performansı
          _DetailTab(
            loading: _loadingDetail,
            error: _detailError,
            onRetry: _fetchDetailedReports,
            child: _ByUnitTab(byUnit: _byUnit),
          ),

          // TAB 3 — Personel Performansı
          _DetailTab(
            loading: _loadingDetail,
            error: _detailError,
            onRetry: _fetchDetailedReports,
            child: _ByUserTab(byUser: _byUser),
          ),

          // TAB 4 — Süresi Geçen
          _DetailTab(
            loading: _loadingDetail,
            error: _detailError,
            onRetry: _fetchDetailedReports,
            child: _OverdueTab(overdueList: _overdueList),
          ),
        ],
      ),
    );
  }
}

// ── TAB 1: Genel Bakış ────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final DashboardStats stats;
  final Map<String, dynamic>? summary;
  final String period;
  const _OverviewTab({required this.stats, required this.summary, required this.period});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _periodHeader(period),
        const SizedBox(height: 16),
        _KpiGrid(stats: stats, summary: summary),
        const SizedBox(height: 20),
        _ResolutionGauge(rate: stats.resolutionRate),
        const SizedBox(height: 20),
        if (summary != null) ...[
          _SummaryCard(summary: summary!),
          const SizedBox(height: 20),
        ],
        if (stats.dailyStats.isNotEmpty) ...[
          _DailyTrendChart(stats: stats),
          const SizedBox(height: 20),
        ],
        if (stats.topicStats.isNotEmpty) ...[
          _TopicDistribution(stats: stats),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _periodHeader(String p) {
    final labels = {'7d': 'Son 7 Günlük Rapor', '30d': 'Son 30 Günlük Rapor',
                    '90d': 'Son 90 Günlük Rapor', '365d': 'Yıllık Rapor'};
    return Row(
      children: [
        const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryGreen, size: 20),
        const SizedBox(width: 8),
        Text(labels[p] ?? 'Rapor',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final avgDays = (summary['avg_resolution_days'] as num?)?.toStringAsFixed(1) ?? '-';
    final overdue = summary['overdue_count'] ?? 0;
    final todayCount = summary['today_count'] ?? 0;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Özet İstatistikler',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          _StatRow(label: 'Ortalama Çözüm Süresi', value: '$avgDays gün'),
          _StatRow(label: 'Bugün Gelen', value: '$todayCount talep'),
          _StatRow(label: 'Süresi Geçen', value: '$overdue talep',
              valueColor: overdue > 0 ? AppTheme.errorColor : null),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _StatRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

// ── TAB 2: Birim ─────────────────────────────────────────────────────────────

class _ByUnitTab extends StatelessWidget {
  final List<Map<String, dynamic>> byUnit;
  const _ByUnitTab({required this.byUnit});

  @override
  Widget build(BuildContext context) {
    if (byUnit.isEmpty) return const _EmptyState();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: byUnit.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final u = byUnit[i];
        final total = (u['total'] as num?)?.toInt() ?? 0;
        final resolved = (u['resolved'] as num?)?.toInt() ?? 0;
        final rate = total > 0 ? (resolved / total * 100).round() : 0;
        final Color barColor = rate >= 80 ? AppTheme.successColor
            : rate >= 50 ? AppTheme.warningColor : AppTheme.errorColor;

        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(u['unit_name'] as String? ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  Text('$rate%', style: TextStyle(fontWeight: FontWeight.bold, color: barColor)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: rate / 100,
                backgroundColor: AppTheme.backgroundGray,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Chip(label: 'Toplam', value: total.toString(), color: AppTheme.infoColor),
                  const SizedBox(width: 8),
                  _Chip(label: 'Çözülen', value: resolved.toString(), color: AppTheme.successColor),
                  const SizedBox(width: 8),
                  _Chip(label: 'Bekleyen',
                      value: ((u['pending'] as num?)?.toInt() ?? 0).toString(),
                      color: AppTheme.warningColor),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── TAB 3: Personel ──────────────────────────────────────────────────────────

class _ByUserTab extends StatelessWidget {
  final List<Map<String, dynamic>> byUser;
  const _ByUserTab({required this.byUser});

  @override
  Widget build(BuildContext context) {
    if (byUser.isEmpty) return const _EmptyState();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: byUser.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final u = byUser[i];
        final name = u['user_name'] as String? ?? '-';
        final resolved = (u['resolved'] as num?)?.toInt() ?? 0;
        final statusChanges = (u['status_changes'] as num?)?.toInt() ?? 0;
        final notes = (u['notes'] as num?)?.toInt() ?? 0;

        return _Card(
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(u['unit_name'] as String? ?? '',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Chip(label: 'Çözüm', value: resolved.toString(), color: AppTheme.successColor),
                  const SizedBox(height: 4),
                  Text('$statusChanges işlem · $notes not',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── TAB 4: Süresi Geçen ──────────────────────────────────────────────────────

class _OverdueTab extends StatelessWidget {
  final List<Map<String, dynamic>> overdueList;
  const _OverdueTab({required this.overdueList});

  @override
  Widget build(BuildContext context) {
    if (overdueList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 56, color: AppTheme.successColor),
            SizedBox(height: 12),
            Text('Süresi geçen talep yok!',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: overdueList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = overdueList[i];
        final daysOpen = r['days_open'] as int? ?? 0;
        return _Card(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$daysOpen gün',
                    style: const TextStyle(fontSize: 12,
                        color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['subject'] as String? ?? r['tracking_number'] as String? ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (r['citizen_name'] != null) r['citizen_name'] as String,
                        if (r['unit_name'] != null) r['unit_name'] as String,
                      ].join(' · '),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Paylaşılan widget'lar ─────────────────────────────────────────────────────

class _DetailTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final Widget child;
  const _DetailTab({required this.loading, required this.error,
      required this.onRetry, required this.child});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return _ErrorView(message: error!, onRetry: onRetry);
    return child;
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Chip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$label: $value',
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final DashboardStats stats;
  final Map<String, dynamic>? summary;
  const _KpiGrid({required this.stats, required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _KpiCard(label: 'Toplam Talep', value: stats.total.toString(),
            icon: Icons.inbox_rounded, color: AppTheme.infoColor),
        _KpiCard(label: 'Çözülen', value: stats.resolved.toString(),
            icon: Icons.check_circle_rounded, color: AppTheme.successColor),
        _KpiCard(label: 'Reddedilen', value: stats.rejected.toString(),
            icon: Icons.cancel_rounded, color: AppTheme.errorColor),
        _KpiCard(label: 'Süresi Geçen',
            value: (summary?['overdue_count'] ?? stats.overdueCount).toString(),
            icon: Icons.warning_rounded, color: AppTheme.warningColor),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, color: color, size: 16),
          ),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _ResolutionGauge extends StatelessWidget {
  final double rate;
  const _ResolutionGauge({required this.rate});

  @override
  Widget build(BuildContext context) {
    final pct = (rate / 100).clamp(0.0, 1.0);
    final Color c = rate >= 80 ? AppTheme.successColor
        : rate >= 50 ? AppTheme.warningColor : AppTheme.errorColor;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Çözüm Oranı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(value: pct, backgroundColor: AppTheme.backgroundGray,
                    valueColor: AlwaysStoppedAnimation<Color>(c), minHeight: 16,
                    borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(width: 12),
              Text('${rate.round()}%',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c)),
            ],
          ),
          const SizedBox(height: 8),
          Text(rate >= 80 ? 'Mükemmel performans'
              : rate >= 50 ? 'Geliştirilmesi gerekiyor' : 'Kritik seviye',
              style: TextStyle(fontSize: 12, color: c)),
        ],
      ),
    );
  }
}

class _DailyTrendChart extends StatelessWidget {
  final DashboardStats stats;
  const _DailyTrendChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final data = stats.dailyStats.take(14).toList().reversed.toList();
    final spots = data.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.count.toDouble())).toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Günlük Talep Trendi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primaryGreen,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true,
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1)),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    interval: (data.length / 4).ceilToDouble(),
                    getTitlesWidget: (v, m) {
                      final i = v.toInt();
                      if (i < 0 || i >= data.length) return const SizedBox.shrink();
                      final parts = data[i].date.split('-');
                      return Text(parts.length >= 3 ? '${parts[2]}/${parts[1]}' : '',
                          style: const TextStyle(fontSize: 9, color: AppTheme.textHint));
                    },
                  )),
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 28,
                    getTitlesWidget: (v, m) => Text(v.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
                  )),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: AppTheme.dividerColor, strokeWidth: 1)),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicDistribution extends StatelessWidget {
  final DashboardStats stats;
  const _TopicDistribution({required this.stats});

  @override
  Widget build(BuildContext context) {
    final top = stats.topicStats.take(6).toList();
    final total = top.fold<int>(0, (s, t) => s + t.count);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Konu Dağılımı',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...top.map((t) {
            final pct = total > 0 ? (t.count / total * 100).round() : 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(flex: 5,
                      child: Text(t.topicName, style: const TextStyle(fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Expanded(flex: 4,
                      child: LinearProgressIndicator(
                        value: pct / 100, backgroundColor: AppTheme.backgroundGray,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                        minHeight: 6, borderRadius: BorderRadius.circular(4),
                      )),
                  const SizedBox(width: 8),
                  SizedBox(width: 36,
                      child: Text('$pct%',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          textAlign: TextAlign.right)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 56, color: AppTheme.textHint),
          SizedBox(height: 12),
          Text('Veri bulunamadı',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
          ],
        ),
      ),
    );
  }
}
