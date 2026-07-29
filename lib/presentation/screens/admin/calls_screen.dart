import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/calls_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../widgets/common/drawer_leading_button.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallsProvider>().fetchCalls();
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
      context.read<CallsProvider>().loadMore();
    }
  }

  Future<void> _dial(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arama başlatılamadı')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CallsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Çağrı Merkezi'),
        leading: const DrawerLeadingButton(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Numara veya personel ara...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          prov.setSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                setState(() {});
                prov.setSearch(v.trim());
              },
            ),
          ),
        ),
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.errorColor, size: 40),
                      const SizedBox(height: 8),
                      Text(prov.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => prov.fetchCalls(),
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : prov.calls.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_missed_rounded,
                              size: 64,
                              color: AppTheme.textHint.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          const Text('Çağrı kaydı bulunamadı',
                              style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => prov.fetchCalls(),
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: prov.calls.length + (prov.hasMore ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == prov.calls.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return _CallTile(
                            call: prov.calls[i],
                            onDial: _dial,
                          );
                        },
                      ),
                    ),
    );
  }
}

class _CallTile extends StatelessWidget {
  final CallModel call;
  final void Function(String) onDial;

  const _CallTile({required this.call, required this.onDial});

  Color get _statusColor {
    switch (call.callStatus) {
      case 'answered':
        return AppTheme.successColor;
      case 'no_answer':
        return AppTheme.errorColor;
      case 'busy':
        return const Color(0xFFfa8c16);
      default:
        return AppTheme.textHint;
    }
  }

  IconData get _directionIcon => call.callDirection == 'inbound'
      ? Icons.call_received_rounded
      : Icons.call_made_rounded;

  Color get _directionColor => call.callDirection == 'inbound'
      ? AppTheme.primaryGreen
      : const Color(0xFF1677ff);

  @override
  Widget build(BuildContext context) {
    final number = call.displayNumber;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: number != '-'
            ? () => onDial(number.replaceAll(' ', ''))
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Direction icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _directionColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_directionIcon,
                    color: _directionColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          number,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            call.statusLabel,
                            style: TextStyle(
                                fontSize: 10,
                                color: _statusColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.access_time_outlined,
                            size: 12, color: AppTheme.textHint),
                        const SizedBox(width: 3),
                        Text(
                          call.startedAt != null
                              ? AppDateUtils.formatDateTime(call.startedAt!)
                              : '-',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        if (call.durationSeconds != null &&
                            call.durationSeconds! > 0) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.timer_outlined,
                              size: 12, color: AppTheme.textHint),
                          const SizedBox(width: 3),
                          Text(
                            call.durationLabel,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ],
                    ),
                    if (call.answeredByName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        call.answeredByName!,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textHint),
                      ),
                    ],
                    if (call.linkedRequest != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.link_rounded,
                              size: 11, color: AppTheme.primaryGreen),
                          const SizedBox(width: 3),
                          Text(
                            call.linkedRequest!,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.primaryGreen),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Dial button
              if (number != '-')
                IconButton(
                  icon: const Icon(Icons.call_rounded,
                      color: AppTheme.primaryGreen, size: 22),
                  onPressed: () => onDial(number.replaceAll(' ', '')),
                  tooltip: 'Ara',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
