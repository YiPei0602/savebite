import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/app/theme/app_colors.dart';
import 'package:savebite/app/theme/app_typography.dart';
import 'package:savebite/shared/constants/app_constants.dart';
import 'package:savebite/shared/widgets/custom_button.dart';
import 'package:savebite/shared/widgets/status_modal.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/features/auth_profile_impact/domain/models/user_model.dart';

/// Signup Screen
///
/// Allows new users to create an account and select their role (Consumer or Merchant only).
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
  String _selectedRole = AppConstants.roleConsumer;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    final roleParam = uri.queryParameters['role'];
    if (roleParam == 'consumer') {
      _selectedRole = AppConstants.roleConsumer;
    } else if (roleParam == 'merchant') {
      _selectedRole = AppConstants.roleMerchant;
    } else {
      _selectedRole = AppConstants.roleConsumer;
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
    return _firstNameController.text.trim().isNotEmpty &&
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

    setState(() => _isLoading = true);

    UserRole role;
    if (_selectedRole == AppConstants.roleConsumer) {
      role = UserRole.consumer;
    } else if (_selectedRole == AppConstants.roleMerchant) {
      role = UserRole.merchant;
    } else {
      role = UserRole.consumer;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signup(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: role,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      await StatusModal.show(
        context: context,
        isSuccess: true,
        title: 'Account Created',
        message: 'Your account has been created successfully.',
        onButtonPressed: () {
          Navigator.of(context).pop(); // Close modal
          final userRole = authProvider.userRole;
          if (userRole == UserRole.merchant) {
            context.go('/merchant-dashboard');
          } else {
            context.go('/home');
          }
        },
      );
    } else {
      final errorMessage =
          authProvider.errorMessage ?? 'Sign up failed. Please try again.';
      await StatusModal.show(
        context: context,
        isSuccess: false,
        title: 'Account Creation Failed',
        message: errorMessage,
        onButtonPressed: () {
          Navigator.of(context).pop();
        },
      );
    }
  }

  void _navigateBackToWelcome() {
    if (_selectedRole.isNotEmpty) {
      context.go('/welcome?role=$_selectedRole');
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _navigateBackToWelcome,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppConstants.paddingXL),

                Center(
                  child: Column(
                    children: [
                      Text(
                        'Create Account',
                        style: AppTypography.h2.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.paddingS),
                      Text(
                        'Enter your information',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.paddingXL),

                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    hintText: 'Enter your first name',
                    hintStyle: AppTypography.inputHint.copyWith(
                      color: const Color(0xFF60646C),
                    ),
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: const BorderSide(color: AppColors.borderActive, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
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

                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    hintText: 'Enter your last name',
                    hintStyle: AppTypography.inputHint.copyWith(
                      color: const Color(0xFF60646C),
                    ),
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: const BorderSide(color: AppColors.borderActive, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
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

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    hintStyle: AppTypography.inputHint.copyWith(
                      color: const Color(0xFF60646C),
                    ),
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: const BorderSide(color: AppColors.borderActive, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
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

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Create a password',
                    hintStyle: AppTypography.inputHint.copyWith(
                      color: const Color(0xFF60646C),
                    ),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: const Icon(Icons.visibility_off_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: const BorderSide(color: AppColors.borderActive, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
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

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    hintStyle: AppTypography.inputHint.copyWith(
                      color: const Color(0xFF60646C),
                    ),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: const Icon(Icons.visibility_off_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: const BorderSide(color: AppColors.borderActive, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
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

                CustomButton(
                  text: 'Create Account',
                  onPressed: _isFormValid && !_isLoading ? _handleSignup : null,
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),

                const SizedBox(height: AppConstants.paddingM),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_selectedRole.isNotEmpty) {
                          context.go('/login?role=$_selectedRole');
                        } else {
                          context.go('/login');
                        }
                      },
                      child: Text(
                        'Login',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
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
}

