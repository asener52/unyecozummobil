class FormTemplate {
  final String id;
  final String name;
  final String? description;
  final List<FormField> fields;
  final String? unitName;
  final String? topicName;

  const FormTemplate({
    required this.id,
    required this.name,
    this.description,
    this.fields = const [],
    this.unitName,
    this.topicName,
  });

  factory FormTemplate.fromJson(Map<String, dynamic> json) {
    return FormTemplate(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      unitName: json['unit_name'] as String?,
      topicName: json['topic_name'] as String?,
      fields: (json['fields'] as List<dynamic>?)
              ?.map((e) => FormField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class FormField {
  final String id;
  final String fieldKey;
  final String fieldLabel;
  final String fieldType;
  final bool isRequired;
  final String? placeholder;
  final String? helpText;
  final List<String> options;
  final int sortOrder;
  final Map<String, dynamic>? validation;

  const FormField({
    required this.id,
    required this.fieldKey,
    required this.fieldLabel,
    required this.fieldType,
    this.isRequired = false,
    this.placeholder,
    this.helpText,
    this.options = const [],
    this.sortOrder = 0,
    this.validation,
  });

  // Compatibility getter so existing code using field.fieldName still works
  String get fieldName => fieldKey;

  factory FormField.fromJson(Map<String, dynamic> json) {
    List<String> opts = [];
    final rawOpts = json['options'];
    if (rawOpts is List) {
      opts = rawOpts.map((e) => e.toString()).toList();
    } else if (rawOpts is Map && rawOpts.isNotEmpty) {
      opts = rawOpts.keys.map((k) => k.toString()).toList();
    } else if (rawOpts is String && rawOpts.isNotEmpty) {
      opts = rawOpts.split(',').map((e) => e.trim()).toList();
    }

    return FormField(
      id: json['id']?.toString() ?? '',
      fieldKey: json['field_key'] as String? ?? json['field_name'] as String? ?? '',
      fieldLabel: json['label'] as String? ?? json['field_label'] as String? ?? '',
      fieldType: json['field_type'] as String? ?? 'text',
      isRequired: json['is_required'] as bool? ?? json['required'] as bool? ?? false,
      placeholder: json['placeholder'] as String?,
      helpText: json['help_text'] as String?,
      options: opts,
      sortOrder: (json['field_order'] as num?)?.toInt() ??
          (json['sort_order'] as num?)?.toInt() ??
          0,
      validation: json['validation'] is Map
          ? Map<String, dynamic>.from(json['validation'] as Map)
          : null,
    );
  }
}

class Topic {
  final String id;
  final String name;
  final String? description;
  final int? deadlineHours;
  final String? unitId;
  final String? unitName;

  const Topic({
    required this.id,
    required this.name,
    this.description,
    this.deadlineHours,
    this.unitId,
    this.unitName,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      deadlineHours: (json['deadline_hours'] as num?)?.toInt() ??
          (json['deadline_days'] != null
              ? ((json['deadline_days'] as num).toInt() * 24)
              : null),
      unitId: json['unit_id']?.toString(),
      unitName: json['unit_name'] as String?,
    );
  }
}
