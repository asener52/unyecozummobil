import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/form_template.dart';
import '../../../data/repositories/form_repository.dart';
import '../../../data/repositories/request_repository.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/common/attachment_picker_widget.dart';
import '../../widgets/request/dynamic_form_field_widget.dart';

class CitizenFormScreen extends StatefulWidget {
  final String? formId;

  const CitizenFormScreen({super.key, this.formId});

  @override
  State<CitizenFormScreen> createState() => _CitizenFormScreenState();
}

class _CitizenFormScreenState extends State<CitizenFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formRepo = FormRepository();
  final _requestRepo = RequestRepository();

  FormTemplate? _template;
  bool _loading = true;
  bool _submitting = false;
  String? _submitError;
  String? _trackingNumber;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final Map<String, dynamic> _formData = {};
  List<AttachedFile> _attachments = [];

  @override
  void initState() {
    super.initState();
    if (widget.formId != null) {
      _loadForm(widget.formId!);
    } else {
      setState(() => _loading = false);
    }
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

  Future<void> _loadForm(String id) async {
    try {
      final form = await _formRepo.getPublicForm(id);
      setState(() {
        _template = form;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final subject = _subjectCtrl.text.trim().isNotEmpty
          ? _subjectCtrl.text.trim()
          : _template?.name ?? 'Talep';

      if (_attachments.isNotEmpty) {
        // Multipart form (dosya varsa)
        final formData = FormData();
        formData.fields
          ..add(MapEntry('citizen_name', _nameCtrl.text.trim()))
          ..add(MapEntry('citizen_phone', _phoneCtrl.text.trim()))
          ..add(MapEntry('subject', subject))
          ..add(MapEntry('description', _descCtrl.text.trim()));
        if (_emailCtrl.text.trim().isNotEmpty) {
          formData.fields
              .add(MapEntry('citizen_email', _emailCtrl.text.trim()));
        }
        if (_template != null) {
          formData.fields.add(MapEntry('form_id', _template!.id));
        }
        // Dinamik form alanları
        for (final entry in _formData.entries) {
          formData.fields.add(MapEntry(entry.key, entry.value.toString()));
        }
        for (final file in _attachments) {
          formData.files.add(MapEntry(
            'files',
            await MultipartFile.fromFile(
              file.path,
              filename: file.name,
              contentType: DioMediaType.parse(file.mimeType),
            ),
          ));
        }
        final tracking = await _requestRepo.createRequestMultipart(formData);
        if (tracking.isEmpty) throw Exception('Sunucu takip numarası döndürmedi. Lütfen tekrar deneyin.');
        setState(() {
          _trackingNumber = tracking;
          _submitting = false;
        });
      } else {
        // Normal JSON
        final data = <String, dynamic>{
          'citizen_name': _nameCtrl.text.trim(),
          'citizen_phone': _phoneCtrl.text.trim(),
          'subject': subject,
          'description': _descCtrl.text.trim(),
          if (_emailCtrl.text.trim().isNotEmpty)
            'citizen_email': _emailCtrl.text.trim(),
          if (_template != null) 'form_id': _template!.id,
          ..._formData,
        };
        final tracking = await _requestRepo.createRequest(data: data);
        if (tracking.isEmpty) throw Exception('Sunucu takip numarası döndürmedi. Lütfen tekrar deneyin.');
        setState(() {
          _trackingNumber = tracking;
          _submitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _submitError = ApiService.parseError(e);
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_trackingNumber != null) {
      return _SuccessScreen(trackingNumber: _trackingNumber!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_template?.name ?? 'Talep Oluştur'),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ad soyad gerekli'
                            : null,
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
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Telefon numarası gerekli'
                            : null,
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
                      if (_template == null) ...[
                        TextFormField(
                          controller: _subjectCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Konu *',
                            prefixIcon: Icon(Icons.subject),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Konu gerekli'
                              : null,
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
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Açıklama gerekli'
                            : null,
                      ),
                    ],
                  ),

                  // Dinamik form alanları
                  if (_template != null && _template!.fields.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Ek Bilgiler',
                      icon: Icons.list_alt_outlined,
                      children: _template!.fields
                          .map((field) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: DynamicFormFieldWidget(
                                  field: field,
                                  value: _formData[field.fieldKey],
                                  onChanged: (v) => setState(
                                      () => _formData[field.fieldKey] = v),
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
                        onChanged: (files) =>
                            setState(() => _attachments = files),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Hata mesajı
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
                            child: Text(
                              _submitError!,
                              style: const TextStyle(
                                  color: AppTheme.errorColor, fontSize: 13),
                            ),
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
                    label: Text(_submitting ? 'Gönderiliyor...' : 'Talebi Gönder'),
                  ),

                  const SizedBox(height: 32),
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

class _SuccessScreen extends StatelessWidget {
  final String trackingNumber;

  const _SuccessScreen({required this.trackingNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talep Alındı'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
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
              const Text('Talebiniz Alındı!',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                'Talebiniz başarıyla sisteme kaydedildi.\nTakip numaranızı not edin:',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: trackingNumber));
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
                        trackingNumber,
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
                  style: TextStyle(
                      color: AppTheme.textHint, fontSize: 12)),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () =>
                    context.go('/taleptakip/$trackingNumber'),
                icon: const Icon(Icons.search),
                label: const Text('Takip Et'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/'),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
