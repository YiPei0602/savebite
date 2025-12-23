import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

/// Signup Screen
/// 
/// Allows new users to create an account and select their role.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = AppConstants.roleConsumer;
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
    } else if (roleParam == 'ngo') {
      _selectedRole = AppConstants.roleNGO;
    }
    // If no role parameter, default to consumer
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // TODO: Implement Firebase authentication
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Route based on selected role
        if (_selectedRole == AppConstants.roleConsumer) {
          context.go('/home');
        } else if (_selectedRole == AppConstants.roleMerchant) {
          context.go('/merchant-dashboard');
        } else {
          // Default to home for NGO or other roles
          context.go('/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Green background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // White icon on green background
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
                    scale: 1.5, // 1.5 times bigger without affecting layout
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100 * 1.67, // Base size (layout size)
                      height: 100 * 1.67, // Base size (layout size)
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                const SizedBox(height: AppConstants.paddingXL * 2),
                
                // Header
                Text(
                  'Create Account',
                  style: AppTypography.h2.copyWith(
                    color: Colors.white, // White text on green background
                  ),
                ),
                const SizedBox(height: AppConstants.paddingS),
                Text(
                  'Join SaveBite and start making a difference',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white70, // Light white text on green background
                  ),
                ),
                
                const SizedBox(height: AppConstants.paddingXL),
                
                // Role Selection
                Text(
                  'I am a...',
                  style: AppTypography.h5.copyWith(
                    color: Colors.white, // White text on green background
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),
                _buildRoleSelector(),
                
                const SizedBox(height: AppConstants.paddingL),
                
                // Name Field
                CustomTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameController,
                  prefixIcon: Icons.person_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.length < AppConstants.minNameLength) {
                      return 'Name must be at least ${AppConstants.minNameLength} characters';
                    }
                    return null;
                  },
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
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
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
                ),
                
                const SizedBox(height: AppConstants.paddingXL),
                
                // Signup Button
                CustomButton(
                  text: 'Create Account',
                  onPressed: _handleSignup,
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
                        color: Colors.white70, // Light white text on green background
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Login',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white, // White text on green background
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
        _buildRoleChip('Consumer', AppConstants.roleConsumer, Icons.shopping_bag),
        const SizedBox(width: AppConstants.paddingS),
        _buildRoleChip('Merchant', AppConstants.roleMerchant, Icons.store),
        const SizedBox(width: AppConstants.paddingS),
        _buildRoleChip('NGO', AppConstants.roleNGO, Icons.volunteer_activism),
      ],
    );
  }

  Widget _buildRoleChip(String label, String value, IconData icon) {
    final isSelected = _selectedRole == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRole = value),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.paddingM,
            horizontal: AppConstants.paddingS,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
                size: AppConstants.iconL,
              ),
              const SizedBox(height: AppConstants.paddingXS),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
