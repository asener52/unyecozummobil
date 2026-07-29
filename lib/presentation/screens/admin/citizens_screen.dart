import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/citizens_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../data/models/citizen.dart';

class CitizensScreen extends StatefulWidget {
  const CitizensScreen({super.key});

  @override
  State<CitizensScreen> createState() => _CitizensScreenState();
}

class _CitizensScreenState extends State<CitizensScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CitizensProvider>().fetchCitizens();
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
      context.read<CitizensProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CitizensProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vatandaşlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => prov.fetchCitizens(
                search: _searchCtrl.text.trim().isEmpty
                    ? null
                    : _searchCtrl.text.trim()),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'İsim, telefon veya e-posta ara...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          prov.fetchCitizens();
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (v) =>
                  prov.fetchCitizens(search: v.isEmpty ? null : v),
              textInputAction: TextInputAction.search,
            ),
          ),
          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator())
                : prov.error != null
                    ? _ErrorView(
                        message: prov.error!,
                        onRetry: () => prov.fetchCitizens(),
                      )
                    : RefreshIndicator(
                        onRefresh: () => prov.fetchCitizens(
                            search: _searchCtrl.text.trim().isEmpty
                                ? null
                                : _searchCtrl.text.trim()),
                        child: prov.citizens.isEmpty
                            ? const _EmptyState()
                            : ListView.builder(
                                controller: _scrollCtrl,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                itemCount: prov.citizens.length +
                                    (prov.loadingMore ? 1 : 0),
                                itemBuilder: (ctx, i) {
                                  if (i == prov.citizens.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  return _CitizenCard(
                                      citizen: prov.citizens[i]);
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CitizenCard extends StatelessWidget {
  final Citizen citizen;

  const _CitizenCard({required this.citizen});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
              child: Text(
                citizen.displayName.isNotEmpty
                    ? citizen.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    citizen.displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  if (citizen.phone != null)
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 12, color: AppTheme.textHint),
                        const SizedBox(width: 4),
                        Text(citizen.phone!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  if (citizen.email != null)
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 12, color: AppTheme.textHint),
                        const SizedBox(width: 4),
                        Text(citizen.email!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  if (citizen.createdAt != null)
                    Text(
                      'Kayıt: ${AppDateUtils.format(citizen.createdAt!)}',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textHint),
                    ),
                ],
              ),
            ),
            if (citizen.requestCount > 0)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${citizen.requestCount}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  const Text(
                    'talep',
                    style: TextStyle(
                        fontSize: 10, color: AppTheme.textHint),
                  ),
                ],
              ),
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
          Icon(Icons.people_alt_outlined,
              size: 56, color: AppTheme.textHint),
          SizedBox(height: 12),
          Text('Vatandaş bulunamadı',
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
