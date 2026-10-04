import 'package:permission_handler/permission_handler.dart';

/// Service for QR code scanning functionality
class QRScannerService {
  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Validate QR code format for deal redemption
  /// Expected format: `DEALUSE:<deal_use_id>:<redemption_code>`
  /// Example: DEALUSE:105:123456
  static bool isValidDealQRCode(String qrData) {
    if (qrData.isEmpty) return false;
    final parts = qrData.split(':');
    if (parts.length != 3) return false;
    if (parts[0] != 'DEALUSE') return false;
    if (int.tryParse(parts[1]) == null) return false;
    if (parts[2].length != 6 || int.tryParse(parts[2]) == null) return false;
    return true;
  }

  /// Validate QR code format for loyalty reward claim
  /// Expected format: `LOYALTYREWARD:<loyalty_id>:<reward_code>`
  /// Example: LOYALTYREWARD:42:123456
  static bool isValidLoyaltyRewardQRCode(String qrData) {
    if (qrData.isEmpty) return false;
    final parts = qrData.split(':');
    if (parts.length != 3) return false;
    if (parts[0] != 'LOYALTYREWARD') return false;
    if (int.tryParse(parts[1]) == null) return false;
    return parts[2].isNotEmpty;
  }

  /// Returns true if the QR payload is either a deal or a loyalty reward.
  static bool isValidMerchantQRCode(String qrData) =>
      isValidDealQRCode(qrData) || isValidLoyaltyRewardQRCode(qrData);

  /// Extract deal use ID from QR data
  static int? extractDealUseId(String qrData) {
    if (!isValidDealQRCode(qrData)) return null;
    final parts = qrData.split(':');
    return int.tryParse(parts[1]);
  }

  /// Extract redemption code from deal QR data
  static String? extractRedemptionCode(String qrData) {
    if (!isValidDealQRCode(qrData)) return null;
    final parts = qrData.split(':');
    return parts[2];
  }

  /// Extract reward_code from a LOYALTYREWARD QR payload
  static String? extractLoyaltyRewardCode(String qrData) {
    if (!isValidLoyaltyRewardQRCode(qrData)) return null;
    return qrData.split(':')[2];
  }
}
