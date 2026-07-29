class Unit {
  final String id;
  final String name;
  final String? parentId;
  final String? parentName;
  final String? description;
  final bool isActive;
  final int? requestCount;

  const Unit({
    required this.id,
    required this.name,
    this.parentId,
    this.parentName,
    this.description,
    this.isActive = true,
    this.requestCount,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      parentId: json['parent_id']?.toString(),
      parentName: json['parent_name'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      requestCount: json['request_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parent_id': parentId,
        'description': description,
        'is_active': isActive,
      };
}
