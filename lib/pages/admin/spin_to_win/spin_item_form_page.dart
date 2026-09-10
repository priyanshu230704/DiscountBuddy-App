import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_typography.dart';
import '../../../models/admin/spin_item.dart';
import '../../../services/admin_service.dart';
import '../../../services/api_service.dart';

class SpinItemFormPage extends StatefulWidget {
  const SpinItemFormPage({super.key});

  @override
  State<SpinItemFormPage> createState() => _SpinItemFormPageState();
}

class _SpinItemFormPageState extends State<SpinItemFormPage> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  final ImagePicker _picker = ImagePicker();

  SpinItem? _editingItem;
  bool get isEditMode => _editingItem != null;

  int _campaignId = 0;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconController = TextEditingController(text: '🎁');
  final _promoCodeController = TextEditingController();
  final _discountController = TextEditingController();
  final _minSpinsController = TextEditingController(text: '0');
  final _stockLimitController = TextEditingController();
  final _weightController = TextEditingController(text: '10');
  final _sliceIndexController = TextEditingController(text: '0');

  SpinItemType _selectedType = SpinItemType.promocode;
  bool _isActive = true;
  File? _selectedImageFile;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is SpinItem) {
      _editingItem = args;
      _campaignId = args.campaign;
      _titleController.text = args.title;
      _descriptionController.text = args.description;
      _iconController.text = args.icon;
      _selectedType = args.itemType;
      _promoCodeController.text = args.promoCodeValue;
      _discountController.text = args.discountPercentage?.toString() ?? '';
      _minSpinsController.text = args.minSpinsBeforeWin.toString();
      _stockLimitController.text = args.stockLimit?.toString() ?? '';
      _weightController.text = args.probabilityWeight.toString();
      _sliceIndexController.text = args.sliceIndex.toString();
      _isActive = args.isActive;
    } else if (args is Map && args['campaignId'] != null) {
      _campaignId = args['campaignId'] as int;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
    _promoCodeController.dispose();
    _discountController.dispose();
    _minSpinsController.dispose();
    _stockLimitController.dispose();
    _weightController.dispose();
    _sliceIndexController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final discount = double.tryParse(_discountController.text.trim());
    final minSpins = int.tryParse(_minSpinsController.text.trim()) ?? 0;
    final stockLimit = int.tryParse(_stockLimitController.text.trim());
    final weight = int.tryParse(_weightController.text.trim()) ?? 10;
    final sliceIndex = int.tryParse(_sliceIndexController.text.trim()) ?? 0;

    try {
      if (isEditMode) {
        await _adminService.updateItem(
          _editingItem!.id,
          campaignId: _campaignId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          icon: _iconController.text.trim(),
          imageFile: _selectedImageFile,
          itemType: _selectedType,
          promoCodeValue: _promoCodeController.text.trim(),
          discountPercentage: discount,
          minSpinsBeforeWin: minSpins,
          stockLimit: stockLimit,
          probabilityWeight: weight,
          sliceIndex: sliceIndex,
          isActive: _isActive,
        );
        Get.back(result: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wheel slice item updated.')),
        );
      } else {
        await _adminService.createItem(
          campaignId: _campaignId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          icon: _iconController.text.trim(),
          imageFile: _selectedImageFile,
          itemType: _selectedType,
          promoCodeValue: _promoCodeController.text.trim(),
          discountPercentage: discount,
          minSpinsBeforeWin: minSpins,
          stockLimit: stockLimit,
          probabilityWeight: weight,
          sliceIndex: sliceIndex,
          isActive: _isActive,
        );
        Get.back(result: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wheel slice item added.')),
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
          isEditMode ? 'Edit Wheel Slice' : 'Add Wheel Slice',
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
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
              ],

              // Item Type Dropdown
              Text('Slice Type *', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<SpinItemType>(
                initialValue: _selectedType,
                decoration: _inputDecoration('Select item type'),
                items: SpinItemType.values.map((type) {
                  String label = type.name;
                  if (type == SpinItemType.empty) label = 'empty (Try Again / Lose)';
                  return DropdownMenuItem(value: type, child: Text(label.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Title
              Text('Slice Title *', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('e.g. 50% OFF Promo Code or Try Again'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Icon Emoji & Image Upload
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Icon *', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _iconController,
                          decoration: _inputDecoration('🎁'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Slice Image (Optional)', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image_rounded, size: 18),
                          label: Text(_selectedImageFile != null ? 'Selected' : 'Pick Image'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_selectedImageFile != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_selectedImageFile!, height: 80, width: 80, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 16),

              // Promo code & discount
              if (_selectedType == SpinItemType.promocode || _selectedType == SpinItemType.discount) ...[
                Text('Promo Code / Reward Text', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _promoCodeController,
                  decoration: _inputDecoration('e.g. Use promo code MEGA50 for 50% OFF'),
                ),
                const SizedBox(height: 16),
                if (_selectedType == SpinItemType.discount) ...[
                  Text('Discount Percentage (%)', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('e.g. 50.0'),
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              // Win conditions: Min spins before win, Stock limit
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Min Spins Before Win', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _minSpinsController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('0'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stock Limit (blank = ∞)', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _stockLimitController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('e.g. 10'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weight & Slice Index
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Probability Weight *', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('10'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Slice Index *', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _sliceIndexController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('0'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Active switch
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
                      activeTrackColor: AppColors.primary,
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
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditMode ? 'Save Wheel Slice' : 'Add Wheel Slice',
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
