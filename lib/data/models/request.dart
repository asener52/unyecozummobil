class RequestModel {
  final String id;
  final String trackingNumber;
  final String subject;
  final String? description;
  final String status;
  final String? priority;
  final String? applicantName;
  final String? applicantPhone;
  final String? applicantEmail;
  final String? formId;
  final String? formName;
  final String? unitId;
  final String? unitName;
  final String? assignedTo;
  final String? assignedName;
  final String createdAt;
  final String? updatedAt;
  final String? resolvedAt;
  final Map<String, dynamic>? formData;
  /// fieldKey → fieldLabel haritası — API'den geliyorsa dolu, yoksa boş
  final Map<String, String> formFieldLabels;
  final List<RequestAction> actions;
  final List<Attachment> attachments;
  final bool? slaBreached;
  final bool isRead;

  const RequestModel({
    required this.id,
    required this.trackingNumber,
    required this.subject,
    this.description,
    required this.status,
    this.priority,
    this.applicantName,
    this.applicantPhone,
    this.applicantEmail,
    this.formId,
    this.formName,
    this.unitId,
    this.unitName,
    this.assignedTo,
    this.assignedName,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.formData,
    this.formFieldLabels = const {},
    this.actions = const [],
    this.attachments = const [],
    this.slaBreached,
    this.isRead = false,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    // actions can come as 'actions' (admin detail) or 'history' (public track)
    final rawActions =
        (json['actions'] ?? json['history']) as List<dynamic>? ?? [];
    // attachments
    final rawAttachments = json['attachments'] as List<dynamic>? ?? [];
    // subject: topic_name (konu) önce göster, form_name (birim formu) fallback
    final subject = json['subject'] as String? ??
        json['topic_name'] as String? ??
        json['form_name'] as String? ??
        'Talep';

    return RequestModel(
      id: json['id']?.toString() ?? '',
      trackingNumber: json['tracking_number'] as String? ?? '',
      subject: subject,
      description: json['description'] as String? ?? json['resolution_note'] as String?,
      status: json['status'] as String? ?? 'pending',
      priority: json['priority'] as String?,
      applicantName: json['citizen_name'] as String? ?? json['applicant_name'] as String?,
      applicantPhone: json['citizen_phone'] as String? ?? json['applicant_phone'] as String?,
      applicantEmail: json['citizen_email'] as String? ?? json['applicant_email'] as String?,
      formId: json['form_id']?.toString(),
      formName: json['form_name'] as String?,
      unitId: (json['assigned_unit_id'] ?? json['unit_id'])?.toString(),
      unitName: json['unit_name'] as String?,
      assignedTo: (json['assigned_user_id'] ?? json['assigned_to'])?.toString(),
      assignedName: json['assigned_user_name'] as String? ?? json['assigned_name'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
      resolvedAt: json['resolved_at'] as String?,
      formData: json['form_data'] is Map
          ? Map<String, dynamic>.from(json['form_data'] as Map)
          : null,
      formFieldLabels: _parseFieldLabels(
          json['form_fields'] ?? json['form_schema'] ?? json['fields']),
      actions: rawActions
          .map((e) => RequestAction.fromJson(e as Map<String, dynamic>))
          .toList(),
      attachments: rawAttachments
          .map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      slaBreached: json['sla_breached'] as bool?,
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  static Map<String, String> _parseFieldLabels(dynamic raw) {
    if (raw is! List) return {};
    final result = <String, String>{};
    for (final item in raw) {
      if (item is Map) {
        final key = item['field_key'] ?? item['field_name'] ?? item['key'];
        final label = item['label'] ?? item['field_label'] ?? item['name'];
        if (key != null && label != null) {
          result[key.toString()] = label.toString();
        }
      }
    }
    return result;
  }

  String get statusLabel {
    const labels = {
      'pending':     'Beklemede',
      'in_progress': 'İşleme Alındı',
      'resolved':    'Onay Bekliyor',
      'approved':    'Onaylandı',
      'returned':    'İade Edildi',
      'rejected':    'Reddedildi',
      'cancelled':   'İptal',
    };
    return labels[status] ?? status;
  }

  String? get resolutionNote =>
      description?.isNotEmpty == true ? description : null;

  String get priorityLabel {
    const labels = {
      'low': 'Düşük',
      'normal': 'Normal',
      'medium': 'Orta',
      'high': 'Yüksek',
      'urgent': 'Acil',
    };
    return labels[priority ?? 'normal'] ?? 'Normal';
  }
}

class RequestAction {
  final String id;
  final String actionType;
  final String? note;
  final String? newStatus;
  final String createdAt;
  final String? createdByName;

  const RequestAction({
    required this.id,
    required this.actionType,
    this.note,
    this.newStatus,
    required this.createdAt,
    this.createdByName,
  });

  factory RequestAction.fromJson(Map<String, dynamic> json) {
    return RequestAction(
      id: json['id']?.toString() ?? '',
      actionType: json['action_type'] as String? ?? '',
      note: json['note'] as String?,
      newStatus: json['new_status'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      createdByName: json['user_name'] as String? ?? json['created_by_name'] as String?,
    );
  }
}

class Attachment {
  final String id;
  final String filename;
  final String? originalName;
  final String? mimeType;
  final int? fileSize;
  final String createdAt;
  final String? filePath; // tracking_no/filename — for /files/ URL

  const Attachment({
    required this.id,
    required this.filename,
    this.originalName,
    this.mimeType,
    this.fileSize,
    required this.createdAt,
    this.filePath,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id']?.toString() ?? '',
      filename: json['filename'] as String? ?? '',
      originalName: json['original_name'] as String?,
      mimeType: json['mime_type'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt(),
      createdAt: json['created_at'] as String? ?? '',
      filePath: json['file_path'] as String?,
    );
  }

  /// Full API path for this attachment
  String urlPath(String baseUrl) {
    final base = baseUrl.replaceAll('/api', '');
    if (filePath != null && filePath!.isNotEmpty) {
      return '$base/files/$filePath';
    }
    return '$base/uploads/$filename';
  }
}
