import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../design/app_colors.dart';
import '../../design/app_typography.dart';
import '../../models/spin_to_win/customer_spin_models.dart';
import '../../routes/app_routes.dart';
import '../../services/customer_spin_service.dart';

class SpinWheelScreen extends StatefulWidget {
  final bool isModal;
  const SpinWheelScreen({super.key, this.isModal = false});

  static Future<void> showModal(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        clipBehavior: Clip.hardEdge,
        child: const SpinWheelScreen(isModal: true),
      ),
    );
  }

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen> with SingleTickerProviderStateMixin {
  final CustomerSpinService _spinService = CustomerSpinService();

  SpinWheelResponse? _wheelData;
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _wheelAnimation;
  double _currentRotation = 0.0;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _wheelAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.decelerate,
    );
    _loadWheelData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWheelData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _spinService.getWheel();
      setState(() {
        _wheelData = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerSpin() async {
    if (_isSpinning || _wheelData == null || !_wheelData!.isActive) return;
    if (_wheelData!.remainingSpinsToday <= 0) {
      Get.snackbar(
        'Limit Reached',
        'You have reached your daily spin limit of ${_wheelData!.maxSpinsPerDay}. Try again tomorrow!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isSpinning = true;
    });

    try {
      final result = await _spinService.spinWheel();
      _animateWheelToSlice(result);
    } catch (e) {
      setState(() {
        _isSpinning = false;
      });
      Get.snackbar(
        'Spin Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _animateWheelToSlice(SpinResultResponse result) {
    final slices = _wheelData?.slices ?? [];
    if (slices.isEmpty) {
      setState(() => _isSpinning = false);
      return;
    }

    final totalSlices = slices.length;
    final targetSliceIndex = slices.indexWhere((s) => s.sliceIndex == result.sliceIndex);
    final sliceIdx = targetSliceIndex >= 0 ? targetSliceIndex : 0;

    // Pointer is at the top (-pi/2)
    final sliceAngle = (2 * math.pi) / totalSlices;
    final targetAngle = (2 * math.pi) - (sliceIdx * sliceAngle) - (sliceAngle / 2);
    final extraFullRounds = 5 * 2 * math.pi;

    final startAngle = _currentRotation % (2 * math.pi);
    final finalRotation = _currentRotation + extraFullRounds + (targetAngle - startAngle);

    final animationTween = Tween<double>(begin: _currentRotation, end: finalRotation);

    _wheelAnimation = animationTween.animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.reset();
    _animationController.forward().then((_) {
      setState(() {
        _currentRotation = finalRotation;
        _isSpinning = false;
      });

      _loadWheelData();
      _showResultDialog(result);
    });
  }

  void _showResultDialog(SpinResultResponse result) {
    final isWin = result.isWin;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isWin ? '🎉 CONGRATULATIONS! 🎉' : '😅 BETTER LUCK NEXT TIME!',
                textAlign: TextAlign.center,
                style: AppTypography.title.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isWin ? const Color(0xFF9333EA) : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Icon(
                isWin ? Icons.card_giftcard_rounded : Icons.sentiment_neutral_rounded,
                size: 64,
                color: isWin ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                result.title,
                textAlign: TextAlign.center,
                style: AppTypography.title.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              if (result.promoCode.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          result.promoCode,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF9333EA),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFF9333EA)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: result.promoCode));
                          Get.snackbar('Copied', 'Promo code copied to clipboard!', snackPosition: SnackPosition.BOTTOM);
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9333EA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Awesome!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(child: _buildBody()),
            if (_wheelData != null && _wheelData!.isActive) _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleIconButton(
            icon: Icons.chevron_left_rounded,
            onTap: () {
              if (widget.isModal) {
                Navigator.pop(context);
              } else {
                Get.back();
              }
            },
          ),
          Row(
            children: [
              _CircleIconButton(
                icon: Icons.emoji_events_outlined,
                onTap: () {
                  if (widget.isModal) {
                    Navigator.pop(context);
                  }
                  Get.toNamed(AppRoutes.myPrizes);
                },
              ),
              const SizedBox(width: 10),
              _CircleIconButton(
                icon: Icons.close_rounded,
                onTap: () {
                  if (widget.isModal) {
                    Navigator.pop(context);
                  } else {
                    Get.back();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF9333EA)));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadWheelData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_wheelData == null || !_wheelData!.isActive) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars_rounded, size: 72, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                'No Active Wheel',
                style: AppTypography.title.copyWith(fontSize: 20, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _wheelData?.message ?? 'No Spin to Win campaign currently active. Check back soon for rewards!',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final slices = _wheelData!.slices;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Main Header Title
          Text(
            (_wheelData?.title != null && _wheelData!.title!.isNotEmpty)
                ? _wheelData!.title!
                : 'Spin to Unlock\nExclusive Discount',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1B4B),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              (_wheelData?.description != null && _wheelData!.description!.isNotEmpty)
                  ? _wheelData!.description!
                  : 'Get 95% OFF on your first spin and unlock smarter, faster scanning today!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Wheel & Stand Graphic Container
          _buildWheelWithStand(slices),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWheelWithStand(List<CustomerSpinSlice> slices) {
    return Center(
      child: SizedBox(
        width: 320,
        height: 360,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // 3D Pedestal Stand at the Bottom
            Positioned(
              bottom: 10,
              child: Column(
                children: [
                  // Stand Neck (Dark Metallic Curved Neck)
                  Container(
                    width: 105,
                    height: 65,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF27272A), Color(0xFF18181B)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  // Stand Base Plate (Purple Rounded Oval Base)
                  Container(
                    width: 160,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9333EA),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9333EA).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Rotating Wheel Circle
            Positioned(
              top: 16,
              child: AnimatedBuilder(
                animation: _wheelAnimation,
                builder: (context, child) {
                  final rotationAngle = _isSpinning ? _wheelAnimation.value : _currentRotation;
                  return Transform.rotate(
                    angle: rotationAngle,
                    child: CustomPaint(
                      size: const Size(270, 270),
                      painter: _ReferenceWheelPainter(slices: slices),
                    ),
                  );
                },
              ),
            ),

            // Top Pointer Teardrop Pin (Pointing Down Over Top Rim)
            Positioned(
              top: 2,
              child: CustomPaint(
                size: const Size(26, 42),
                painter: _TeardropPointerPainter(),
              ),
            ),

            // Center Purple Circle Hub / Cap
            Positioned(
              top: 129,
              child: GestureDetector(
                onTap: _isSpinning ? null : _triggerSpin,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF9333EA),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    final remaining = _wheelData?.remainingSpinsToday ?? 0;
    final total = _wheelData?.maxSpinsPerDay ?? 1;

    String btnText = 'Spin $remaining/$total';
    if (remaining <= 0) {
      btnText = 'Out of Spins Today';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: (_isSpinning || remaining <= 0) ? null : _triggerSpin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9333EA),
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 4,
            shadowColor: const Color(0xFF9333EA).withValues(alpha: 0.35),
          ),
          child: _isSpinning
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  btnText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF1E1B4B), size: 22),
      ),
    );
  }
}

class _ReferenceWheelPainter extends CustomPainter {
  final List<CustomerSpinSlice> slices;

  _ReferenceWheelPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final rimThickness = 14.0;
    final innerRadius = outerRadius - rimThickness;

    final totalSlices = slices.length;
    final sweepAngle = (2 * math.pi) / totalSlices;

    // 1. Draw Outer Dark Frame/Rim
    final rimPaint = Paint()
      ..color = const Color(0xFF1F1F23)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius, rimPaint);

    // 2. Alternating Wedge Colors
    final purplePaint = Paint()..color = const Color(0xFF9333EA);
    final whitePaint = Paint()..color = Colors.white;

    for (int i = 0; i < totalSlices; i++) {
      final startAngle = (i * sweepAngle) - (math.pi / 2);
      final isPurple = (i % 2 == 0);

      // Wedge Arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        sweepAngle,
        true,
        isPurple ? purplePaint : whitePaint,
      );

      // Divider Line between slices
      final linePaint = Paint()
        ..color = const Color(0xFF1F1F23)
        ..strokeWidth = 2;
      final lineX = center.dx + innerRadius * math.cos(startAngle);
      final lineY = center.dy + innerRadius * math.sin(startAngle);
      canvas.drawLine(center, Offset(lineX, lineY), linePaint);

      // 3. Radial Text inside slice
      canvas.save();
      final textAngle = startAngle + (sweepAngle / 2);
      final textDistance = innerRadius * 0.62;
      final textX = center.dx + textDistance * math.cos(textAngle);
      final textY = center.dy + textDistance * math.sin(textAngle);

      canvas.translate(textX, textY);
      canvas.rotate(textAngle + (math.pi / 2));

      final item = slices[i];
      final titleText = item.title.isNotEmpty ? item.title : (item.icon.isNotEmpty ? item.icon : '🎁');

      final textSpan = TextSpan(
        text: titleText,
        style: TextStyle(
          color: isPurple ? Colors.white : const Color(0xFF18181B),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: 80);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ReferenceWheelPainter oldDelegate) => oldDelegate.slices != slices;
}

class _TeardropPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final radius = width / 2;

    // 1. Continuous Teardrop Map-Pin Path pointing DOWN
    final path = Path();
    // Top semicircle arc from left (-pi) through top (-pi/2) to right (0)
    path.arcTo(
      Rect.fromLTWH(0, 0, width, width),
      math.pi,
      math.pi,
      false,
    );
    // Straight line from right edge down to bottom center sharp point
    path.lineTo(radius, height);
    // Close back up to left edge
    path.close();

    // 2. Drop Shadow under pointer pin
    final shadowPath = path.shift(const Offset(0, 3));
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(shadowPath, shadowPaint);

    // 3. Main Pin Gradient Body (#C084FC -> #9333EA)
    final pinPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFC084FC), Color(0xFF9333EA)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(path, pinPaint);

    // 4. Subtle White Highlight Outline
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, borderPaint);

    // 5. Inner White Dot centered in upper bulb
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(radius, radius * 0.9), 3.6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
