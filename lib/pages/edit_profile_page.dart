import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_gradient_button.dart';
import '../components/app_app_bar.dart';
import '../components/inputs.dart';
import '../providers/auth_provider.dart';
import '../design/app_avatars.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  String? _selectedAvatarUrl;
  late PageController _pageController;
  final List<String> _customAvatars = [];

  List<String> get _presetAvatars => AppAvatars.presetAvatars;
  List<String> get _allAvatars => [..._presetAvatars, ..._customAvatars];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Initialize avatar selection
    final userProfilePic = _authProvider.user?.profilePicture;
    int initialPage = _presetAvatars.length ~/ 2;
    
    if (userProfilePic != null && userProfilePic.isNotEmpty) {
      if (!_presetAvatars.contains(userProfilePic)) {
        _customAvatars.add(userProfilePic);
      }
      _selectedAvatarUrl = userProfilePic;
      initialPage = _allAvatars.indexOf(userProfilePic);
      if (initialPage == -1) initialPage = 0;
    } else if (_presetAvatars.isNotEmpty) {
      _selectedAvatarUrl = _presetAvatars[initialPage];
    }
    
    _pageController = PageController(
      viewportFraction: 0.35,
      initialPage: initialPage,
    );
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = _authProvider.user;
    _userNameController.text = user?.username ?? '';
    _emailController.text = user?.email ?? '';
  }


  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _authProvider.updateProfile(
        username: _userNameController.text.trim(),
        firstName: _userNameController.text.trim(),
        lastName: '',
        email: _emailController.text.trim(),
        avatarUrl: _selectedAvatarUrl,
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
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Select Your Avatar',
                style: AppTypography.title.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Avatar selection with swipeable carousel
              LayoutBuilder(
                builder: (context, constraints) {
                  const viewportFraction = 0.35;
                  final containerSize = constraints.maxWidth * viewportFraction;

                  return SizedBox(
                    height: containerSize + 40,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _selectedAvatarUrl = _allAvatars[index];
                        });
                      },
                      itemCount: _allAvatars.length,
                      itemBuilder: (context, index) {
                        final avatarUrl = _allAvatars[index];
                        final isSelected = _selectedAvatarUrl == avatarUrl;

                        return Center(
                          child: GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            child: AnimatedScale(
                              scale: isSelected ? 1.0 : 0.7,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              child: AnimatedOpacity(
                                opacity: isSelected ? 1.0 : 0.4,
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  width: containerSize,
                                  height: containerSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: AppColors.primary,
                                            width: 3,
                                          )
                                        : null,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withOpacity(0.4),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                    child: ClipOval(
                                      child: avatarUrl.startsWith('assets/')
                                          ? Image.asset(
                                              avatarUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: AppColors.cardBorder,
                                                child: const Icon(Icons.person, color: AppColors.textDisabled),
                                              ),
                                            )
                                          : CachedNetworkImage(
                                              imageUrl: avatarUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Center(
                                                child: CircularProgressIndicator(
                                                  color: AppColors.primary,
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: AppColors.cardBorder,
                                                child: const Icon(Icons.person, color: AppColors.textDisabled),
                                              ),
                                            ),
                                    ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xxxl),
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
                onPressed: _saveProfile,
                isLoading: _isLoading,
                child: const Text('Save'),
              ),
              SizedBox(height: AppSpacing.xxxl),
            ],
          ),
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
