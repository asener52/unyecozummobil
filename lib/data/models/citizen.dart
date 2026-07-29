class Citizen {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? tcNo;
  final int requestCount;
  final String? createdAt;

  const Citizen({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.tcNo,
    this.requestCount = 0,
    this.createdAt,
  });

  String get displayName => name ?? email ?? phone ?? 'Bilinmiyor';

  factory Citizen.fromJson(Map<String, dynamic> json) {
    return Citizen(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? json['citizen_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      tcNo: json['tc_no'] as String?,
      requestCount: json['request_count'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
    );
  }
}
