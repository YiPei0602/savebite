import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/status_modal.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

/// Signup Screen
/// 
/// Allows new users to create an account and select their role (Consumer or Merchant only).
/// Follows iOS Human Interface Guidelines with modern, clean UI.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedRole; // null initially, user must select
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get role from query parameters and pre-select
    final uri = GoRouterState.of(context).uri;
    final roleParam = uri.queryParameters['role'];
    if (roleParam == 'consumer') {
      _selectedRole = AppConstants.roleConsumer;
    } else if (roleParam == 'merchant') {
      _selectedRole = AppConstants.roleMerchant;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _selectedRole != null &&
        _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Convert role string to UserRole enum
    UserRole role;
    if (_selectedRole == AppConstants.roleConsumer) {
      role = UserRole.consumer;
    } else if (_selectedRole == AppConstants.roleMerchant) {
      role = UserRole.merchant;
    } else {
      role = UserRole.consumer; // Default fallback
    }

    // Get AuthProvider and attempt signup
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signup(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: role,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        // Show success modal
        await StatusModal.show(
          context: context,
          isSuccess: true,
          title: 'Account Created',
          message: 'Your account has been created successfully.',
          onButtonPressed: () {
            Navigator.of(context).pop(); // Close modal
            // Navigate based on user role
            final userRole = authProvider.userRole;
            if (userRole != null) {
              if (userRole == UserRole.merchant) {
                context.go('/merchant-dashboard');
              } else {
                context.go('/home');
              }
            } else {
              context.go('/home');
            }
          },
        );
      } else {
        // Signup failed - show failure modal
        final errorMessage = authProvider.errorMessage ?? 'Sign up failed. Please try again.';
        await StatusModal.show(
          context: context,
          isSuccess: false,
          title: 'Account Creation Failed',
          message: errorMessage,
          onButtonPressed: () {
            Navigator.of(context).pop(); // Close modal only, stay on signup screen
          },
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppConstants.paddingXL),

                // Logo/Branding
                Center(
                  child: Transform.scale(
                    scale: 1.5,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100 * 1.67,
                      height: 100 * 1.67,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingXL * 2),

                // Header
                Text(
                  'Create Account',
                  style: AppTypography.h2.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingS),
                Text(
                  'Join SaveBite and start making a difference',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: AppConstants.paddingXL),

                // Role Selection
                Text(
                  'I am a...',
                  style: AppTypography.h5.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),
                _buildRoleSelector(),

                const SizedBox(height: AppConstants.paddingL),

                // First Name Field
                CustomTextField(
                  label: 'First Name',
                  hint: 'Enter your first name',
                  controller: _firstNameController,
                  prefixIcon: Icons.person_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    if (value.trim().length < 2) {
                      return 'First name must be at least 2 characters';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: AppConstants.paddingM),

                // Last Name Field
                CustomTextField(
                  label: 'Last Name',
                  hint: 'Enter your last name',
                  controller: _lastNameController,
                  prefixIcon: Icons.person_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    if (value.trim().length < 2) {
                      return 'Last name must be at least 2 characters';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: AppConstants.paddingM),

                // Email Field
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: AppConstants.paddingM),

                // Password Field
                CustomTextField(
                  label: 'Password',
                  hint: 'Create a password',
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < AppConstants.minPasswordLength) {
                      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: AppConstants.paddingM),

                // Confirm Password Field
                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: AppConstants.paddingXL),

                // Signup Button
                CustomButton(
                  text: 'Create Account',
                  onPressed: _isFormValid && !_isLoading ? _handleSignup : null,
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),

                const SizedBox(height: AppConstants.paddingM),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Login',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildRoleCard(
            label: 'Consumer',
            value: AppConstants.roleConsumer,
            icon: Icons.shopping_bag_outlined,
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: _buildRoleCard(
            label: 'Merchant',
            value: AppConstants.roleMerchant,
            icon: Icons.store_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == value;
    return InkWell(
      onTap: () => setState(() => _selectedRole = value),
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.paddingL,
          horizontal: AppConstants.paddingM,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
            width: isSelected ? 2.0 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.white,
              size: AppConstants.iconXL,
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              label,
              style: AppTypography.h5.copyWith(
                color: isSelected ? AppColors.primary : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
