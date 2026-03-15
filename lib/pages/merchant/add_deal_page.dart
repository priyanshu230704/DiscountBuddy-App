import 'package:flutter/material.dart';
import 'package:discount_buddy/theme/app_colors.dart';
import 'package:discount_buddy/design/app_spacing.dart';
import 'package:discount_buddy/design/app_typography.dart';
import 'package:discount_buddy/components/inputs.dart';
import 'package:discount_buddy/components/buttons.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import '../../services/merchant_service.dart';

/// Add/Edit Deal Page for Merchants
class AddDealPage extends StatefulWidget {
  final Map<String, dynamic>? deal;
  const AddDealPage({super.key, this.deal});

  @override
  State<AddDealPage> createState() => _AddDealPageState();
}

class _AddDealPageState extends State<AddDealPage> {
  final MerchantService _merchantService = MerchantService();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _minSpendController = TextEditingController();
  final _maxUsesController = TextEditingController();
  final _maxPerUserController = TextEditingController();
  final _termsController = TextEditingController();

  List<Map<String, dynamic>> _myRestaurants = [];
  int? _selectedRestaurantId;
  String _dealType = 'percentage';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFeatured = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final restaurants = await _merchantService.getMerchantRestaurants();
      setState(() {
        _myRestaurants = restaurants;
        if (restaurants.isNotEmpty) {
          _selectedRestaurantId = restaurants.first['id'];
        }
        _isLoading = false;
      });

      if (widget.deal != null) {
        _loadDealData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load restaurants: ${e.toString()}'),
          ),
        );
      }
    }
  }

  void _loadDealData() {
    final deal = widget.deal!;
    _titleController.text = deal['title'] ?? '';
    _descriptionController.text = deal['description'] ?? '';
    _dealType = deal['deal_type'] ?? 'percentage';
    _discountController.text =
        deal['discount_percentage']?.toString() ??
        deal['discount_amount']?.toString() ??
        '';
    _minSpendController.text = deal['minimum_spend']?.toString() ?? '';
    _maxUsesController.text = deal['max_uses']?.toString() ?? '';
    _maxPerUserController.text = deal['max_per_user']?.toString() ?? '';
    _termsController.text = deal['terms_and_conditions'] ?? '';
    _isFeatured = deal['is_featured'] ?? false;
    _selectedRestaurantId = deal['restaurant']['id'];

    if (deal['start_date'] != null) {
      _startDate = DateTime.parse(deal['start_date']);
    }
    if (deal['end_date'] != null) {
      _endDate = DateTime.parse(deal['end_date']);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveDeal() async {
    if (!_formKey.currentState!.validate() || _selectedRestaurantId == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dealData = {
        'restaurant': _selectedRestaurantId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'deal_type': _dealType,
        if (_dealType == 'percentage')
          'discount_percentage': double.tryParse(_discountController.text),
        if (_dealType == 'fixed')
          'discount_amount': double.tryParse(_discountController.text),
        'minimum_spend': _minSpendController.text.trim(),
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'max_uses': int.tryParse(_maxUsesController.text),
        'max_per_user': int.tryParse(_maxPerUserController.text) ?? 1,
        'terms_and_conditions': _termsController.text.trim(),
        'is_featured': _isFeatured,
      };

      if (widget.deal != null) {
        await _merchantService.updateDeal(widget.deal!['id'], dealData);
      } else {
        await _merchantService.createDeal(dealData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deal saved successfully'),
            backgroundColor: AppColors.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save deal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        titleText: widget.deal != null ? 'Edit deal' : 'Create deal',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Select Restaurant *'),
                    AppDropdown<int>(
                      value: _selectedRestaurantId,
                      label: 'Restaurant *',
                      items: _myRestaurants
                          .map(
                            (r) => DropdownMenuItem<int>(
                              value: r['id'] as int,
                              child: Text(r['name'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedRestaurantId = val),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _titleController,
                      label: 'Deal title *',
                      validator: (v) => v!.isEmpty ? 'Title required' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildLabel('Deal Type'),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTypeChip('percentage', 'Percentage'),
                          const SizedBox(width: AppSpacing.sm),
                          _buildTypeChip('fixed', 'Fixed Amount'),
                          const SizedBox(width: AppSpacing.sm),
                          _buildTypeChip('two_for_one', '2 for 1'),
                        ],
                      ),
                    ),
                    if (_dealType != 'two_for_one') ...[
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        controller: _discountController,
                        label: _dealType == 'percentage'
                            ? 'Discount %'
                            : 'Discount amount',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _minSpendController,
                      label: 'Minimum spend (e.g. 30.00)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePicker(
                            'Start Date',
                            _startDate,
                            true,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: _buildDatePicker('End Date', _endDate, false),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _maxUsesController,
                            label: 'Max total uses',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: AppTextField(
                            controller: _maxPerUserController,
                            label: 'Max per user',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _termsController,
                      label: 'Terms & Conditions',
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SwitchListTile(
                      title: const Text('Featured Deal'),
                      value: _isFeatured,
                      onChanged: (v) => setState(() => _isFeatured = v),
                      activeThumbColor: AppColors.accent,
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    PrimaryButton(
                      label: widget.deal != null ? 'Update deal' : 'Create deal',
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _saveDeal,
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        left: 4,
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final selected = _dealType == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (s) => setState(() => _dealType = type),
      selectedColor: AppColors.accent.withValues(alpha: 0.2),
      labelStyle: AppTypography.bodySmall.copyWith(
        color: selected ? AppColors.accent : Colors.black,
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, bool isStart) {
    return InkWell(
      onTap: () => _selectDate(context, isStart),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption,
            ),
            Text(
              date == null
                  ? 'Select Date'
                  : '${date.day}/${date.month}/${date.year}',
              style: AppTypography.body,
            ),
          ],
        ),
      ),
    );
  }
}
