import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/form_template.dart';
import '../../../data/repositories/form_repository.dart';
import '../../../data/repositories/request_repository.dart';
import '../../../data/services/api_service.dart';
import '../../providers/request_provider.dart';
import '../../widgets/common/attachment_picker_widget.dart';
import '../../widgets/request/dynamic_form_field_widget.dart';

enum _Step { selectForm, fillForm, success }

class AdminCreateRequestScreen extends StatefulWidget {
  const AdminCreateRequestScreen({super.key});

  @override
  State<AdminCreateRequestScreen> createState() =>
      _AdminCreateRequestScreenState();
}

class _AdminCreateRequestScreenState extends State<AdminCreateRequestScreen> {
  _Step _step = _Step.selectForm;

  // — Adım 1: Form seçimi —
  final _formRepo = FormRepository();
  List<FormTemplate> _templates = [];
  bool _loadingTemplates = true;
  String _templateSearch = '';
  FormTemplate? _selectedTemplate; // null = Genel talep

  // — Adım 2: Form doldurma —
  final _formKey = GlobalKey<FormState>();
  final _requestRepo = RequestRepository();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final Map<String, dynamic> _formData = {};
  List<AttachedFile> _attachments = [];

  bool _submitting = false;
  String? _submitError;

  // — Adım 3: Başarı —
  String? _trackingNumber;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    try {
      final list = await _formRepo.getPublicForms();
      if (mounted) setState(() { _templates = list; _loadingTemplates = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingTemplates = false);
    }
  }

  // ── Adım 1: Form seçimi ──────────────────────────────────────────────────

  void _selectTemplate(FormTemplate? tpl) {
    setState(() {
      _selectedTemplate = tpl;
      _formData.clear();
      _step = _Step.fillForm;
    });
  }

  Widget _buildSelectStep() {
    final filtered = _templates.where((t) {
      if (_templateSearch.isEmpty) return true;
      return t.name.toLowerCase().contains(_templateSearch.toLowerCase()) ||
          (t.description?.toLowerCase().contains(_templateSearch.toLowerCase()) ??
              false);
    }).toList();

    return Column(
      children: [
        // Arama
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Form ara...',
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => setState(() => _templateSearch = v),
          ),
        ),

        Expanded(
          child: _loadingTemplates
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    // Genel talep seçeneği
                    _TemplateCard(
                      title: 'Genel Talep',
                      subtitle: 'Özel bir form gerektirmeyen talepler',
                      icon: Icons.article_outlined,
                      onTap: () => _selectTemplate(null),
                    ),
                    const SizedBox(height: 8),

                    if (filtered.isEmpty && _templateSearch.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            '"$_templateSearch" ile eşleşen form bulunamadı',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    else ...[
                      if (filtered.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'FORM ŞABLONLARI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textHint,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ...filtered.map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _TemplateCard(
                              title: t.name,
                              subtitle: t.description ??
                                  (t.unitName != null ? 'Birim: ${t.unitName}' : null),
                              icon: Icons.dynamic_form_outlined,
                              onTap: () => _selectTemplate(t),
                            ),
                          )),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  // ── Adım 2: Form doldurma ────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _submitError = null; });

    try {
      final subject = _subjectCtrl.text.trim().isNotEmpty
          ? _subjectCtrl.text.trim()
          : _selectedTemplate?.name ?? 'Genel Talep';

      String tracking;
      if (_attachments.isNotEmpty) {
        final fd = FormData();
        fd.fields
          ..add(MapEntry('citizen_name', _nameCtrl.text.trim()))
          ..add(MapEntry('citizen_phone', _phoneCtrl.text.trim()))
          ..add(MapEntry('subject', subject))
          ..add(MapEntry('description', _descCtrl.text.trim()));
        if (_emailCtrl.text.trim().isNotEmpty) {
          fd.fields.add(MapEntry('citizen_email', _emailCtrl.text.trim()));
        }
        if (_selectedTemplate != null) {
          fd.fields.add(MapEntry('form_id', _selectedTemplate!.id));
        }
        for (final entry in _formData.entries) {
          fd.fields.add(MapEntry(entry.key, entry.value.toString()));
        }
        for (final file in _attachments) {
          fd.files.add(MapEntry(
            'files',
            await MultipartFile.fromFile(
              file.path,
              filename: file.name,
              contentType: DioMediaType.parse(file.mimeType),
            ),
          ));
        }
        tracking = await _requestRepo.createRequestMultipart(fd);
      } else {
        final data = <String, dynamic>{
          'citizen_name': _nameCtrl.text.trim(),
          'citizen_phone': _phoneCtrl.text.trim(),
          'subject': subject,
          'description': _descCtrl.text.trim(),
          if (_emailCtrl.text.trim().isNotEmpty)
            'citizen_email': _emailCtrl.text.trim(),
          if (_selectedTemplate != null) 'form_id': _selectedTemplate!.id,
          ..._formData,
        };
        tracking = await _requestRepo.createRequest(data: data);
      }

      setState(() { _trackingNumber = tracking; _submitting = false; _step = _Step.success; });

      // Talep listesini yenile
      if (mounted) {
        context.read<RequestProvider>().fetchRequests();
      }
    } catch (e) {
      setState(() { _submitError = ApiService.parseError(e); _submitting = false; });
    }
  }

  Widget _buildFillStep() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Seçilen form etiketi
          if (_selectedTemplate != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dynamic_form_outlined,
                      size: 16, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedTemplate!.name,
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Başvuru sahibi
          _SectionCard(
            title: 'Başvuru Sahibi Bilgileri',
            icon: Icons.person_outline,
            children: [
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ad soyad gerekli' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon *',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '05XX XXX XX XX',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Telefon gerekli' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-posta (isteğe bağlı)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Talep bilgileri
          _SectionCard(
            title: 'Talep Bilgileri',
            icon: Icons.article_outlined,
            children: [
              if (_selectedTemplate == null) ...[
                TextFormField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Konu *',
                    prefixIcon: Icon(Icons.subject),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Konu gerekli' : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Açıklama *',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                  hintText: 'Talebinizi detaylı açıklayın...',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Açıklama gerekli' : null,
              ),
            ],
          ),

          // Dinamik form alanları
          if (_selectedTemplate != null &&
              _selectedTemplate!.fields.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Ek Bilgiler',
              icon: Icons.list_alt_outlined,
              children: _selectedTemplate!.fields
                  .map((field) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DynamicFormFieldWidget(
                          field: field,
                          value: _formData[field.fieldKey],
                          onChanged: (v) =>
                              setState(() => _formData[field.fieldKey] = v),
                        ),
                      ))
                  .toList(),
            ),
          ],

          // Dosya / Medya ekle
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Fotoğraf / Video / Belge Ekle',
            icon: Icons.attach_file_rounded,
            children: [
              AttachmentPickerWidget(
                files: _attachments,
                onChanged: (files) => setState(() => _attachments = files),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Hata
          if (_submitError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.errorColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_submitError!,
                        style: const TextStyle(
                            color: AppTheme.errorColor, fontSize: 13)),
                  ),
                ],
              ),
            ),

          ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded),
            label: Text(_submitting ? 'Kaydediliyor...' : 'Talebi Kaydet'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50)),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Adım 3: Başarı ───────────────────────────────────────────────────────

  Widget _buildSuccessStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.successColor, size: 56),
            ),
            const SizedBox(height: 24),
            const Text('Talep Oluşturuldu!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              'Talep başarıyla sisteme kaydedildi.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Takip numarası
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                    ClipboardData(text: _trackingNumber ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Takip numarası kopyalandı'),
                      duration: Duration(seconds: 1)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _trackingNumber ?? '',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                          letterSpacing: 1.5),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.copy,
                        color: AppTheme.primaryGreen, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Kopyalamak için dokunun',
                style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.list_alt_rounded),
              label: const Text('Talep Listesine Dön'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // Yeni talep oluştur — formu sıfırla
                setState(() {
                  _step = _Step.selectForm;
                  _trackingNumber = null;
                  _selectedTemplate = null;
                  _nameCtrl.clear();
                  _phoneCtrl.clear();
                  _emailCtrl.clear();
                  _subjectCtrl.clear();
                  _descCtrl.clear();
                  _formData.clear();
                  _attachments.clear();
                  _submitError = null;
                });
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni Talep Oluştur'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ana build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    String title;
    Widget? leading;

    switch (_step) {
      case _Step.selectForm:
        title = 'Yeni Talep';
        leading = null; // AppBar varsayılan back butonu
        break;
      case _Step.fillForm:
        title = _selectedTemplate?.name ?? 'Genel Talep';
        leading = IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _step = _Step.selectForm),
        );
        break;
      case _Step.success:
        title = 'Talep Oluşturuldu';
        leading = const SizedBox.shrink();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: leading,
        automaticallyImplyLeading: _step != _Step.success,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: switch (_step) {
          _Step.selectForm => KeyedSubtree(
              key: const ValueKey('select'),
              child: _buildSelectStep(),
            ),
          _Step.fillForm => KeyedSubtree(
              key: const ValueKey('fill'),
              child: _buildFillStep(),
            ),
          _Step.success => KeyedSubtree(
              key: const ValueKey('success'),
              child: _buildSuccessStep(),
            ),
        },
      ),
    );
  }
}

// ─── Yardımcı widget'lar ────────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textHint, size: 22),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard(
      {required this.title, required this.icon, required this.children});

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
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const Divider(height: 18),
          ...children,
        ],
      ),
    );
  }
}
