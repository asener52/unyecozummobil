class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phone;
  final String? unitId;
  final String? unitName;
  final Map<String, dynamic> permissions;
  final bool isActive;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phone,
    this.unitId,
    this.unitName,
    this.permissions = const {},
    this.isActive = true,
  });

  String get name {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : email;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: json['role_name'] as String? ?? json['role'] as String? ?? 'unit_user',
      phone: json['phone'] as String?,
      unitId: json['unit_id']?.toString(),
      unitName: json['unit_name'] as String?,
      permissions: json['permissions'] is Map
          ? Map<String, dynamic>.from(json['permissions'] as Map)
          : {},
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'role_name': role,
        'phone': phone,
        'unit_id': unitId,
        'unit_name': unitName,
        'permissions': permissions,
        'is_active': isActive,
      };

  bool get isSuperAdmin => role == 'superadmin';
  bool get isAdmin => role == 'admin' || role == 'superadmin';
  bool get isManager => role == 'unit_manager' || isAdmin;

  bool hasPermission(String permission) {
    if (isSuperAdmin) return true;
    // permission format: "resource:action" e.g. "requests:read"
    final parts = permission.split(':');
    if (parts.length == 2) {
      final resource = parts[0];
      final action = parts[1];
      final actions = permissions[resource];
      if (actions is List) return actions.contains(action);
    }
    return permissions.containsKey(permission);
  }

  String get displayName => name;
  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : email[0].toUpperCase();
  }
}
