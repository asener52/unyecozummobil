import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart' as dio_pkg;
import '../../widgets/common/attachment_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/utils/storage.dart';
import '../../../data/models/request.dart';
import '../../../data/repositories/form_repository.dart';
import '../../../data/repositories/request_repository.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/common/status_badge.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  // fieldKey → görünen etiket haritası
  Map<String, String> _fieldLabels = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<RequestProvider>();
      await prov.fetchRequest(widget.requestId);
      final req = prov.selectedRequest;
      if (req == null) return;

      // Okundu olarak işaretle (web ile senkronize)
      RequestRepository().markAsRead(widget.requestId);

      if (req.formFieldLabels.isNotEmpty) {
        // API cevabında etiketler zaten mevcut
        if (mounted) setState(() => _fieldLabels = req.formFieldLabels);
      } else if (req.formId != null &&
          req.formData != null &&
          req.formData!.isNotEmpty) {
        // Form şablonunu ayrıca çek
        await _fetchFieldLabels(req.formId!);
      }
    });
  }

  Future<void> _fetchFieldLabels(String formId) async {
    try {
      final template = await FormRepository().getPublicForm(formId);
      if (!mounted) return;
      setState(() {
        _fieldLabels = {
          for (final f in template.fields) f.fieldKey: f.fieldLabel,
        };
      });
    } catch (_) {}
  }

  /// Teknik anahtarı okunabilir hale çevirir (son çare fallback)
  String _labelFor(String key) {
    if (_fieldLabels.containsKey(key)) return _fieldLabels[key]!;
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  void dispose() {
    context.read<RequestProvider>().clearSelected();
    super.dispose();
  }

  void _showStatusDialog(BuildContext context, RequestModel request) {
    String? selectedStatus = request.status;
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Durumu Güncelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(labelText: 'Durum'),
              items: AppConstants.requestStatuses.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (v) {
                selectedStatus = v;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Not (isteğe bağlı)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (selectedStatus == null) return;
              final prov = context.read<RequestProvider>();
              final ok = await prov.updateStatus(
                requestId: request.id,
                status: selectedStatus!,
                note: noteCtrl.text.trim(),
              );
              noteCtrl.dispose();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Durum güncellendi'
                      : 'Güncelleme başarısız'),
                  backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
                ),
              );
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  void _showNoteDialog(BuildContext context, RequestModel request) {
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Not Ekle'),
        content: TextField(
          controller: noteCtrl,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'İç not...',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              noteCtrl.dispose();
              Navigator.pop(context);
            },
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final note = noteCtrl.text.trim();
              Navigator.pop(context);
              noteCtrl.dispose();
              if (note.isEmpty) return;
              final ok = await context
                  .read<RequestProvider>()
                  .addNote(requestId: request.id, note: note);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Not eklendi' : 'Not eklenemedi'),
                  backgroundColor:
                      ok ? AppTheme.successColor : AppTheme.errorColor,
                ),
              );
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showAttachmentDialog(BuildContext context, RequestModel request) {
    showDialog(
      context: context,
      builder: (_) => _AttachmentUploadDialog(request: request),
    );
  }

  Future<void> _quickStatus(
    BuildContext context,
    RequestModel request,
    String newStatus,
    String label, {
    bool noteRequired = false,
    String? initialNote,
  }) async {
    final noteCtrl = TextEditingController(text: initialNote ?? '');
    String? noteError;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(label),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: noteRequired ? 'Not (zorunlu)' : 'Not (isteğe bağlı)',
                  alignLabelWithHint: true,
                  errorText: noteError,
                ),
                onChanged: (_) {
                  if (noteError != null) setDialogState(() => noteError = null);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (noteRequired && noteCtrl.text.trim().isEmpty) {
                  setDialogState(() => noteError = 'Not zorunludur');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(label),
            ),
          ],
        ),
      ),
    );
    final note = noteCtrl.text.trim();
    noteCtrl.dispose();
    if (confirmed != true || !mounted) return;

    final ok = await context.read<RequestProvider>().updateStatus(
          requestId: request.id,
          status: newStatus,
          note: note.isNotEmpty ? note : null,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '$label yapıldı' : 'İşlem başarısız'),
        backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  void _showAssignDialog(BuildContext context, RequestModel request) {
    showDialog(
      context: context,
      builder: (_) => _AssignDialog(request: request),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RequestProvider>();
    final request = prov.selectedRequest;
    final user = context.watch<AuthProvider>().user;
    final canEdit = user?.hasPermission('requests:update') ?? false;
    final canDialOut = user?.hasPermission('calls:dial_out') ?? false;
    final canResolve = user?.hasPermission('requests:resolve') ?? false;
    final canApprove = user?.hasPermission('requests:approve') ?? false;
    final canReturn = user?.hasPermission('requests:return') ?? false;
    final canAssign = user?.hasPermission('requests:assign') ?? false;
    final status = request?.status ?? '';
    // İş akışı: pending → in_progress → resolved → approved
    final isPending = status == 'pending';
    final isInProgress = status == 'in_progress';
    final isResolved = status == 'resolved';
    final isActive = isPending || isInProgress;

    return Scaffold(
      appBar: AppBar(
        title: Text(request?.trackingNumber ?? 'Talep Detayı'),
        actions: (request == null || !canEdit)
            ? null
            : [
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'status') _showStatusDialog(context, request);
                    if (v == 'note') _showNoteDialog(context, request);
                    if (v == 'attach') _showAttachmentDialog(context, request);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'status',
                        child: Text('Durumu Güncelle')),
                    PopupMenuItem(
                        value: 'note', child: Text('Not Ekle')),
                    PopupMenuItem(
                        value: 'attach', child: Text('Dosya Ekle')),
                  ],
                ),
              ],
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : request == null
              ? const Center(child: Text('Talep bulunamadı'))
              : RefreshIndicator(
                  onRefresh: () => prov.fetchRequest(widget.requestId),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Özet
                      _DetailCard(
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
                            if (request.description != null &&
                                request.description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                request.description!,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13),
                              ),
                            ],
                            const Divider(height: 20),
                            _infoRow(Icons.confirmation_number_outlined,
                                'Takip No', request.trackingNumber),
                            const SizedBox(height: 6),
                            _infoRow(Icons.access_time_outlined,
                                'Oluşturulma',
                                AppDateUtils.formatDateTime(request.createdAt)),
                            if (request.unitName != null) ...[
                              const SizedBox(height: 6),
                              _infoRow(Icons.business_outlined, 'Birim',
                                  request.unitName!),
                            ],
                            if (request.assignedName != null) ...[
                              const SizedBox(height: 6),
                              _infoRow(Icons.assignment_ind_outlined,
                                  'Atanan', request.assignedName!),
                            ],
                            if (request.priority != null) ...[
                              const SizedBox(height: 6),
                              _infoRow(Icons.flag_outlined, 'Öncelik',
                                  request.priorityLabel),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Başvuru sahibi
                      if (request.applicantName != null)
                        _DetailCard(
                          title: 'Başvuru Sahibi',
                          icon: Icons.person_outline,
                          child: Column(
                            children: [
                              if (request.applicantName != null)
                                _infoRow(Icons.person_outline, 'Ad Soyad',
                                    request.applicantName!),
                              if (request.applicantPhone != null) ...[
                                const SizedBox(height: 6),
                                _infoRow(Icons.phone_outlined, 'Telefon',
                                    request.applicantPhone!),
                              ],
                              if (request.applicantEmail != null) ...[
                                const SizedBox(height: 6),
                                _infoRow(Icons.email_outlined, 'E-posta',
                                    request.applicantEmail!),
                              ],
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Form verileri
                      if (request.formData != null &&
                          request.formData!.isNotEmpty)
                        _DetailCard(
                          title: request.formName ?? 'Form Bilgileri',
                          icon: Icons.list_alt_outlined,
                          child: Column(
                            children: request.formData!.entries
                                .map((e) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 6),
                                      child: _infoRow(
                                        Icons.arrow_right,
                                        _labelFor(e.key),
                                        e.value?.toString() ?? '-',
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Ekler
                      if (request.attachments.isNotEmpty)
                        _DetailCard(
                          title: 'Ekler',
                          icon: Icons.attach_file_rounded,
                          child: Column(
                            children: request.attachments
                                .map((a) => _AttachmentItem(attachment: a))
                                .toList(),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // İşlem geçmişi
                      if (request.actions.isNotEmpty)
                        _DetailCard(
                          title: 'İşlem Geçmişi',
                          icon: Icons.history_rounded,
                          child: Column(
                            children: request.actions
                                .map((a) => _ActionItem(action: a))
                                .toList(),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Ara-Bağla butonu — vatandaşın telefonu varsa ve yetkisi varsa göster
                      if (canDialOut && request.applicantPhone != null &&
                          request.applicantPhone!.isNotEmpty) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _callAndConnect(context, request),
                            icon: const Icon(Icons.phone_in_talk_rounded,
                                size: 18),
                            label: const Text('Ara (Santral)',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1677ff),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Hızlı aksiyon butonları — iş akışı: pending→in_progress→resolved→approved
                      if (canEdit || canResolve || canApprove || canReturn || canAssign) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // 1. İşleme Al: pending → in_progress
                            if (canEdit && isPending)
                              ElevatedButton.icon(
                                onPressed: () => _quickStatus(
                                    context, request, 'in_progress', 'İşleme Al'),
                                icon: const Icon(Icons.play_circle_outline, size: 16),
                                label: const Text('İşleme Al'),
                              ),
                            // 2. Sonuçlandır: in_progress → resolved
                            if (canResolve && isInProgress)
                              ElevatedButton.icon(
                                onPressed: () => _quickStatus(
                                    context, request, 'resolved', 'Sonuçlandır',
                                    noteRequired: true),
                                icon: const Icon(Icons.task_alt_rounded, size: 16),
                                label: const Text('Sonuçlandır'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF13c2c2)),
                              ),
                            // 3. Onayla: resolved → approved (yönetici onayı)
                            if (canApprove && isResolved)
                              ElevatedButton.icon(
                                onPressed: () => _quickStatus(
                                    context, request, 'approved', 'Onayla',
                                    initialNote: request.resolutionNote),
                                icon: const Icon(Icons.verified_outlined, size: 16),
                                label: const Text('Onayla'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.successColor),
                              ),
                            // 4. İade Et: in_progress veya resolved → returned
                            if (canReturn && (isInProgress || isResolved))
                              OutlinedButton.icon(
                                onPressed: () => _quickStatus(
                                    context, request, 'returned', 'İade Et',
                                    noteRequired: true),
                                icon: const Icon(Icons.undo_rounded, size: 16),
                                label: const Text('İade Et'),
                              ),
                            // 5. Aktar: pending veya in_progress
                            if (canAssign && isActive)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _showAssignDialog(context, request),
                                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                label: const Text('Aktar'),
                              ),
                            // 6. Not Ekle
                            if (canEdit)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _showNoteDialog(context, request),
                                icon: const Icon(Icons.note_add_outlined, size: 16),
                                label: const Text('Not Ekle'),
                              ),
                            // 7. Dosya Ekle
                            if (canEdit)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _showAttachmentDialog(context, request),
                                icon: const Icon(Icons.attach_file_rounded, size: 16),
                                label: const Text('Dosya Ekle'),
                              ),
                            // 7. Durum Güncelle (gelişmiş)
                            if (canEdit)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _showStatusDialog(context, request),
                                icon: const Icon(Icons.edit_rounded, size: 16),
                                label: const Text('Güncelle'),
                              ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Future<void> _callAndConnect(
      BuildContext context, RequestModel request) async {
    final phone = request.applicantPhone ?? '';

    // Telefon numarası validasyonu — yalnızca Türkiye GSM formatı kabul edilir
    final phoneRegex = RegExp(r'^(\+90|0)?[5][0-9]{9}$');
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçersiz telefon numarası formatı'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    final name = request.applicantName ?? 'vatandaş';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk_rounded, color: Color(0xFF1677ff)),
            SizedBox(width: 8),
            Text('Santralden Ara'),
          ],
        ),
        content: Text(
          '$name\n$phone\n\n'
          'Önce sizin telefonunuz çalacak, yanıtladıktan sonra vatandaşa bağlanacaksınız.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1677ff)),
            child: const Text('Ara'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final api = ApiService();
    try {
      await api.post(ApiConstants.pbxCallAndConnect, data: {
        'citizen_phone': phone,
        'request_id': request.id,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Arama başlatıldı. Telefon numaranız çalacak...'),
          backgroundColor: Color(0xFF1677ff),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.parseError(e)),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.textHint),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 12),
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

class _DetailCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? icon;

  const _DetailCard({required this.child, this.title, this.icon});

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
          if (title != null) ...[
            Row(
              children: [
                if (icon != null)
                  Icon(icon, size: 16, color: AppTheme.primaryGreen),
                if (icon != null) const SizedBox(width: 6),
                Text(
                  title!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final RequestAction action;

  const _ActionItem({required this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
              if (true)
                Container(
                  width: 1,
                  height: 24,
                  color: AppTheme.dividerColor,
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _actionLabel(action.actionType),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppDateUtils.formatDateTime(action.createdAt),
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textHint),
                    ),
                  ],
                ),
                if (action.createdByName != null)
                  Text(
                    action.createdByName!,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                if (action.note != null && action.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGray,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        action.note!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary),
                      ),
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
      'status_change': 'Durum Değiştirildi',
      'assignment': 'Görevlendirildi',
      'assigned': 'Atandı',
      'internal_note': 'İç Not',
      'note': 'Not Eklendi',
      'created': 'Oluşturuldu',
      'resolved': 'Çözüldü',
      'closed': 'Kapatıldı',
      'returned': 'İade Edildi',
      'deleted': 'Silindi',
    };
    return labels[type] ?? type;
  }
}

class _AttachmentItem extends StatefulWidget {
  final Attachment attachment;

  const _AttachmentItem({required this.attachment});

  @override
  State<_AttachmentItem> createState() => _AttachmentItemState();
}

class _AttachmentItemState extends State<_AttachmentItem> {
  String? _token;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final t = await SecureStorage.getToken();
    if (mounted) setState(() => _token = t);
  }

  bool get _isImage {
    final mt = widget.attachment.mimeType ?? '';
    return mt.startsWith('image/');
  }

  bool get _isVideo {
    final mt = widget.attachment.mimeType ?? '';
    return mt.startsWith('video/');
  }

  bool get _isPdf {
    final mt = widget.attachment.mimeType ?? '';
    final name = widget.attachment.originalName ?? widget.attachment.filename;
    return mt.contains('pdf') || name.toLowerCase().endsWith('.pdf');
  }

  IconData get _icon {
    if (_isImage) return Icons.image_outlined;
    if (_isVideo) return Icons.videocam_outlined;
    if (_isPdf) return Icons.picture_as_pdf_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color get _iconColor {
    if (_isImage) return Colors.blue;
    if (_isVideo) return Colors.purple;
    if (_isPdf) return Colors.red;
    return Colors.grey;
  }

  String _buildUrl() {
    return widget.attachment.urlPath(ApiConstants.baseUrl);
  }

  /// PDF'i Dio ile indirip geçici dizine kaydeder, sistem görüntüleyici ile açar.
  Future<void> _openPdf() async {
    if (_token == null || _downloading) return;
    setState(() => _downloading = true);

    try {
      final url = _buildUrl();
      final tmpDir = await getTemporaryDirectory();
      final filename = widget.attachment.originalName ?? widget.attachment.filename;
      final safeName = filename.split(RegExp(r'[/\\]')).last;
      final savePath = '${tmpDir.path}/$safeName';

      final d = dio_pkg.Dio();
      await d.download(
        url,
        savePath,
        options: dio_pkg.Options(
          headers: {'Authorization': 'Bearer $_token'},
        ),
      );

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF görüntüleyici bulunamadı'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF açılamadı: ${e.toString().split('\n').first}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _open() async {
    if (_isPdf) {
      await _openPdf();
      return;
    }
    if (_token == null) return;
    final url = '${_buildUrl()}?token=$_token';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showFullImage(BuildContext context) {
    if (_token == null) return;
    final url = _buildUrl();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  httpHeaders: {'Authorization': 'Bearer $_token'},
                  fit: BoxFit.contain,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: Colors.white, size: 48),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                onPressed: _open,
                tooltip: 'Dışarıda aç',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.attachment.originalName ?? widget.attachment.filename;
    final sizeKb = widget.attachment.fileSize != null
        ? '${(widget.attachment.fileSize! / 1024).toStringAsFixed(1)} KB'
        : null;

    if (_isImage) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim önizleme
            GestureDetector(
              onTap: () => _showFullImage(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _token == null
                    ? Container(
                        height: 160,
                        width: double.infinity,
                        color: const Color(0xFFF5F5F5),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : CachedNetworkImage(
                        imageUrl: _buildUrl(),
                        httpHeaders: {'Authorization': 'Bearer $_token'},
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 160,
                          color: const Color(0xFFF5F5F5),
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 80,
                          color: const Color(0xFFF5F5F5),
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: Color(0xFF8c8c8c), size: 32),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textHint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (sizeKb != null)
                  Text(sizeKb,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textHint)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _open,
                  child: const Icon(Icons.open_in_new_rounded,
                      size: 14, color: AppTheme.textHint),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _downloading ? null : _open,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _downloading
                  ? Padding(
                      padding: const EdgeInsets.all(9),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _iconColor,
                      ),
                    )
                  : Icon(_icon, size: 18, color: _iconColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (sizeKb != null)
                    Text(sizeKb,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textHint)),
                  if (_downloading)
                    const Text('İndiriliyor...',
                        style: TextStyle(
                            fontSize: 10, color: AppTheme.textHint)),
                ],
              ),
            ),
            if (!_downloading)
              const Icon(Icons.open_in_new_rounded,
                  size: 16, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}

class _AssignDialog extends StatefulWidget {
  final RequestModel request;

  const _AssignDialog({required this.request});

  @override
  State<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<_AssignDialog> {
  final _api = ApiService();
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _allUsers = [];
  String? _selectedUnitId;
  String? _selectedUserId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final unitResp = await _api.get('/units');
      final unitList = unitResp.data as List<dynamic>;
      List<Map<String, dynamic>> users = [];
      try {
        final userResp = await _api.get('/users/for-assignment');
        users = (userResp.data as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (_) {
        // yetki yok — sadece birim ataması yapılabilir
      }
      setState(() {
        _units = unitList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _allUsers = users;
        _selectedUnitId =
            widget.request.unitId?.isNotEmpty == true ? widget.request.unitId : null;
        _selectedUserId =
            widget.request.assignedTo?.isNotEmpty == true ? widget.request.assignedTo : null;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _unitUsers {
    if (_selectedUnitId == null) return [];
    return _allUsers.where((u) {
      if (u['unit_id']?.toString() == _selectedUnitId) return true;
      final extras = u['extra_unit_ids'];
      if (extras is List) {
        return extras.any((id) => id?.toString() == _selectedUnitId);
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Talebi Aktar'),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : _units.isEmpty
              ? const Text('Birim bulunamadı')
              : SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Birim',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF595959))),
                        const SizedBox(height: 4),
                        ..._units.map((u) => RadioListTile<String>(
                              value: u['id'].toString(),
                              groupValue: _selectedUnitId,
                              title: Text(u['name']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 13)),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setState(() {
                                _selectedUnitId = v;
                                _selectedUserId = null;
                              }),
                            )),
                        if (_selectedUnitId != null && _allUsers.isNotEmpty) ...[
                          const Divider(height: 20),
                          const Text('Personel (opsiyonel)',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF595959))),
                          const SizedBox(height: 4),
                          if (_unitUsers.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('Bu birimde aktif personel yok',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8c8c8c))),
                            )
                          else
                            RadioListTile<String?>(
                              value: null,
                              groupValue: _selectedUserId,
                              title: const Text('Personel seçme',
                                  style: TextStyle(fontSize: 13)),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) =>
                                  setState(() => _selectedUserId = v),
                            ),
                          ..._unitUsers.map((u) => RadioListTile<String>(
                                value: u['id'].toString(),
                                groupValue: _selectedUserId,
                                title: Text(
                                  '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'
                                      .trim(),
                                  style: const TextStyle(fontSize: 13),
                                ),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (v) =>
                                    setState(() => _selectedUserId = v),
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _selectedUnitId == null
              ? null
              : () async {
                  Navigator.pop(context);
                  final ok = await context.read<RequestProvider>().assignRequest(
                        requestId: widget.request.id,
                        unitId: _selectedUnitId,
                        userId: _selectedUserId,
                      );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Talep aktarıldı' : 'Aktarım başarısız'),
                      backgroundColor:
                          ok ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  );
                },
          child: const Text('Aktar'),
        ),
      ],
    );
  }
}

// ─── Dosya Yükleme Dialog'u ───────────────────────────────────────────────────

class _AttachmentUploadDialog extends StatefulWidget {
  final RequestModel request;

  const _AttachmentUploadDialog({required this.request});

  @override
  State<_AttachmentUploadDialog> createState() =>
      _AttachmentUploadDialogState();
}

class _AttachmentUploadDialogState extends State<_AttachmentUploadDialog> {
  List<AttachedFile> _files = [];
  bool _uploading = false;

  Future<void> _upload() async {
    if (_files.isEmpty) return;
    setState(() => _uploading = true);

    final prov = context.read<RequestProvider>();
    final ok = await prov.uploadAttachments(
      requestId: widget.request.id,
      filePaths: _files.map((f) => f.path).toList(),
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? '${_files.length} dosya başarıyla yüklendi'
            : 'Dosya yüklenemedi'),
        backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.attach_file_rounded, size: 20),
          SizedBox(width: 8),
          Text('Dosya Ekle'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: AttachmentPickerWidget(
            files: _files,
            onChanged: (updated) => setState(() => _files = updated),
            maxFiles: 10,
            maxMb: 10,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _uploading ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton.icon(
          onPressed: (_files.isEmpty || _uploading) ? null : _upload,
          icon: _uploading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_rounded, size: 16),
          label: Text(_uploading ? 'Yükleniyor...' : 'Yükle (${_files.length})'),
        ),
      ],
    );
  }
}
