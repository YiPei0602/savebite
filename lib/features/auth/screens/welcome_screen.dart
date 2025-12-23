import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

/// Welcome Screen
/// 
/// Displays welcome message with Sign Up and Login options.
/// Based on the reference design with clean, modern UI.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isSignUpPressed = false;
  bool _isLoginPressed = false;

  void _navigateToSignUp(BuildContext context, String? role) {
    if (role != null) {
      context.go('/signup?role=$role');
    } else {
      context.go('/signup');
    }
  }

  void _navigateToLogin(BuildContext context, String? role) {
    if (role != null) {
      context.go('/login?role=$role');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get role from query parameters
    final uri = GoRouterState.of(context).uri;
    final role = uri.queryParameters['role'];
    
    return Scaffold(
      backgroundColor: AppColors.primary, // Green background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/role-based-login'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingXL),
          child: Column(
            children: [
              const SizedBox(height: AppConstants.paddingXL),
              
              // Logo/Branding - Same size as login/signup pages
              Center(
                child: Transform.scale(
                  scale: 1.5, // 1.5 times bigger without affecting layout
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100 * 1.67, // Same as login/signup pages
                    height: 100 * 1.67, // Same as login/signup pages
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Welcome Content
              Column(
                children: [
                  Text(
                    'Welcome',
                    style: AppTypography.h1.copyWith(
                      color: Colors.white, // White text on green background
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  Text(
                    'Good food deserves a second chance.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white70, // Light white text on green background
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.paddingXL * 2),
              
              // Action Buttons
              Column(
                children: [
                  // Sign Up Button - Orange on press
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _isSignUpPressed = true),
                      onTapUp: (_) {
                        setState(() => _isSignUpPressed = false);
                        _navigateToSignUp(context, role);
                      },
                      onTapCancel: () => setState(() => _isSignUpPressed = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingM,
                        ),
                        decoration: BoxDecoration(
                          color: _isSignUpPressed ? AppColors.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                          border: Border.all(
                            color: _isSignUpPressed ? AppColors.accent : Colors.white.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Sign Up',
                            style: AppTypography.buttonLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.paddingM),
                  
                  // Login Button - Darker orange on press
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _isLoginPressed = true),
                      onTapUp: (_) {
                        setState(() => _isLoginPressed = false);
                        _navigateToLogin(context, role);
                      },
                      onTapCancel: () => setState(() => _isLoginPressed = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingM,
                        ),
                        decoration: BoxDecoration(
                          color: _isLoginPressed ? AppColors.accentDark : AppColors.accent,
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(_isLoginPressed ? 0.3 : 0.15),
                              blurRadius: _isLoginPressed ? 8 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Login',
                            style: AppTypography.buttonLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.paddingXL),
            ],
          ),
        ),
      ),
    );
  }
}
