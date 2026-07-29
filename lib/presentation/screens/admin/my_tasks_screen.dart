import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/request_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/drawer_leading_button.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  static String? _getMahalle(Map<String, dynamic>? formData) {
    if (formData == null) return null;
    for (final key in ['mahalle', 'mahalle_adi', 'mahalle_adı', 'neighborhood']) {
      final val = formData[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // assignedToMe=true zaten provider constructor'da set edildi (defaultAssignedToMe: true)
      context.read<RequestProvider>().fetchRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RequestProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Görevlerim'),
        leading: const DrawerLeadingButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => prov.fetchRequests(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Hızlı filtre sekmeleri
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                _QuickTab(
                  label: 'Tümü',
                  selected: prov.statusFilter == null,
                  onTap: () => prov.setFilter(status: null as String?),
                ),
                const SizedBox(width: 8),
                _QuickTab(
                  label: 'Bekleyenler',
                  selected: prov.statusFilter == 'pending',
                  onTap: () => prov.setFilter(status: 'pending'),
                ),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => prov.fetchRequests(),
                    child: prov.requests.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.55,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        prov.statusFilter != null
                                            ? Icons.filter_list_off
                                            : Icons.task_alt_rounded,
                                        size: 56,
                                        color: AppTheme.textHint,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        prov.statusFilter != null
                                            ? 'Filtreyle eşleşen görev yok'
                                            : 'Size atanmış talep bulunmuyor',
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary),
                                      ),
                                      if (prov.statusFilter != null) ...[
                                        const SizedBox(height: 12),
                                        TextButton(
                                          onPressed: () => prov.setFilter(
                                              status: null as String?),
                                          child: const Text('Tümünü Göster'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: prov.requests.length,
                            itemBuilder: (context, index) {
                              final req = prov.requests[index];
                              final mahalle = _getMahalle(req.formData);
                              return Card(
                                child: InkWell(
                                  onTap: () =>
                                      context.push('/panel/talep/${req.id}'),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Talep No + Durum
                                        Row(
                                          children: [
                                            const Icon(
                                                Icons.confirmation_number_outlined,
                                                size: 13,
                                                color: AppTheme.textHint),
                                            const SizedBox(width: 4),
                                            Text(
                                              req.trackingNumber,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textHint,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            const Spacer(),
                                            StatusBadge(status: req.status),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // Konu
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Konu: ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textHint,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                req.subject,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (mahalle != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on_outlined,
                                                  size: 13,
                                                  color: AppTheme.textHint),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  mahalle,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppTheme.textSecondary),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          AppDateUtils.timeAgo(req.createdAt),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textHint),
                                        ),
                                        if (req.slaBreached == true)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.errorColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                '⚠ SLA ihlali',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.errorColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuickTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
