import 'dart:io';
import 'package:flutter/material.dart';
import '../../design/app_colors.dart';
import '../../design/app_typography.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/mystery_visit.dart';
import '../../services/mystery_guest_service.dart';

class MysteryAuditModal extends StatefulWidget {
  final MysteryVisit visit;
  final Function(MysteryVisit) onUpdate;

  const MysteryAuditModal({
    super.key,
    required this.visit,
    required this.onUpdate,
  });

  @override
  State<MysteryAuditModal> createState() => _MysteryAuditModalState();
}

class _MysteryAuditModalState extends State<MysteryAuditModal> {
  final MysteryGuestService _mysteryService = MysteryGuestService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  late MysteryVisit _currentVisit;

  // Scores (0-10)
  int _preVisitScore = 8;
  int _ambienceScore = 8;
  int _serviceScore = 8;
  int _foodScore = 8;
  int _discountScore = 8;
  int _hygieneScore = 8;

  // Comments
  final TextEditingController _preVisitComment = TextEditingController();
  final TextEditingController _ambienceComment = TextEditingController();
  final TextEditingController _serviceComment = TextEditingController();
  final TextEditingController _foodComment = TextEditingController();
  final TextEditingController _discountComment = TextEditingController();
  final TextEditingController _hygieneComment = TextEditingController();
  final TextEditingController _overallComment = TextEditingController();

  bool _isRiskFlagged = false;

  @override
  void initState() {
    super.initState();
    _currentVisit = widget.visit;
    // Load existing scores if in progress
    // In a real app, we'd fetch these from the API or local storage
  }

  Future<void> _startVisit() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _mysteryService.startVisit(_currentVisit.id);
      setState(() {
        _currentVisit = updated;
        _isLoading = false;
      });
      widget.onUpdate(updated);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start visit: $e')));
    }
  }

  Future<void> _pickAndUploadEvidence() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      await _mysteryService.uploadEvidence(
        visitId: _currentVisit.id,
        file: File(image.path),
        description: 'Mystery Guest Evidence',
      );
      // Reload visit to see new evidence
      final updated = await _mysteryService.getVisitDetail(_currentVisit.id);
      setState(() {
        _currentVisit = updated;
        _isLoading = false;
      });
      widget.onUpdate(updated);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _submitReport() async {
    setState(() => _isLoading = true);
    try {
      final report = {
        'pre_visit_score': _preVisitScore,
        'pre_visit_comment': _preVisitComment.text,
        'ambience_score': _ambienceScore,
        'ambience_comment': _ambienceComment.text,
        'service_score': _serviceScore,
        'service_comment': _serviceComment.text,
        'food_score': _foodScore,
        'food_comment': _foodComment.text,
        'discount_experience_score': _discountScore,
        'discount_experience_comment': _discountComment.text,
        'hygiene_score': _hygieneScore,
        'hygiene_comment': _hygieneComment.text,
        'is_risk_flagged': _isRiskFlagged,
        'comments': _overallComment.text,
      };

      final updated = await _mysteryService.submitVisit(
        id: _currentVisit.id,
        reportData: report,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onUpdate(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audit submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mystery Guest Audit',
                    style: AppTypography.body.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _currentVisit.status == 'assigned'
                    ? _buildStartScreen()
                    : _buildAuditForm(),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: AppColors.white.withValues(alpha: 0.6),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.psychology, size: 80, color: AppColors.primary),
        const SizedBox(height: 24),
        Text(
          'Anonymous Audit',
          style: AppTypography.body.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Once you start the audit, your status will change to "In Progress". Please ensure you are at the location and ready to evaluate.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _startVisit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Start Audit Now',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditForm() {
    return ListView(
      children: [
        _buildSectionHeader('Pre-Visit Experience'),
        _buildScoreCounter(
          _preVisitScore,
          (val) => setState(() => _preVisitScore = val),
        ),
        _buildCommentField(
          _preVisitComment,
          'Comment on booking/app experience...',
        ),

        _buildSectionHeader('Ambience & Environment'),
        _buildScoreCounter(
          _ambienceScore,
          (val) => setState(() => _ambienceScore = val),
        ),
        _buildCommentField(
          _ambienceComment,
          'Comment on decor, lighting, music...',
        ),

        _buildSectionHeader('Service Quality'),
        _buildScoreCounter(
          _serviceScore,
          (val) => setState(() => _serviceScore = val),
        ),
        _buildCommentField(
          _serviceComment,
          'Comment on staff friendliness, speed...',
        ),

        _buildSectionHeader('Food & Drink'),
        _buildScoreCounter(
          _foodScore,
          (val) => setState(() => _foodScore = val),
        ),
        _buildCommentField(_foodComment, 'Comment on taste, presentation...'),

        _buildSectionHeader('Discount Experience'),
        _buildScoreCounter(
          _discountScore,
          (val) => setState(() => _discountScore = val),
        ),
        _buildCommentField(
          _discountComment,
          'How smooth was the QR code redemption?',
        ),

        _buildSectionHeader('Hygiene & Safety'),
        _buildScoreCounter(
          _hygieneScore,
          (val) => setState(() => _hygieneScore = val),
        ),
        _buildCommentField(
          _hygieneComment,
          'Cleanliness of tables, washrooms...',
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('Evidence (Upload Photos)'),
        Wrap(
          spacing: 8,
          children: [
            ..._currentVisit.evidence.map(
              (e) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.textDisabled),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(e.fileUrl, fit: BoxFit.cover),
                ),
              ),
            ),
            GestureDetector(
              onTap: _pickAndUploadEvidence,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.textDisabled,
                    style: BorderStyle.none,
                  ),
                ),
                child: const Icon(Icons.add_a_photo, color: AppColors.textDisabled),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('Final Thoughts'),
        _buildCommentField(_overallComment, 'Any other feedback?'),

        SwitchListTile(
          title: Text(
            'Flag for Risk?',
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
          subtitle: const Text(
            'Something major was wrong (e.g., safety, fraud)',
          ),
          value: _isRiskFlagged,
          onChanged: (val) => setState(() => _isRiskFlagged = val),
          activeThumbColor: AppColors.error,
        ),

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _submitReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Submit Report',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildScoreCounter(int score, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: score > 0 ? () => onChanged(score - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Container(
          width: 60,
          alignment: Alignment.center,
          child: Text(
            '$score/10',
            style: AppTypography.body.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: score < 10 ? () => onChanged(score + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _buildCommentField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: controller,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: hint,
          fillColor: AppColors.background,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.textDisabled),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.textDisabled),
          ),
        ),
        style: AppTypography.body.copyWith(fontSize: 14),
      ),
    );
  }
}
