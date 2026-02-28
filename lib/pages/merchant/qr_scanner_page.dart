import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/qr_scanner_service.dart';
import '../../services/merchant_service.dart';
import '../../models/deal_redemption.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/generic_bottom_sheet.dart';
import 'package:discount_buddy/theme/app_colors.dart';

/// QR Scanner Screen for merchants to scan and redeem customer deals
class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  final MerchantService _merchantService = MerchantService();
  bool _isProcessing = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await QRScannerService.hasCameraPermission();
    if (!hasPermission) {
      final granted = await QRScannerService.requestCameraPermission();
      setState(() => _hasPermission = granted);
    } else {
      setState(() => _hasPermission = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String qrData) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    // Pause scanner to prevent multiple scans
    await _controller.stop();

    // Validate QR format
    if (!QRScannerService.isValidDealQRCode(qrData)) {
      if (mounted) {
        _showErrorDialog('Invalid QR code format', null);
      }
      setState(() => _isProcessing = false);
      // Resume scanner after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _controller.start();
      });
      return;
    }

    // Show loading
    _showLoadingDialog();

    try {
      // Call redemption API
      final response = await _merchantService.redeemDealByQR(qrData);

      // Hide loading
      if (mounted) Navigator.of(context).pop();

      // Check if redemption was successful
      final success = response['success'] ?? false;
      if (success) {
        final dealRedemption = DealRedemption.fromJson(response);
        if (mounted) _showSuccessDialog(dealRedemption);
      } else {
        final reason = _cleanErrorMessage(
          response['reason'] ?? 'Redemption failed',
        );
        if (mounted) _showErrorDialog(reason, null);
      }
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.of(context).pop();

      // Extract and clean error message
      String errorMessage = _cleanErrorMessage(e.toString());

      if (mounted) _showErrorDialog(errorMessage, null);
    }

    setState(() => _isProcessing = false);
  }

  String _cleanErrorMessage(String message) {
    // Remove common prefixes
    message = message.replaceFirst('Exception: Redemption failed: ', '');
    message = message.replaceFirst('reason: ', '');
    message = message.replaceFirst('Exception: ', '');
    return message.trim();
  }

  void _showLoadingDialog() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => GenericBottomSheet(
        title: 'Processing',
        showCloseButton: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              const SizedBox(
                height: 48,
                width: 48,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verifying deal...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccessDialog(DealRedemption dealRedemption) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: GenericBottomSheet(
          title: 'Deal Redeemed!',
          onClose: () {
            Navigator.of(context).pop(); // Close sheet
            Navigator.of(context).pop(); // Go back to dashboard
          },
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 16),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 52,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dealRedemption.deal.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Code',
                        dealRedemption.redemptionCode ?? 'N/A',
                      ),
                      _buildInfoRow(
                        'Restaurant',
                        dealRedemption.deal.restaurantName,
                      ),
                      _buildInfoRow(
                        'Redeemed',
                        _formatDateTime(dealRedemption.redeemedAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close sheet
                        Navigator.of(context).pop(); // Go back to dashboard
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message, dynamic errorType) {
    IconData icon = Icons.error_outline_rounded;
    Color color = AppColors.error;

    if (message.contains('already been redeemed')) {
      icon = Icons.warning_amber_rounded;
      color = AppColors.accent;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: GenericBottomSheet(
          title: 'Redemption Failed',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Icon(icon, color: color, size: 52),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Resume scanner after closing error
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted && !_isProcessing) _controller.start();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.background,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      side: const BorderSide(
                        color: AppColors.textDisabled,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Scan QR Code',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Camera permission required',
                style: GoogleFonts.inter(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.textPrimary,
      appBar: AppBar(
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.textPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard),
            onPressed: () => _showManualEntryDialog(),
            tooltip: 'Enter code manually',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleQRCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          // Overlay with scanning frame
          CustomPaint(painter: ScannerOverlayPainter(), child: Container()),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.textPrimary54,
              child: Text(
                'Position the QR code within the frame',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Enter Redemption Code',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: '6-digit code',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.length != 6) {
                _showError('Code must be 6 digits');
                return;
              }

              Navigator.of(context).pop();
              _showLoadingDialog();

              try {
                final response = await _merchantService.redeemDealByCode(code);

                if (mounted) Navigator.of(context).pop();

                final success = response['success'] ?? false;
                if (success) {
                  final dealRedemption = DealRedemption.fromJson(response);
                  _showSuccessDialog(dealRedemption);
                } else {
                  final reason = response['reason'] ?? 'Redemption failed';
                  _showErrorDialog(reason, null);
                }
              } catch (e) {
                if (mounted) Navigator.of(context).pop();

                String errorMessage = e.toString();
                if (errorMessage.startsWith('Exception: Redemption failed: ')) {
                  errorMessage = errorMessage.substring(
                    'Exception: Redemption failed: '.length,
                  );
                }

                _showErrorDialog(errorMessage, null);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary54
      ..style = PaintingStyle.fill;

    final framePaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final frameSize = size.width * 0.7;
    final left = (size.width - frameSize) / 2;
    final top = (size.height - frameSize) / 2;

    // Draw semi-transparent overlay
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRect(Rect.fromLTWH(left, top, frameSize, frameSize))
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    // Draw frame corners
    final cornerLength = 30.0;
    final rect = Rect.fromLTWH(left, top, frameSize, frameSize);

    // Top-left
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      framePaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left, rect.top + cornerLength),
      framePaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right - cornerLength, rect.top),
      framePaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      framePaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      framePaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left, rect.bottom - cornerLength),
      framePaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right - cornerLength, rect.bottom),
      framePaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
