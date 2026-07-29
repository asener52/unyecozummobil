import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/form_template.dart' as model;
import '../../../data/services/api_service.dart';

class DynamicFormFieldWidget extends StatelessWidget {
  final model.FormField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const DynamicFormFieldWidget({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (field.fieldType) {
      case 'text':
      case 'textarea':
      case 'email':
      case 'number':
      case 'phone':
        return _TextFieldWidget(field: field, value: value, onChanged: onChanged);
      case 'select':
      case 'dropdown':
        return _DropdownWidget(field: field, value: value, onChanged: onChanged);
      case 'multiselect':
      case 'multi_select':
      case 'checkboxgroup':
      case 'checkbox_group':
        return _MultiSelectWidget(field: field, value: value, onChanged: onChanged);
      case 'radio':
        return _RadioWidget(field: field, value: value, onChanged: onChanged);
      case 'checkbox':
        return _CheckboxWidget(field: field, value: value, onChanged: onChanged);
      case 'date':
        return _DateWidget(field: field, value: value, onChanged: onChanged);
      case 'time':
        return _TimeWidget(field: field, value: value, onChanged: onChanged);
      case 'rating':
        return _RatingWidget(field: field, value: value, onChanged: onChanged);
      case 'range':
        return _RangeWidget(field: field, value: value, onChanged: onChanged);
      case 'unit_select':
        return _ApiSelectWidget(
          field: field,
          value: value,
          onChanged: onChanged,
          apiPath: '/units',
          labelKey: 'name',
          valueKey: 'id',
        );
      case 'topic_select':
        return _ApiSelectWidget(
          field: field,
          value: value,
          onChanged: onChanged,
          apiPath: '/topics/public',
          labelKey: 'name',
          valueKey: 'id',
        );
      case 'user_select':
        return _ApiSelectWidget(
          field: field,
          value: value,
          onChanged: onChanged,
          apiPath: '/users',
          labelKey: 'display_name',
          valueKey: 'id',
          labelFallback: (item) {
            final fn = item['first_name'] ?? '';
            final ln = item['last_name'] ?? '';
            return '$fn $ln'.trim();
          },
        );
      case 'separator':
        return _SeparatorWidget(field: field);
      case 'info':
        return _InfoWidget(field: field);
      case 'file':
        return _FileInfoWidget(field: field);
      case 'hidden':
        return const SizedBox.shrink(); // gizli alan — render etme
      default:
        return _TextFieldWidget(field: field, value: value, onChanged: onChanged);
    }
  }
}

// ─── Text / Textarea / Email / Phone / Number ─────────────────────────────────

class _TextFieldWidget extends StatefulWidget {
  final model.FormField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _TextFieldWidget({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<_TextFieldWidget> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      maxLines: widget.field.fieldType == 'textarea' ? 3 : 1,
      keyboardType: widget.field.fieldType == 'number'
          ? TextInputType.number
          : widget.field.fieldType == 'email'
              ? TextInputType.emailAddress
              : widget.field.fieldType == 'phone'
                  ? TextInputType.phone
                  : TextInputType.text,
      decoration: InputDecoration(
        labelText:
            widget.field.fieldLabel + (widget.field.isRequired ? ' *' : ''),
        hintText: widget.field.placeholder,
        alignLabelWithHint: widget.field.fieldType == 'textarea',
      ),
      onChanged: widget.onChanged,
      validator: widget.field.isRequired
          ? (v) => v == null || v.trim().isEmpty
              ? '${widget.field.fieldLabel} gerekli'
              : null
          : null,
    );
  }
}

// ─── Select / Dropdown ────────────────────────────────────────────────────────

class _DropdownWidget extends StatelessWidget {
  final model.FormField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _DropdownWidget({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value?.toString(),
      isExpanded: true,
      decoration: InputDecoration(
        labelText: field.fieldLabel + (field.isRequired ? ' *' : ''),
      ),
      items: field.options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
      validator: field.isRequired
          ? (v) =>
              v == null || v.isEmpty ? '${field.fieldLabel} gerekli' : null
          : null,
    );
  }
}

// ─── Radio ────────────────────────────────────────────────────────────────────

class _RadioWidget extends StatelessWidget {
  final model.FormField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _RadioWidget({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.fieldLabel + (field.isRequired ? ' *' : ''),
          style: const TextStyle(fontSize: 13, color: Color(0xFF595959)),
        ),
        const SizedBox(height: 4),
        ...field.options.map(
          (option) => InkWell(
            onTap: () => onChanged(option),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Radio<String>(
                    value: option,
                    groupValue: value?.toString(),
                    onChanged: (v) => onChanged(v),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(option, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Checkbox ─────────────────────────────────────────────────────────────────

class _CheckboxWidget extends StatelessWidget {
  final model.FormField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _CheckboxWidget({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final checked = value == true || value == 'true';
    return CheckboxListTile(
      title: Text(field.fieldLabel, style: const TextStyle(fontSize: 14)),
      value: checked,
      onChanged: (v) => onChanged(v),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

// ─── Date ─────────────────────────────────────────────────────────────────────

class _DateWidget extends StatelessWidget {
  final model.FormField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _DateWidget({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value != null
              ? DateTime.tryParse(value.toString()) ?? DateTime.now()
              : DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          locale: const Locale('tr', 'TR'),
        );
        if (picked != null) {
          onChanged(picked.toIso8601String().substring(0, 10));
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.fieldLabel + (field.isRequired ? ' *' : ''),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value?.toString() ?? 'Tarih seçin',
          style: TextStyle(
            color: value == null ? const Color(0xFF8c8c8c) : null,
          ),
        ),
      ),
    );
  }
}

// ─── Time ─────────────────────────────────────────────────────────────────────

class _TimeWidget extends StatelessWidget {
  final model.FormField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _TimeWidget({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        TimeOfDay? initial;
        if (value != null) {
          final parts = value.toString().split(':');
          if (parts.length >= 2) {
            initial = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 0,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }
        final picked = await showTimePicker(
          context: context,
          initialTime: initial ?? TimeOfDay.now(),
        );
        if (picked != null) {
          onChanged(
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.fieldLabel + (field.isRequired ? ' *' : ''),
          suffixIcon: const Icon(Icons.access_time_outlined, size: 18),
        ),
        child: Text(
          value?.toString() ?? 'Saat seçin',
          style: TextStyle(
            color: value == null ? const Color(0xFF8c8c8c) : null,
          ),
        ),
      ),
    );
  }
}

// ─── Rating (Yıldız) ──────────────────────────────────────────────────────────

class _RatingWidget extends StatelessWidget {
  final model.FormField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _RatingWidget({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rating = (value is num)
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.fieldLabel + (field.isRequired ? ' *' : ''),
          style: const TextStyle(fontSize: 13, color: Color(0xFF595959)),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => onChanged(star),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: star <= rating ? Colors.amber : Colors.grey,
                  size: 32,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Range (Slider) ───────────────────────────────────────────────────────────

class _RangeWidget extends StatelessWidget {
  final model.FormField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _RangeWidget({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final min = (field.validation?['min'] as num?)?.toDouble() ?? 0.0;
    final max = (field.validation?['max'] as num?)?.toDouble() ?? 100.0;
    final current = (value is num)
        ? (value as num).toDouble()
        : double.tryParse(value?.toString() ?? '') ?? min;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              field.fieldLabel + (field.isRequired ? ' *' : ''),
              style: const TextStyle(fontSize: 13, color: Color(0xFF595959)),
            ),
            Text(
              current.toStringAsFixed(0),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF1a6b3c)),
            ),
          ],
        ),
        Slider(
          value: current.clamp(min, max),
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: (v) => onChanged(v.toInt()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(min.toStringAsFixed(0),
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFF8c8c8c))),
            Text(max.toStringAsFixed(0),
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFF8c8c8c))),
          ],
        ),
      ],
    );
  }
}

// ─── API-driven Select (unit_select / topic_select / user_select) ─────────────

class _ApiSelectWidget extends StatefulWidget {
  final model.FormField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final String apiPath;
  final String labelKey;
  final String valueKey;
  final String Function(Map<String, dynamic>)? labelFallback;

  const _ApiSelectWidget({
    required this.field,
    required this.value,
    required this.onChanged,
    required this.apiPath,
    required this.labelKey,
    required this.valueKey,
    this.labelFallback,
  });

  @override
  State<_ApiSelectWidget> createState() => _ApiSelectWidgetState();
}

class _ApiSelectWidgetState extends State<_ApiSelectWidget> {
  final _api = ApiService();
  List<Map<String, dynamic>> _options = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final resp = await _api.get(widget.apiPath);
      final raw = resp.data;
      List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map && raw['data'] is List) {
        list = raw['data'] as List;
      } else {
        list = [];
      }
      if (mounted) {
        setState(() {
          _options = list
              .whereType<Map<String, dynamic>>()
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Yüklenemedi'; });
    }
  }

  String _label(Map<String, dynamic> item) {
    if (widget.labelFallback != null) {
      final fb = widget.labelFallback!(item);
      if (fb.isNotEmpty) return fb;
    }
    return item[widget.labelKey]?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.field.fieldLabel + (widget.field.isRequired ? ' *' : ''),
        ),
        child: const SizedBox(
          height: 20,
          child: Row(children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Yükleniyor...', style: TextStyle(fontSize: 13, color: Color(0xFF8c8c8c))),
          ]),
        ),
      );
    }

    if (_error != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.field.fieldLabel,
          errorText: _error,
        ),
        child: const SizedBox(),
      );
    }

    final currentVal = widget.value?.toString();
    final validVal = _options.any((o) => o[widget.valueKey]?.toString() == currentVal)
        ? currentVal
        : null;

    return DropdownButtonFormField<String>(
      value: validVal,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: widget.field.fieldLabel + (widget.field.isRequired ? ' *' : ''),
      ),
      hint: const Text('Seçiniz'),
      items: _options.map((o) {
        final v = o[widget.valueKey]?.toString() ?? '';
        return DropdownMenuItem<String>(value: v, child: Text(_label(o)));
      }).toList(),
      onChanged: widget.onChanged,
      validator: widget.field.isRequired
          ? (v) => v == null || v.isEmpty ? '${widget.field.fieldLabel} gerekli' : null
          : null,
    );
  }
}

// ─── Separator ────────────────────────────────────────────────────────────────

class _SeparatorWidget extends StatelessWidget {
  final model.FormField field;

  const _SeparatorWidget({required this.field});

  @override
  Widget build(BuildContext context) {
    if (field.fieldLabel.isEmpty) return const Divider(height: 24);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            field.fieldLabel,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8c8c8c),
                fontWeight: FontWeight.w500),
          ),
        ),
        const Expanded(child: Divider()),
      ]),
    );
  }
}

// ─── Info ─────────────────────────────────────────────────────────────────────

class _InfoWidget extends StatelessWidget {
  final model.FormField field;

  const _InfoWidget({required this.field});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFe6f7ff),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF91caff)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF1677ff), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              field.fieldLabel.isNotEmpty ? field.fieldLabel : (field.helpText ?? ''),
              style: const TextStyle(fontSize: 13, color: Color(0xFF003eb3)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MultiSelect (Çoklu Seçim) ────────────────────────────────────────────────

class _MultiSelectWidget extends StatelessWidget {
  final model.FormField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _MultiSelectWidget({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  List<String> _selectedList() {
    if (value == null) return [];
    if (value is List) return (value as List).map((e) => e.toString()).toList();
    if (value is String && (value as String).isNotEmpty) {
      return (value as String).split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedList();

    return FormField<List<String>>(
      initialValue: selected,
      validator: field.isRequired
          ? (v) =>
              (v == null || v.isEmpty) ? '${field.fieldLabel} gerekli' : null
          : null,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.fieldLabel + (field.isRequired ? ' *' : ''),
              style: const TextStyle(fontSize: 13, color: Color(0xFF595959)),
            ),
            if (field.helpText != null) ...[
              const SizedBox(height: 2),
              Text(field.helpText!,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8c8c8c))),
            ],
            const SizedBox(height: 6),
            ...field.options.map((option) {
              final isChecked = selected.contains(option);
              return InkWell(
                onTap: () {
                  final updated = List<String>.from(selected);
                  if (isChecked) {
                    updated.remove(option);
                  } else {
                    updated.add(option);
                  }
                  onChanged(updated.join(','));
                  state.didChange(updated);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isChecked,
                        onChanged: (v) {
                          final updated = List<String>.from(selected);
                          if (v == true) {
                            updated.add(option);
                          } else {
                            updated.remove(option);
                          }
                          onChanged(updated.join(','));
                          state.didChange(updated);
                        },
                        activeColor: AppTheme.primaryGreen,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      Expanded(
                          child: Text(option,
                              style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                ),
              );
            }),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Text(state.errorText!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFd32f2f))),
              ),
          ],
        );
      },
    );
  }
}

// ─── File (form içi dosya alanı) ──────────────────────────────────────────────

class _FileInfoWidget extends StatelessWidget {
  final model.FormField field;

  const _FileInfoWidget({required this.field});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Row(children: [
        const Icon(Icons.attach_file_rounded, color: Color(0xFF8c8c8c), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${field.fieldLabel}: Dosya ekleme için yukarıdaki "Dosya / Medya Ekle" bölümünü kullanın',
            style: const TextStyle(fontSize: 12, color: Color(0xFF595959)),
          ),
        ),
      ]),
    );
  }
}
