import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Landing Page Screen
/// 
/// Displays the SaveBite brand and logo on app launch.
/// Auto-navigates to role-based login after 2-3 seconds or on tap.
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
    
    // Auto-navigate after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _navigateToRoleLogin();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToRoleLogin() {
    context.go('/role-based-login');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final logoSize = (screenHeight / 3) * 1.5; // 1.5x bigger than 1/3 screen

    return Scaffold(
      backgroundColor: const Color(0xFF00615F), // Deep teal
      body: GestureDetector(
        onTap: _navigateToRoleLogin,
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              'assets/images/logo.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
