import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/api_service.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../data/models/request.dart';
import '../../../data/repositories/request_repository.dart';
import '../../widgets/common/status_badge.dart';

class CitizenTrackScreen extends StatefulWidget {
  final String? initialTracking;

  const CitizenTrackScreen({super.key, this.initialTracking});

  @override
  State<CitizenTrackScreen> createState() => _CitizenTrackScreenState();
}

class _CitizenTrackScreenState extends State<CitizenTrackScreen> {
  final _trackingCtrl = TextEditingController();
  final _repo = RequestRepository();
  RequestModel? _result;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialTracking != null) {
      _trackingCtrl.text = widget.initialTracking!;
      _search();
    }
  }

  @override
  void dispose() {
    _trackingCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final tracking = _trackingCtrl.text.trim();
    if (tracking.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _repo.trackRequest(tracking);
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Bu takip numarasına ait talep bulunamadı.\n'
            '(${ApiService.parseError(e)})';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talep Sorgula'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Arama kutusu
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Talep Takip Numarası',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Talebinizi oluştururken aldığınız numarayı girin',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _trackingCtrl,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _search(),
                            decoration: const InputDecoration(
                              hintText: 'Örn: UNY-2024-001234',
                              prefixIcon:
                                  Icon(Icons.confirmation_number_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _loading ? null : _search,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(56, 52),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.search),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Hata mesajı
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.errorColor),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppTheme.errorColor))),
                  ],
                ),
              ),

            // Sonuç kartı
            if (_result != null) _TrackResultCard(request: _result!),
          ],
        ),
      ),
    );
  }
}

class _TrackResultCard extends StatelessWidget {
  final RequestModel request;

  const _TrackResultCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Genel bilgiler
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.subject,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StatusBadge(status: request.status),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.confirmation_number_outlined,
                    'Takip No', request.trackingNumber),
                const SizedBox(height: 8),
                if (request.unitName != null)
                  _infoRow(Icons.business_outlined,
                      'Birim', request.unitName!),
                if (request.unitName != null) const SizedBox(height: 8),
                _infoRow(Icons.access_time_outlined, 'Başvuru Tarihi',
                    AppDateUtils.formatDateTime(request.createdAt)),
                if (request.resolvedAt != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(Icons.check_circle_outline, 'Çözüm Tarihi',
                      AppDateUtils.formatDateTime(request.resolvedAt)),
                ],
                const Divider(height: 24),
                // Kopyala
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: request.trackingNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Takip numarası kopyalandı')),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy, size: 16,
                          color: AppTheme.primaryGreen),
                      const SizedBox(width: 6),
                      Text(
                        request.trackingNumber,
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Zaman çizelgesi
        if (request.actions.isNotEmpty) ...[
          const Text(
            'İşlem Geçmişi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: request.actions
                    .map((action) => _TimelineItem(action: action))
                    .toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textHint),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final RequestAction action;

  const _TimelineItem({required this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 32,
                color: AppTheme.dividerColor,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppDateUtils.formatDateTime(action.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textHint),
                ),
                const SizedBox(height: 2),
                Text(
                  _actionLabel(action.actionType),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (action.note != null && action.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      action.note!,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _actionLabel(String type) {
    const labels = {
      'status_change': 'Durum Güncellendi',
      'assignment': 'Görevlendirme',
      'note': 'Not Eklendi',
      'created': 'Talep Oluşturuldu',
      'resolved': 'Çözüme Kavuşturuldu',
      'closed': 'Kapatıldı',
    };
    return labels[type] ?? type;
  }
}
