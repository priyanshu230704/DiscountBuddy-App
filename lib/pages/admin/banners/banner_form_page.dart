import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_typography.dart';
import '../../../models/admin/app_banner.dart';
import '../../../services/admin_service.dart';
import '../../../services/api_service.dart';

class BannerFormPage extends StatefulWidget {
  const BannerFormPage({super.key});

  @override
  State<BannerFormPage> createState() => _BannerFormPageState();
}

class _BannerFormPageState extends State<BannerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  final ImagePicker _picker = ImagePicker();

  AppBanner? _editingBanner;
  bool get isEditMode => _editingBanner != null;

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _ctaUrlController = TextEditingController();
  final _priorityController = TextEditingController(text: '0');

  bool _isVisible = true;
  File? _selectedImageFile;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is AppBanner) {
      _editingBanner = args;
      _titleController.text = args.title ?? '';
      _bodyController.text = args.body ?? '';
      _ctaUrlController.text = args.ctaUrl;
      _priorityController.text = args.priority.toString();
      _isVisible = args.isVisible;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _ctaUrlController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
      }
    } catch (e) {
      Get.snackbar('Image Error', 'Could not pick image: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final priority = int.tryParse(_priorityController.text.trim()) ?? 0;
    final ctaUrl = _ctaUrlController.text.trim();
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    try {
      if (isEditMode) {
        await _adminService.updateBanner(
          _editingBanner!.id,
          title: title.isNotEmpty ? title : null,
          body: body.isNotEmpty ? body : null,
          ctaUrl: ctaUrl,
          priority: priority,
          isVisible: _isVisible,
          imageFile: _selectedImageFile,
        );
        Get.back(result: true);
        Get.snackbar('Success', 'Banner updated successfully.');
      } else {
        await _adminService.createBanner(
          title: title.isNotEmpty ? title : null,
          body: body.isNotEmpty ? body : null,
          ctaUrl: ctaUrl,
          priority: priority,
          isVisible: _isVisible,
          imageFile: _selectedImageFile,
        );
        Get.back(result: true);
        Get.snackbar('Success', 'Banner created successfully.');
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
    final existingImg = _editingBanner?.displayImage;

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
          isEditMode ? 'Edit Banner' : 'Create Banner',
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
              Text('Banner Title', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Enter banner title (e.g. Weekend Deals)'),
              ),
              const SizedBox(height: 16),

              // Body
              Text('Body Description', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bodyController,
                maxLines: 2,
                decoration: _inputDecoration('Enter promo description (e.g. Up to 50% off)'),
              ),
              const SizedBox(height: 20),

              // CTA URL
              Text('CTA Tap Link (cta_url)', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'https://... (external URL), in-app route e.g. /restaurants/tasty-bites, or leave empty for no tap.',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _ctaUrlController,
                decoration: _inputDecoration('https://example.com/deals or /restaurants/slug'),
              ),
              const SizedBox(height: 20),

              // Image Selection Section
              Text('Banner Image', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library_rounded),
                      label: Text(_selectedImageFile != null ? 'New Photo Selected' : 'Pick Photo File'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: _selectedImageFile != null ? AppColors.primary : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedImageFile != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImageFile!, height: 130, width: double.infinity, fit: BoxFit.cover),
                ),
              ] else if (existingImg != null && existingImg.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(imageUrl: existingImg, height: 130, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 20),

              // Priority
              Text('Priority (Higher = First)', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priorityController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('10'),
              ),
              const SizedBox(height: 16),

              // Is Visible Switch
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
                    Text('Is Visible', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                    Switch.adaptive(
                      value: _isVisible,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) => setState(() => _isVisible = val),
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
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditMode ? 'Save Banner Changes' : 'Create Banner',
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }
}
