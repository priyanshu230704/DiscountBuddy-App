import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_gradient_button.dart';
import '../../components/app_app_bar.dart';
import '../../components/inputs.dart';
import '../../services/merchant_service.dart';
import 'package:intl/intl.dart';

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
  final _shortDescriptionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _comboPriceController = TextEditingController();
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
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _loadDealData() {
    final deal = widget.deal!;
    _titleController.text = deal['title'] ?? '';
    _shortDescriptionController.text = deal['short_description'] ?? '';
    _descriptionController.text = deal['description'] ?? '';
    _dealType = deal['deal_type'] ?? 'percentage';
    _discountController.text =
        deal['discount_percentage']?.toString() ??
        deal['discount_amount']?.toString() ??
        '';
    _comboPriceController.text = deal['combo_price']?.toString() ?? '';
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
      initialDate: isStart 
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? (_startDate ?? DateTime.now())),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.merchantIndigo,
              onPrimary: Colors.white,
              onSurface: AppColors.textDarkest,
            ),
          ),
          child: child!,
        );
      },
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all required fields.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dealData = {
        'restaurant': _selectedRestaurantId,
        'title': _titleController.text.trim(),
        'short_description': _shortDescriptionController.text.trim(),
        'description': _descriptionController.text.trim(),
        'deal_type': _dealType,
        if (_dealType == 'percentage')
          'discount_percentage': double.tryParse(_discountController.text),
        if (_dealType == 'fixed')
          'discount_amount': double.tryParse(_discountController.text),
        if (_dealType == 'combo')
          'combo_price': double.tryParse(_comboPriceController.text),
        'minimum_spend': _dealType == 'combo' ? '' : _minSpendController.text.trim(),
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
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save deal: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: widget.deal != null ? 'Edit Deal' : 'Create Deal',
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.merchantIndigo),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader('Basic Details', Icons.info_outline_rounded),
                    const SizedBox(height: AppSpacing.md),
                    _buildFormSection(
                      children: [
                        _buildLabel('Select Restaurant *'),
                        AppDropdown<int>(
                          value: _selectedRestaurantId,
                          label: 'Restaurant *',
                          items: _myRestaurants
                              .map(
                                (r) => DropdownMenuItem<int>(
                                  value: r['id'] as int,
                                  child: Text(r['name'] as String, style: AppTypography.body),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedRestaurantId = val),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          controller: _titleController,
                          label: 'Deal Title *',
                          hintText: 'e.g. 50% Off Burgers',
                          validator: (v) => v!.isEmpty ? 'Title required' : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          hintText: 'Explain the details of this deal to your customers...',
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          controller: _shortDescriptionController,
                          label: 'Short Description (Two Words) *',
                          hintText: 'e.g. Save Today',
                          validator: (v) => v!.isEmpty ? 'Short description required' : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Deal Configuration', Icons.local_offer_outlined),
                    const SizedBox(height: AppSpacing.md),
                    _buildFormSection(
                      children: [
                        _buildLabel('Deal Type *'),
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildTypeChip('percentage', 'Percentage', Icons.percent_rounded)),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(child: _buildTypeChip('fixed', 'Fixed Amount', Icons.currency_pound_rounded)),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Expanded(child: _buildTypeChip('combo', 'Combo Deal', Icons.fastfood_rounded)),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(child: _buildTypeChip('two_for_one', '2-for-1', Icons.people_alt_rounded)),
                              ],
                            ),
                          ],
                        ),
                        if (_dealType == 'percentage' || _dealType == 'fixed') ...[
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            controller: _discountController,
                            label: _dealType == 'percentage'
                                ? 'Discount Percentage (%) *'
                                : 'Discount Amount (£)',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => v!.isEmpty 
                                ? 'Value required' 
                                : null,
                          ),
                        ],
                        if (_dealType == 'combo') ...[
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            controller: _comboPriceController,
                            label: 'Combo Price (£) *',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => _dealType == 'combo' && v!.isEmpty 
                                ? 'Combo price required' 
                                : null,
                          ),
                        ],
                        if (_dealType != 'combo') ...[
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            controller: _minSpendController,
                            label: 'Minimum Spend required (Optional)',
                            hintText: 'e.g. 30.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Usage & Restrictions', Icons.rule_rounded),
                    const SizedBox(height: AppSpacing.md),
                    _buildFormSection(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePicker('Valid From', _startDate, true),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: _buildDatePicker('Valid Until', _endDate, false),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _maxUsesController,
                                label: 'Max Total Uses',
                                hintText: 'Leave empty for unlimited',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: AppTextField(
                                controller: _maxPerUserController,
                                label: 'Max Per User',
                                hintText: 'Default is 1',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          controller: _termsController,
                          label: 'Terms & Conditions',
                          hintText: 'e.g. Valid only for dine-in. Not valid with other promos.',
                          maxLines: 3,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    _buildFormSection(
                      padding: const EdgeInsets.all(8),
                      children: [
                        SwitchListTile(
                          title: Text(
                            'Featured Deal',
                            style: AppTypography.title.copyWith(fontSize: 16),
                          ),
                          subtitle: Text('Highlight this deal at the top of your page', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                          value: _isFeatured,
                          onChanged: (v) => setState(() => _isFeatured = v),
                          activeThumbColor: AppColors.merchantIndigo,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xxxl),
                    AppGradientButton(
                      onPressed: _isSaving ? null : _saveDeal,
                      isLoading: _isSaving,
                      child: Text(widget.deal != null ? 'Save Changes' : 'Create Deal'),
                    ),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.merchantIndigo),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.title.copyWith(fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildFormSection({
    required List<Widget> children,
    EdgeInsets padding = const EdgeInsets.all(AppSpacing.xl),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDarkest.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final selected = _dealType == type;
    return GestureDetector(
      onTap: () => setState(() => _dealType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.merchantIndigo : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.merchantIndigo : AppColors.cardBorder,
            width: 1,
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: AppColors.merchantIndigo.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 16, 
              color: selected ? AppColors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: selected ? AppColors.white : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        InkWell(
          onTap: () => _selectDate(context, isStart),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: date == null ? AppColors.textDisabled : AppColors.merchantIndigo,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date == null
                        ? 'Select Date'
                        : DateFormat('MMM d, yyyy').format(date),
                    style: AppTypography.body.copyWith(
                      color: date == null ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
