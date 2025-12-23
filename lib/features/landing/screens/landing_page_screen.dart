import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

/// Landing Page Screen
/// 
/// Displays the SaveBite brand and logo on app launch.
/// User must click "Get Started" button to proceed.
class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup fade-in animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToRoleSelection() {
    context.go('/role-based-login');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF00615F), // Deep teal
      body: SafeArea(
        child: Column(
          children: [
            // Loading Image Section
            Expanded(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Image.asset(
                    'assets/images/Loading.png',
                    width: screenWidth * 0.8 * 1.33, // Increased by 1/3
                    height: screenHeight * 0.6 * 1.33, // Increased by 1/3
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            
            // Get Started Button
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingXL),
              child: SizedBox(
                width: double.infinity,
                  child: ElevatedButton(
                  onPressed: _navigateToRoleSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent, // Bright Orange
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingM,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'Get Started',
                    style: AppTypography.buttonLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
