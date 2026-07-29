import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/delegations_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/delegation.dart';

class DelegationsScreen extends StatefulWidget {
  const DelegationsScreen({super.key});

  @override
  State<DelegationsScreen> createState() => _DelegationsScreenState();
}

class _DelegationsScreenState extends State<DelegationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DelegationsProvider>().fetchDelegations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DelegationsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yetki Delegasyonları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => prov.fetchDelegations(),
          ),
        ],
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.error != null
              ? _ErrorView(
                  message: prov.error!,
                  onRetry: () => prov.fetchDelegations(),
                )
              : RefreshIndicator(
                  onRefresh: () => prov.fetchDelegations(),
                  child: prov.delegations.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: prov.delegations.length,
                          itemBuilder: (ctx, i) => _DelegationCard(
                            delegation: prov.delegations[i],
                            onDelete: () => _confirmDelete(
                                context, prov, prov.delegations[i]),
                          ),
                        ),
                ),
    );
  }

  void _confirmDelete(
      BuildContext context, DelegationsProvider prov, Delegation d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delegasyonu İptal Et'),
        content: Text(
            '${d.toUserName} kişisine verilen yetkiyi iptal etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await prov.deleteDelegation(d.id);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(prov.error ?? 'İptal edilemedi')),
                );
              }
            },
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );
  }
}

class _DelegationCard extends StatelessWidget {
  final Delegation delegation;
  final VoidCallback onDelete;

  const _DelegationCard({required this.delegation, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final active = delegation.isCurrentlyActive;
    final fmt = DateFormat('dd.MM.yyyy');

    DateTime? startDt;
    DateTime? endDt;
    try {
      startDt = DateTime.parse(delegation.startDate);
      endDt = DateTime.parse(delegation.endDate);
    } catch (_) {}

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: active
                        ? AppTheme.successColor.withValues(alpha: 0.12)
                        : AppTheme.textHint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    active ? 'Aktif' : 'Pasif',
                    style: TextStyle(
                      fontSize: 11,
                      color: active
                          ? AppTheme.successColor
                          : AppTheme.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppTheme.errorColor),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(delegation.fromUserName,
                    style: const TextStyle(fontSize: 13)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppTheme.textHint),
                ),
                const Icon(Icons.person_rounded,
                    size: 16, color: AppTheme.primaryGreen),
                const SizedBox(width: 6),
                Text(delegation.toUserName,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.primaryGreen)),
              ],
            ),
            const SizedBox(height: 6),
            if (startDt != null && endDt != null)
              Row(
                children: [
                  const Icon(Icons.date_range_outlined,
                      size: 14, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Text(
                    '${fmt.format(startDt)} – ${fmt.format(endDt)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            if (delegation.permissions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: delegation.permissions
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.infoColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(p,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.infoColor)),
                        ))
                    .toList(),
              ),
            ],
            if (delegation.reason != null &&
                delegation.reason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                delegation.reason!,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
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
          Icon(Icons.transfer_within_a_station_outlined,
              size: 56, color: AppTheme.textHint),
          SizedBox(height: 12),
          Text('Delegasyon bulunamadı',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          SizedBox(height: 8),
          Text(
            'Yetki aktarımı web panelinden yapılabilir.',
            style: TextStyle(fontSize: 12, color: AppTheme.textHint),
            textAlign: TextAlign.center,
          ),
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
            const Icon(Icons.error_outline,
                size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: onRetry, child: const Text('Tekrar Dene')),
          ],
        ),
      ),
    );
  }
}
