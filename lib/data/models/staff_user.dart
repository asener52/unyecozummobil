class StaffUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? roleName;
  final String? roleDisplayName;
  final String? unitId;
  final String? unitName;
  final bool isActive;
  final bool isLdap;
  final String? createdAt;

  const StaffUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.roleName,
    this.roleDisplayName,
    this.unitId,
    this.unitName,
    this.isActive = true,
    this.isLdap = false,
    this.createdAt,
  });

  String get name {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : email;
  }

  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phone: json['phone'] as String?,
      roleName: json['role_name'] as String?,
      roleDisplayName: json['role_display_name'] as String? ?? json['role_name'] as String?,
      unitId: json['unit_id']?.toString(),
      unitName: json['unit_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isLdap: json['is_ldap'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }
}
