class ExternalMessage {
  final String id;
  final String source;
  final String? senderName;
  final String? senderContact;
  final String content;
  final String status;
  final String? linkedRequestId;
  final String? linkedTrackingNumber;
  final String createdAt;

  const ExternalMessage({
    required this.id,
    required this.source,
    this.senderName,
    this.senderContact,
    required this.content,
    required this.status,
    this.linkedRequestId,
    this.linkedTrackingNumber,
    required this.createdAt,
  });

  String get sourceLabel {
    switch (source) {
      case 'whatsapp':
        return 'WhatsApp';
      case 'email':
        return 'E-posta';
      case 'sms':
        return 'SMS';
      default:
        return source;
    }
  }

  bool get isConverted => linkedRequestId != null;

  factory ExternalMessage.fromJson(Map<String, dynamic> json) {
    return ExternalMessage(
      id: json['id']?.toString() ?? '',
      source: json['source'] as String? ?? '',
      senderName: json['sender_name'] as String?,
      senderContact: json['sender_contact'] as String? ??
          json['sender_phone'] as String? ??
          json['sender_email'] as String?,
      content: json['content'] as String? ?? json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'new',
      linkedRequestId: json['linked_request_id']?.toString(),
      linkedTrackingNumber: json['tracking_number'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
