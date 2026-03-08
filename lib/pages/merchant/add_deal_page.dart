import 'package:discount_buddy/theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/merchant_service.dart';
import '../../widgets/auth/auth_text_field.dart';

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
      appBar: AppBar(
        title: Text(
          widget.deal != null ? 'Edit Deal' : 'Create Deal',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Select Restaurant *'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _selectedRestaurantId,
                          items: _myRestaurants.map((r) {
                            return DropdownMenuItem<int>(
                              value: r['id'],
                              child: Text(r['name']),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedRestaurantId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _titleController,
                      placeholder: 'Deal Title *',
                      validator: (v) => v!.isEmpty ? 'Title required' : null,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _descriptionController,
                      placeholder: 'Description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Deal Type'),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTypeChip('percentage', 'Percentage'),
                          const SizedBox(width: 8),
                          _buildTypeChip('fixed', 'Fixed Amount'),
                          const SizedBox(width: 8),
                          _buildTypeChip('two_for_one', '2 for 1'),
                        ],
                      ),
                    ),
                    if (_dealType != 'two_for_one') ...[
                      const SizedBox(height: 16),
                      AuthTextField(
                        controller: _discountController,
                        placeholder: _dealType == 'percentage'
                            ? 'Discount %'
                            : 'Discount Amount',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _minSpendController,
                      placeholder: 'Minimum Spend (e.g. 30.00)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePicker(
                            'Start Date',
                            _startDate,
                            true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDatePicker('End Date', _endDate, false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AuthTextField(
                            controller: _maxUsesController,
                            placeholder: 'Max Total Uses',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AuthTextField(
                            controller: _maxPerUserController,
                            placeholder: 'Max Per User',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _termsController,
                      placeholder: 'Terms & Conditions',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Featured Deal'),
                      value: _isFeatured,
                      onChanged: (v) => setState(() => _isFeatured = v),
                      activeThumbColor: AppColors.accent,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveDeal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator()
                            : Text(
                                widget.deal != null
                                    ? 'Update Deal'
                                    : 'Create Deal',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
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
      labelStyle: TextStyle(
        color: selected ? AppColors.accent : Colors.black,
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, bool isStart) {
    return InkWell(
      onTap: () => _selectDate(context, isStart),
      child: Container(
        padding: const EdgeInsets.all(12),
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
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              date == null
                  ? 'Select Date'
                  : '${date.day}/${date.month}/${date.year}',
            ),
          ],
        ),
      ),
    );
  }
}
