import 'package:discount_buddy/design/app_colors.dart';
import '../design/app_spacing.dart';
import '../design/app_typography.dart';
import '../components/buttons.dart';
import '../components/inputs.dart';
import '../providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/app_scaffold.dart';
import '../widgets/app_gradient_button.dart';
import '../components/app_app_bar.dart';

/// Edit Profile Screen
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final AuthProvider _authProvider = AuthProvider();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = _authProvider.user;
    _userNameController.text = user?.username ?? '';
    _emailController.text = user?.email ?? '';
  }

  String _getInitials() {
    final name = _userNameController.text.trim();
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '?';
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _authProvider.updateProfile(
        firstName: _userNameController.text.trim(),
        lastName: '',
        email: _emailController.text.trim(),
        imageFile: _image,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully', style: AppTypography.body),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _authProvider.errorMessage ?? 'Failed to update profile',
              style: AppTypography.body,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile', style: AppTypography.body),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: 'Edit profile',
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xxxl),
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppColors.purpleGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _image != null
                            ? Image.file(
                                _image!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                            : (_authProvider.user?.profilePicture != null
                                ? Image.network(
                                    _authProvider.user!.profilePicture!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Text(
                                        _getInitials(),
                                        style: AppTypography.headline.copyWith(
                                          fontSize: 48,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _getInitials(),
                                      style: AppTypography.headline.copyWith(
                                        fontSize: 48,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  )),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: AppColors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xxxl),
              _buildTextField(
                label: 'User name',
                controller: _userNameController,
                onChanged: (value) => setState(() {}),
              ),
              SizedBox(height: AppSpacing.lg),
              _buildTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
              ),
              SizedBox(height: AppSpacing.xxxl),
              AppGradientButton(
                text: 'Save',
                onPressed: _saveProfile,
                isLoading: _isLoading,
              ),
              SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    bool readOnly = false,
  }) {
    return AppTextField(
      controller: controller,
      label: label,
      keyboardType: keyboardType,
      onChanged: onChanged,
      readOnly: readOnly,
    );
  }
}
