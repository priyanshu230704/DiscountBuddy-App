import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/qr_scanner_service.dart';
import '../../services/merchant_service.dart';
import '../../models/deal_redemption.dart';
import '../../models/restaurant.dart';
import '../../widgets/generic_bottom_sheet.dart';
import 'package:discount_buddy/design/app_design.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_gradient_button.dart';
import '../../components/app_app_bar.dart';

/// QR Scanner Screen for merchants to scan and redeem customer deals
class QRScannerPage extends StatefulWidget {
  final int? initialRestaurantId;
  const QRScannerPage({super.key, this.initialRestaurantId});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  final MerchantService _merchantService = MerchantService();
  bool _isProcessing = false;
  bool _hasPermission = false;
  
  // Restaurant selection state
  List<Map<String, dynamic>> _restaurants = [];
  int? _selectedRestaurantId;

  @override
  void initState() {
    super.initState();
    _checkPermission(isInitialCheck: true);
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    try {
      final restaurants = await _merchantService.getMerchantRestaurants();
      if (mounted) {
        setState(() {
          _restaurants = restaurants;
          
          if (_restaurants.isNotEmpty) {
            // Priority for initial selection:
            // 1. widget.initialRestaurantId (if it's in the list)
            // 2. First restaurant in the list
            if (widget.initialRestaurantId != null && 
                _restaurants.any((r) => r['id'] == widget.initialRestaurantId)) {
              _selectedRestaurantId = widget.initialRestaurantId;
            } else {
              _selectedRestaurantId = _restaurants.first['id'];
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load restaurants: ${e.toString()}');
      }
    }
  }

  Future<void> _checkPermission({bool isInitialCheck = false}) async {
    // Only request permission if it's not already granted
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      if (mounted) setState(() => _hasPermission = true);
      return;
    }

    // Direct request as specified in guideline
    final result = await Permission.camera.request();
    
    if (mounted) {
      if (result.isGranted) {
        setState(() => _hasPermission = true);
      } else if (result.isPermanentlyDenied) {
        _showPermissionSettingsDialog();
      } else if (result.isDenied && !isInitialCheck) {
        // On iOS, if result is denied after a request was made, it often means 
        // the user clicked "Don't Allow" or has already said no before.
        // We show the settings dialog to help them.
        _showPermissionSettingsDialog();
      }
    }
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Camera Access Required',
          style: AppTypography.title.copyWith(fontSize: 18),
        ),
        content: Text(
          'Camera access is required to scan QR codes so you can quickly access offers and product details. Please enable it in your device settings to continue.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          AppGradientButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            width: 160,
            height: 48,
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String qrData) async {
    if (_isProcessing) return;

    // Pause scanner to prevent multiple scans
    await _controller.stop();

    // Validate QR format
    if (!QRScannerService.isValidDealQRCode(qrData)) {
      if (mounted) {
        _showErrorDialog('Invalid QR code format', null);
      }
      // Resume scanner after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _controller.start();
      });
      return;
    }

    // Show details modal to collect price and people count
    if (mounted) {
      _showRedemptionDetailsModal(qrData: qrData);
    }
  }

  void _showRedemptionDetailsModal({String? qrData, String? manualCode}) {
    final priceController = TextEditingController();
    final peopleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textDisabled.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Redemption Details',
                  style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter bill details to complete redemption',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                Text(
                  'Total Bill Amount',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixIcon: const Icon(Icons.receipt_long_rounded),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (double.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Number of People',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: peopleController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '1',
                    prefixIcon: const Icon(Icons.people_alt_rounded),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (int.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                AppGradientButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final price = double.parse(priceController.text);
                      final peopleCount = int.parse(peopleController.text);
                      Navigator.of(context).pop();
                      _processRedemption(
                        qrData: qrData,
                        manualCode: manualCode,
                        price: price,
                        peopleCount: peopleCount,
                        restaurantId: _selectedRestaurantId,
                      );
                    }
                  },
                  width: double.infinity,
                  height: 56,
                  child: Text(
                    'Redeem Deal',
                    style: AppTypography.title.copyWith(color: AppColors.white),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processRedemption({
    String? qrData,
    String? manualCode,
    required double price,
    required int peopleCount,
    int? restaurantId,
  }) async {
    setState(() => _isProcessing = true);
    _showLoadingDialog();

    try {
      final response = qrData != null
          ? await _merchantService.redeemDealByQR(qrData, price: price, peopleCount: peopleCount, restaurantId: restaurantId)
          : await _merchantService.redeemDealByCode(manualCode!, price: price, peopleCount: peopleCount, restaurantId: restaurantId);

      if (!mounted) return;
      Navigator.of(context).pop(); // Hide loading

      final success = response['success'] ?? false;
      if (success) {
        final dealRedemption = DealRedemption.fromJson(response);
        final loyaltyData = response['loyalty'] != null
            ? LoyaltyProgram.fromJson(response['loyalty'] as Map<String, dynamic>)
            : null;
        final loyaltyRewardJustEarned = response['loyalty_reward_just_earned'] as bool? ?? false;
        _showSuccessDialog(dealRedemption, loyaltyData, loyaltyRewardJustEarned);
      } else {
        final reason = _cleanErrorMessage(response['reason'] ?? 'Redemption failed');
        _showErrorDialog(reason, null);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Hide loading
      _showErrorDialog(_cleanErrorMessage(e.toString()), null);
    } finally {
      setState(() => _isProcessing = false);
    }
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
                  color: AppColors.merchantIndigo,
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verifying deal...',
                style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog(
    DealRedemption dealRedemption, [
    LoyaltyProgram? loyalty,
    bool loyaltyRewardJustEarned = false,
  ]) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 
              (loyalty != null && loyalty.loyaltyCardEnabled ? 0.85 : 0.65),
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
                    size: 64,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dealRedemption.deal.title,
                        style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        'Restaurant',
                        dealRedemption.deal.restaurantName,
                      ),
                      _buildInfoRow(
                        'Total Bill',
                        '£${dealRedemption.price?.toStringAsFixed(2) ?? '0.00'}',
                      ),
                      if (dealRedemption.deal.dealType == 'combo')
                        _buildInfoRow(
                          'Combo Price',
                          '£${dealRedemption.deal.comboPrice ?? '0.00'}',
                          valueColor: AppColors.merchantIndigo,
                        )
                      else
                        _buildInfoRow(
                          'Discount Saved',
                          '-£${dealRedemption.discountAmountSaved?.toStringAsFixed(2) ?? '0.00'}',
                          valueColor: AppColors.success,
                        ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1),
                      ),
                      _buildInfoRow(
                        'Final to Collect',
                        '£${dealRedemption.finalBillAmount?.toStringAsFixed(2) ?? '0.00'}',
                        isBold: true,
                        valueColor: AppColors.merchantIndigo,
                      ),
                      _buildInfoRow(
                        'People',
                        dealRedemption.peopleCount?.toString() ?? '1',
                      ),
                      _buildInfoRow(
                        'Redeemed At',
                        _formatDateTime(dealRedemption.redeemedAt),
                      ),
                    ],
                  ),
                ),
                if (loyalty != null && loyalty.loyaltyCardEnabled) ...[
                  const SizedBox(height: 16),
                  if (loyaltyRewardJustEarned)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: AppColors.orangeGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppShadows.medium,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🎉 Reward Earned!',
                                  style: AppTypography.title.copyWith(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Customer completed their card! Reward details:',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  loyalty.rewardDescription,
                                  style: AppTypography.title.copyWith(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: AppShadows.low,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.card_membership_rounded,
                                color: AppColors.primaryPurple,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Loyalty Program Progress',
                                style: AppTypography.title.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                loyalty.progressText.isNotEmpty
                                    ? loyalty.progressText
                                    : 'Progress: ${loyalty.completedRedemptions} of ${loyalty.requiredRedemptions}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${loyalty.remainingRedemptions} left',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primaryPurple,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: loyalty.progressPercentage / 100.0,
                              minHeight: 8,
                              backgroundColor: AppColors.cardBorder,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primaryPurple,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Reward: ${loyalty.rewardDescription}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: AppGradientButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close sheet
                      Navigator.of(context).pop(); // Go back to dashboard
                    },
                    width: double.infinity,
                    height: 56,
                    child: Text(
                      'Done',
                      style: AppTypography.title.copyWith(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
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
      color = AppColors.merchantAmber;
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
                child: Icon(icon, color: color, size: 60),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: AppGradientButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Resume scanner after closing error
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted && !_isProcessing) _controller.start();
                    });
                  },
                  width: double.infinity,
                  height: 56,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.textDisabled.withValues(alpha: 0.1),
                      AppColors.textDisabled.withValues(alpha: 0.1),
                    ],
                  ),
                  child: Text(
                    'Try Again',
                    style: AppTypography.title.copyWith(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
      return AppScaffold(
        appBar: AppAppBar(
          titleText: 'Scan QR Code',
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_rounded, size: 80, color: AppColors.textDisabled),
              const SizedBox(height: 24),
              Text(
                'Camera permission required',
                style: AppTypography.title.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Please grant camera access to scan codes.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 32),
              AppGradientButton(
                onPressed: () => _checkPermission(isInitialCheck: false),
                width: 200,
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      backgroundColor: Colors.black,
      appBar: AppAppBar(
        titleText: 'Scan QR Code',
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_outlined),
            onPressed: () => _showManualEntryDialog(),
            tooltip: 'Enter code manually',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_restaurants.isNotEmpty) _buildRestaurantFilter(),
          Expanded(
            child: Stack(
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
                CustomPaint(
                  painter: ScannerOverlayPainter(), 
                  child: const SizedBox.expand(),
                ),
                // Instructions
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Position QR code within frame',
                          style: AppTypography.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Enter Redemption Code',
          style: AppTypography.title,
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: AppTypography.title.copyWith(fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: AppTypography.body.copyWith(
              color: AppColors.textDisabled, 
              fontSize: 20, 
              letterSpacing: 2
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.merchantIndigo, width: 2),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w700, 
                color: AppColors.textSecondary
              ),
            ),
          ),
          AppGradientButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.length != 6) {
                _showError('Code must be 6 digits');
                return;
              }

              Navigator.of(context).pop();
              _showRedemptionDetailsModal(manualCode: code);
            },
            width: 120,
            height: 48,
            child: const Text('Next', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantFilter() {
    if (_restaurants.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _restaurants.map((restaurant) {
            final isSelected = _selectedRestaurantId == restaurant['id'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedRestaurantId = restaurant['id']);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.merchantIndigo : Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.merchantIndigo : Colors.white38,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    restaurant['name'],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final framePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final frameSize = size.width * 0.7;
    final left = (size.width - frameSize) / 2;
    final top = (size.height - frameSize) / 2;
    
    // Draw semi-transparent overlay
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, frameSize, frameSize), 
          const Radius.circular(24)
        ))
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    // Draw frame corners
    final cornerLength = 40.0;
    final radius = 24.0;
    final rect = Rect.fromLTWH(left, top, frameSize, frameSize);

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + cornerLength)
        ..lineTo(rect.left, rect.top + radius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + radius, rect.top)
        ..lineTo(rect.left + cornerLength, rect.top),
      framePaint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLength, rect.top)
        ..lineTo(rect.right - radius, rect.top)
        ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + radius)
        ..lineTo(rect.right, rect.top + cornerLength),
      framePaint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - cornerLength)
        ..lineTo(rect.left, rect.bottom - radius)
        ..quadraticBezierTo(rect.left, rect.bottom, rect.left + radius, rect.bottom)
        ..lineTo(rect.left + cornerLength, rect.bottom),
      framePaint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLength, rect.bottom)
        ..lineTo(rect.right - radius, rect.bottom)
        ..quadraticBezierTo(rect.right, rect.bottom, rect.right, rect.bottom - radius)
        ..lineTo(rect.right, rect.bottom - cornerLength),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
