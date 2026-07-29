import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../data/models/dashboard_stats.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/drawer_leading_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final dashProv = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Yönetim Paneli'),
        leading: const DrawerLeadingButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => dashProv.fetchStats(),
          ),
        ],
      ),
      body: dashProv.loading
          ? const Center(child: CircularProgressIndicator())
          : dashProv.error != null
              ? _ErrorView(
                  message: dashProv.error!,
                  onRetry: () => dashProv.fetchStats(),
                )
              : RefreshIndicator(
                  onRefresh: () => dashProv.fetchStats(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Hoşgeldin
                      if (user != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Merhaba, ${user.displayName.split(' ').first} 👋',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      // Özet kartlar
                      if (dashProv.stats != null)
                        _SummaryGrid(stats: dashProv.stats!),

                      const SizedBox(height: 20),

                      // Durum dağılımı
                      if (dashProv.stats != null)
                        _StatusPieChart(stats: dashProv.stats!),

                      const SizedBox(height: 20),

                      // Son 7 gün grafiği
                      if (dashProv.stats != null &&
                          dashProv.stats!.dailyStats.isNotEmpty)
                        _DailyBarChart(stats: dashProv.stats!),

                      const SizedBox(height: 20),

                      // Birim istatistikleri
                      if (dashProv.stats != null &&
                          dashProv.stats!.unitStats.isNotEmpty)
                        _UnitStatsList(stats: dashProv.stats!),

                      // Son talepler
                      if (dashProv.stats != null &&
                          dashProv.stats!.recentRequests.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _RecentRequestsList(stats: dashProv.stats!),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final DashboardStats stats;

  const _SummaryGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          label: 'Toplam Talep',
          value: stats.total,
          icon: Icons.inbox_rounded,
          color: AppTheme.infoColor,
        ),
        _StatCard(
          label: 'Yeni',
          value: stats.newCount,
          icon: Icons.fiber_new_rounded,
          color: AppTheme.primaryGreen,
        ),
        _StatCard(
          label: 'İşlemde',
          value: stats.inProgress,
          icon: Icons.pending_rounded,
          color: AppTheme.warningColor,
        ),
        _StatCard(
          label: 'Çözüldü',
          value: stats.resolved,
          icon: Icons.check_circle_rounded,
          color: AppTheme.successColor,
        ),
        _StatCard(
          label: 'Süresi Geçen',
          value: stats.overdueCount,
          icon: Icons.warning_rounded,
          color: AppTheme.errorColor,
        ),
        _StatCard(
          label: 'Çözüm Oranı',
          value: stats.resolutionRate.round(),
          icon: Icons.analytics_rounded,
          color: AppTheme.primaryGreenLight,
          suffix: '%',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String suffix;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
          Text(
            '$value$suffix',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPieChart extends StatelessWidget {
  final DashboardStats stats;

  const _StatusPieChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[];
    void addSection(double val, Color color, String title) {
      if (val <= 0) return;
      sections.add(PieChartSectionData(
        value: val,
        color: color,
        title: val.round().toString(),
        radius: 50,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }

    addSection(stats.newCount.toDouble(), AppTheme.infoColor, 'Yeni');
    addSection(
        stats.inProgress.toDouble(), AppTheme.warningColor, 'İşlemde');
    addSection(stats.pending.toDouble(), const Color(0xFFfaad14), 'Bekliyor');
    addSection(stats.resolved.toDouble(), AppTheme.successColor, 'Çözüldü');
    addSection(stats.closed.toDouble(), AppTheme.textHint, 'Kapalı');
    addSection(stats.rejected.toDouble(), AppTheme.errorColor, 'Reddedildi');

    if (sections.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Durum Dağılımı',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 32,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legend('Yeni', AppTheme.infoColor),
                    _legend('İşlemde', AppTheme.warningColor),
                    _legend('Bekliyor', const Color(0xFFfaad14)),
                    _legend('Çözüldü', AppTheme.successColor),
                    _legend('Kapalı', AppTheme.textHint),
                    _legend('Reddedildi', AppTheme.errorColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _DailyBarChart extends StatelessWidget {
  final DashboardStats stats;

  const _DailyBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final data = stats.dailyStats.take(7).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Günlük Talep Trendi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                barGroups: data.asMap().entries.map((entry) {
                  final i = entry.key;
                  final d = entry.value;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: d.count.toDouble(),
                        color: AppTheme.primaryGreen,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final date = data[i].date;
                        final parts = date.split('-');
                        return Text(
                          parts.length >= 3
                              ? '${parts[2]}/${parts[1]}'
                              : date,
                          style: const TextStyle(
                              fontSize: 9, color: AppTheme.textHint),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, meta) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textHint),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitStatsList extends StatelessWidget {
  final DashboardStats stats;

  const _UnitStatsList({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Birim Bazlı İstatistikler',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ...stats.unitStats.take(5).map((u) => _UnitRow(unit: u)),
        ],
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  final UnitStat unit;

  const _UnitRow({required this.unit});

  @override
  Widget build(BuildContext context) {
    final rate = unit.total > 0
        ? (unit.resolved / unit.total * 100).round()
        : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  unit.unitName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${unit.total} talep',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: rate / 100,
            backgroundColor: AppTheme.backgroundGray,
            valueColor: AlwaysStoppedAnimation<Color>(
              rate >= 80
                  ? AppTheme.successColor
                  : rate >= 50
                      ? AppTheme.warningColor
                      : AppTheme.errorColor,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 2),
          Text(
            '$rate% çözüm oranı',
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }
}

class _RecentRequestsList extends StatelessWidget {
  final DashboardStats stats;

  const _RecentRequestsList({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Son Talepler',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...stats.recentRequests.map((r) {
            final id = r['id']?.toString() ?? '';
            final tracking = r['tracking_number']?.toString() ?? '';
            final name = r['citizen_name']?.toString() ?? '';
            final status = r['status']?.toString() ?? '';
            final formName = r['form_name']?.toString() ?? '';
            final createdAt = r['created_at']?.toString() ?? '';
            return InkWell(
              onTap: () => context.push('/panel/talep/$id'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formName.isNotEmpty ? formName : tracking,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                tracking,
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.textHint),
                              ),
                              if (name.isNotEmpty) ...[
                                const Text(' · ',
                                    style:
                                        TextStyle(color: AppTheme.textHint)),
                                Text(
                                  name,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textHint),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusBadge(status: status),
                        const SizedBox(height: 4),
                        Text(
                          AppDateUtils.timeAgo(createdAt),
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
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
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
          ],
        ),
      ),
    );
  }
}
