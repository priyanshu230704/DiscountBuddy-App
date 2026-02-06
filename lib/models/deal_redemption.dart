class DealRedemption {
  final int id;
  final String redemptionCode;
  final String qrCodeUrl;
  final String status;
  final String expiresAt;

  DealRedemption({
    required this.id,
    required this.redemptionCode,
    required this.qrCodeUrl,
    required this.status,
    required this.expiresAt,
  });

  factory DealRedemption.fromJson(Map<String, dynamic> json) {
    return DealRedemption(
      id: json['id'] as int? ?? 0,
      redemptionCode: json['redemption_code'] as String? ?? '',
      qrCodeUrl: json['qr_code_url'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      expiresAt: json['expires_at'] as String? ?? '',
    );
  }
}
