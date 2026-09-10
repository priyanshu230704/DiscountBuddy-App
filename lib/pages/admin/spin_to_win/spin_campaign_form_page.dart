import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_typography.dart';
import '../../../models/admin/spin_campaign.dart';
import '../../../services/admin_service.dart';
import '../../../services/api_service.dart';

class SpinCampaignFormPage extends StatefulWidget {
  const SpinCampaignFormPage({super.key});

  @override
  State<SpinCampaignFormPage> createState() => _SpinCampaignFormPageState();
}

class _SpinCampaignFormPageState extends State<SpinCampaignFormPage> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();

  SpinCampaign? _editingCampaign;
  bool get isEditMode => _editingCampaign != null;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxSpinsController = TextEditingController(text: '1');
  bool _isActive = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is SpinCampaign) {
      _editingCampaign = args;
      _titleController.text = args.title;
      _descriptionController.text = args.description;
      _maxSpinsController.text = args.maxSpinsPerUserPerDay.toString();
      _isActive = args.isActive;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxSpinsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final maxSpins = int.tryParse(_maxSpinsController.text.trim()) ?? 1;

    try {
      if (isEditMode) {
        await _adminService.updateCampaign(
          _editingCampaign!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          isActive: _isActive,
          maxSpinsPerUserPerDay: maxSpins,
        );
        Get.back(result: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign updated successfully.')),
        );
      } else {
        await _adminService.createCampaign(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          isActive: _isActive,
          maxSpinsPerUserPerDay: maxSpins,
        );
        Get.back(result: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign created successfully.')),
        );
      }
    } catch (e) {
      setState(() {
        if (e is ApiException && e.message.isNotEmpty) {
          _errorMessage = e.message;
        } else {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        }
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isEditMode ? 'Edit Campaign Settings' : 'New Campaign',
          style: AppTypography.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Title
              Text('Campaign Title *', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('e.g. Mega Rewards Wheel'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              Text('Description', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration('Describe the campaign for users...'),
              ),
              const SizedBox(height: 16),

              // Max Spins Per Day
              Text('Max Spins Per User Per Day *', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _maxSpinsController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('e.g. 5'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Max spins is required';
                  final parsed = int.tryParse(val.trim());
                  if (parsed == null || parsed < 1) return 'Must be 1 or higher';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Active Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Is Active', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                    Switch.adaptive(
                      value: _isActive,
                      activeTrackColor: const Color(0xFFEC4899),
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditMode ? 'Save Settings' : 'Create Campaign',
                          style: AppTypography.title.copyWith(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEC4899), width: 1.5)),
    );
  }
}
