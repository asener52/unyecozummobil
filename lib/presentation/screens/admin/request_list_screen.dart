import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/request_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../data/models/request.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/drawer_leading_button.dart';

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<RequestProvider>();
      // Arama kutusunu kayıtlı filtre ile senkronize et
      if (prov.searchQuery != null) {
        _searchCtrl.text = prov.searchQuery!;
      }
      prov.fetchRequests();
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<RequestProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RequestProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Talepler'),
        leading: const DrawerLeadingButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context, prov),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/panel/talep-olustur'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni Talep'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Talep ara...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          prov.setFilter(search: null as String?);
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (v) => prov.setFilter(search: v),
            ),
          ),

          // Hızlı filtre sekmeleri
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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

          // Aktif durum filtresi (modal'dan seçilmişse göster)
          if (prov.statusFilter != null && prov.statusFilter != 'pending')
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Chip(
                    label: Text(
                      AppConstants.requestStatuses[prov.statusFilter] ??
                          prov.statusFilter!,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => prov.setFilter(status: null as String?),
                    backgroundColor:
                        AppTheme.primaryGreen.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                        color: AppTheme.primaryGreen, fontSize: 12),
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
                                    MediaQuery.of(context).size.height * 0.45,
                                child: _EmptyState(
                                  hasFilter: prov.statusFilter != null ||
                                      prov.searchQuery != null,
                                  onClear: () => prov.clearFilters(),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollCtrl,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: prov.requests.length +
                                (prov.loadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == prov.requests.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return _RequestCard(
                                request: prov.requests[index],
                                onTap: () => context.push(
                                    '/panel/talep/${prov.requests[index].id}'),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, RequestProvider prov) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Duruma Göre Filtrele',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(context, prov, null, 'Tümü'),
                ...AppConstants.requestStatuses.entries.map(
                  (e) => _filterChip(context, prov, e.key, e.value),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    BuildContext context,
    RequestProvider prov,
    String? status,
    String label,
  ) {
    final isSelected = prov.statusFilter == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        prov.setFilter(status: status);
        Navigator.pop(context);
      },
      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
      checkmarkColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryGreen : AppTheme.textPrimary,
        fontSize: 13,
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

class _RequestCard extends StatelessWidget {
  final RequestModel request;
  final VoidCallback onTap;

  const _RequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !request.isRead;
    return Card(
      color: isUnread ? AppTheme.primaryGreen.withValues(alpha: 0.04) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isUnread)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 6, top: 2),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      request.subject,
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14,
                        color: isUnread ? AppTheme.textPrimary : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined,
                      size: 13, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Text(
                    request.trackingNumber,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textHint),
                  ),
                  const SizedBox(width: 12),
                  if (request.applicantName != null) ...[
                    const Icon(Icons.person_outline,
                        size: 13, color: AppTheme.textHint),
                    const SizedBox(width: 4),
                    Text(
                      request.applicantName!,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textHint),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    AppDateUtils.timeAgo(request.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textHint),
                  ),
                ],
              ),
              if (request.unitName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.business_outlined,
                        size: 13, color: AppTheme.textHint),
                    const SizedBox(width: 4),
                    Text(
                      request.unitName!,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textHint),
                    ),
                    if (request.assignedName != null) ...[
                      const Text(' · ',
                          style: TextStyle(color: AppTheme.textHint)),
                      const Icon(Icons.assignment_ind_outlined,
                          size: 13, color: AppTheme.textHint),
                      const SizedBox(width: 4),
                      Text(
                        request.assignedName!,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textHint),
                      ),
                    ],
                  ],
                ),
              ],
              if (request.slaBreached == true)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
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
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClear;

  const _EmptyState({required this.hasFilter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.filter_list_off : Icons.inbox_rounded,
            size: 56,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter ? 'Filtreyle eşleşen talep yok' : 'Henüz talep yok',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onClear, child: const Text('Filtreyi Temizle')),
          ],
        ],
      ),
    );
  }
}
