import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_typography.dart';
import '../../../models/restaurant.dart';
import '../../../services/admin_service.dart';
import '../../../services/api_service.dart';
import '../../../services/restaurant_service.dart';
import '../../../utils/date_time_utils.dart';

class NotificationComposePage extends StatefulWidget {
  const NotificationComposePage({super.key});

  @override
  State<NotificationComposePage> createState() => _NotificationComposePageState();
}

class _NotificationComposePageState extends State<NotificationComposePage> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  final RestaurantService _restaurantService = RestaurantService();
  final ImagePicker _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _promptController = TextEditingController();
  final _restaurantSearchController = TextEditingController();

  String _audience = 'all_customers';
  Restaurant? _selectedRestaurant;
  List<Restaurant> _restaurantResults = [];
  File? _imageFile;
  bool _isSubmitting = false;
  bool _isGenerating = false;
  bool _isSearching = false;
  bool _hasPrompt = false;
  bool _sendLater = false;
  DateTime? _scheduledAt;
  String? _errorMessage;

  bool get _needsRestaurant => _audience == 'restaurant_favourites';
  int? get _restaurantId =>
      _selectedRestaurant == null ? null : int.tryParse(_selectedRestaurant!.id);

  @override
  void initState() {
    super.initState();
    _promptController.addListener(() {
      final hasPrompt = _promptController.text.trim().isNotEmpty;
      if (hasPrompt != _hasPrompt) {
        setState(() => _hasPrompt = hasPrompt);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _promptController.dispose();
    _restaurantSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        setState(() => _imageFile = File(image.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  Future<void> _searchRestaurants(String query) async {
    setState(() => _isSearching = true);
    final results = await _restaurantService.getRestaurants(search: query, page: 1);
    if (!mounted) return;
    setState(() {
      _restaurantResults = results;
      _isSearching = false;
    });
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final initial = _scheduledAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await DateTimeUtils.showTimePicker24h(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _errorMessage = null;
    });
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() => _errorMessage = 'Enter a prompt first, then tap Generate.');
      return;
    }
    setState(() {
      _errorMessage = null;
      _isGenerating = true;
    });
    try {
      final copy = await _adminService.generateNotificationCopy(
        prompt: prompt,
        audience: _audience,
        restaurantId: _restaurantId,
      );
      if (!mounted) return;
      setState(() {
        if (copy['title']!.isNotEmpty) _titleController.text = copy['title']!;
        if (copy['body']!.isNotEmpty) _bodyController.text = copy['body']!;
        _isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is ApiException
            ? e.message
            : 'AI draft is unavailable. Type title and body and send manually.';
        _isGenerating = false;
      });
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_needsRestaurant && _selectedRestaurant == null) {
      setState(() => _errorMessage = 'Select a restaurant for favourites.');
      return;
    }

    DateTime? scheduledUtc;
    if (_sendLater) {
      if (_scheduledAt == null) {
        setState(() => _errorMessage = 'Pick a send date and time.');
        return;
      }
      scheduledUtc = DateTimeUtils.utcInstantFromRestaurantWallClock(
        year: _scheduledAt!.year,
        month: _scheduledAt!.month,
        day: _scheduledAt!.day,
        hour: _scheduledAt!.hour,
        minute: _scheduledAt!.minute,
      );
      if (!scheduledUtc.isAfter(DateTime.now().toUtc())) {
        setState(() => _errorMessage = 'Schedule time must be in the future.');
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await _adminService.sendNotificationCampaign(
        title: _titleController.text.trim(),
        message: _bodyController.text.trim(),
        audience: _audience,
        restaurantId: _selectedRestaurant == null ? null : int.tryParse(_selectedRestaurant!.id),
        imageFile: _imageFile,
        scheduledAt: scheduledUtc,
      );
      Get.back(result: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sendLater ? 'Notification scheduled.' : 'Notification queued.')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e is ApiException ? e.message : e.toString().replaceAll('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Compose notification',
          style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
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
              Text('Audience', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _audience,
                decoration: _inputDecoration('Select audience'),
                dropdownColor: AppColors.surface,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.normal),
                items: [
                  DropdownMenuItem(
                    value: 'all_customers',
                    child: Text('All customers', style: AppTypography.body.copyWith(fontWeight: FontWeight.normal)),
                  ),
                  DropdownMenuItem(
                    value: 'restaurant_favourites',
                    child: Text('Restaurant favourites', style: AppTypography.body.copyWith(fontWeight: FontWeight.normal)),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _audience = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                _needsRestaurant ? 'Restaurant (required)' : 'Restaurant (optional, for tap to open)',
                style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (_selectedRestaurant != null)
                InputDecorator(
                  decoration: _inputDecoration('').copyWith(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_selectedRestaurant!.name, style: AppTypography.body.copyWith(fontWeight: FontWeight.normal)),
                            if (_selectedRestaurant!.slug != null)
                              Text(_selectedRestaurant!.slug!, style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedRestaurant = null;
                        }),
                        child: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      ),
                    ],
                  ),
                )
              else
                TextField(
                  controller: _restaurantSearchController,
                  decoration: _inputDecoration('Search restaurant name'),
                  onChanged: (value) {
                    if (value.trim().length >= 2) {
                      _searchRestaurants(value.trim());
                    }
                  },
                ),
              if (_isSearching) const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              if (_selectedRestaurant == null && _restaurantResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: _restaurantResults.take(6).map(
                        (r) => InkWell(
                          onTap: () => setState(() {
                            _selectedRestaurant = r;
                            _restaurantResults = [];
                            _restaurantSearchController.clear();
                          }),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, style: AppTypography.body.copyWith(fontWeight: FontWeight.normal)),
                                const SizedBox(height: 2),
                                Text(r.address, style: AppTypography.bodySmall),
                              ],
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text('Write with AI (optional)', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Type a prompt, then tap Generate. Leave this empty to write title and body yourself.',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _promptController,
                minLines: 1,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.done,
                decoration: _inputDecoration('e.g. Diwali 20% off this weekend').copyWith(
                  suffixIcon: _hasPrompt
                      ? IconButton(
                          tooltip: 'Generate title and body',
                          onPressed: _isGenerating ? null : _generate,
                          icon: _isGenerating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome, color: AppColors.primary),
                        )
                      : null,
                ),
              ),
              if (_hasPrompt) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generate,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome, color: Colors.white),
                    label: const Text(
                      'Generate title and body',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Title', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                minLines: 1,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: _inputDecoration('Notification title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              Text('Body', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bodyController,
                minLines: 3,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: _inputDecoration('Notification body'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Body is required' : null,
              ),
              const SizedBox(height: 16),
              Text('Optional image', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(_imageFile != null ? 'Photo selected' : 'Pick photo'),
              ),
              if (_imageFile != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_imageFile!, height: 130, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Send later', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            'UK time (Europe/London)',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _sendLater,
                      onChanged: (value) {
                        setState(() {
                          _sendLater = value;
                          if (value && _scheduledAt == null) {
                            _scheduledAt = DateTime.now().add(const Duration(hours: 1));
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (_sendLater) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickSchedule,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: _inputDecoration('Pick date and time'),
                    child: Text(
                      _scheduledAt == null
                          ? 'Pick date and time'
                          : '${DateTimeUtils.formatDateOnly(_scheduledAt!)}, ${DateTimeUtils.formatTimeOfDay24h(TimeOfDay.fromDateTime(_scheduledAt!))}',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.normal,
                        color: _scheduledAt == null ? AppColors.textSecondary : null,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _sendLater ? 'Schedule notification' : 'Send notification',
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
}
