import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:savebite/app/theme/app_colors.dart';
import 'package:savebite/app/theme/app_typography.dart';
import 'package:savebite/shared/constants/app_constants.dart';

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
    final uri = GoRouterState.of(context).uri;
    final role = uri.queryParameters['role'];
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final roleImage = role == 'merchant'
        ? 'assets/images/merchant.png'
        : 'assets/images/consumer.png';
    final roleTitle = role == 'merchant' ? 'Sell Smart, Waste Less' : 'Good Food, Better Prices';
    final roleSubtitle = role == 'merchant'
        ? 'List your surplus food & connect with nearby buyers.'
        : 'Explore surplus food from nearby stores & save more.';
    final topColor =
        role == 'merchant' ? const Color(0xFFECE8F9) : const Color(0xFFE8F1FB);

    return Scaffold(
      backgroundColor: topColor,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ColoredBox(color: topColor),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new),
                          onPressed: () => context.go('/role-based-login'),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 1.2,
                    heightFactor: 1.2,
                    child: Image.asset(
                      roleImage,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppConstants.paddingL,
                      AppConstants.paddingL,
                      AppConstants.paddingL,
                      18 + bottomSafe,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - (18 + bottomSafe),
                      ),
                      child: Column(
                        children: [
                          Text(
                            roleTitle,
                            style: AppTypography.h2.copyWith(
                              color: const Color(0xFF1C1C1C),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppConstants.paddingS),
                          Text(
                            roleSubtitle,
                            style: AppTypography.bodyMedium.copyWith(
                              color: const Color(0xFF6E6E6E),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppConstants.paddingXL),
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
                                    color: _isSignUpPressed
                                        ? AppColors.accent
                                        : const Color(0xFFD9D9D9),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Sign Up',
                                    style: AppTypography.buttonLarge.copyWith(
                                      color: const Color(0xFF1C1C1C),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingM),
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
                                  color: _isLoginPressed
                                      ? AppColors.accentDark
                                      : AppColors.accent,
                                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        _isLoginPressed ? 0.25 : 0.12,
                                      ),
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
                          const SizedBox(height: AppConstants.paddingM),
                          Text(
                            role == 'merchant'
                                ? 'Continue as Merchant'
                                : 'Continue as Consumer',
                            style: AppTypography.caption.copyWith(
                              color: const Color(0xFF8A8A8A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
