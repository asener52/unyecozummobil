import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audit_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../data/models/audit_log.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuditProvider>().fetchLogs();
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<AuditProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AuditProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Denetim Kaydı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => prov.fetchLogs(),
          ),
        ],
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.error != null
              ? _ErrorView(
                  message: prov.error!,
                  onRetry: () => prov.fetchLogs(),
                )
              : RefreshIndicator(
                  onRefresh: () => prov.fetchLogs(),
                  child: prov.logs.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount:
                              prov.logs.length + (prov.loadingMore ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i == prov.logs.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _AuditCard(log: prov.logs[i]);
                          },
                        ),
                ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  final AuditLog log;

  const _AuditCard({required this.log});

  Color get _actionColor {
    switch (log.action) {
      case 'create':
        return AppTheme.successColor;
      case 'update':
      case 'status_change':
        return AppTheme.warningColor;
      case 'delete':
        return AppTheme.errorColor;
      case 'login':
        return AppTheme.primaryGreen;
      default:
        return AppTheme.infoColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _actionColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_actionIcon, color: _actionColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${log.actionLabel} · ${log.entityLabel}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        AppDateUtils.timeAgo(log.createdAt),
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textHint),
                      ),
                    ],
                  ),
                  if (log.userName != null)
                    Text(
                      log.userName!,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  if (log.entityId != null)
                    Text(
                      'ID: ${log.entityId}',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textHint),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _actionIcon {
    switch (log.action) {
      case 'create':
        return Icons.add_circle_outline_rounded;
      case 'update':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline_rounded;
      case 'login':
        return Icons.login_rounded;
      case 'logout':
        return Icons.logout_rounded;
      case 'status_change':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.history_rounded;
    }
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
          Icon(Icons.history_rounded, size: 56, color: AppTheme.textHint),
          SizedBox(height: 12),
          Text('Kayıt bulunamadı',
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
