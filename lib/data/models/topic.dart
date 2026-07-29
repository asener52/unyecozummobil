class Topic {
  final String id;
  final String name;
  final String? description;
  final int? deadlineDays;
  final bool isActive;
  final int? requestCount;

  const Topic({
    required this.id,
    required this.name,
    this.description,
    this.deadlineDays,
    this.isActive = true,
    this.requestCount,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      deadlineDays: json['deadline_days'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      requestCount: json['request_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'deadline_days': deadlineDays,
        'is_active': isActive,
      };
}
