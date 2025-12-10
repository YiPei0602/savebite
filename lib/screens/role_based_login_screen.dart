import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

/// Role-Based Login Screen
/// 
/// Displays role selection buttons for users to choose between
/// consumer ("I want to buy") and merchant ("I want to sell") roles.
class RoleBasedLoginScreen extends StatelessWidget {
  const RoleBasedLoginScreen({super.key});

  void _navigateToConsumerAuth(BuildContext context) {
    // Navigate to login with consumer role parameter
    context.go('/login?role=consumer');
  }

  void _navigateToMerchantAuth(BuildContext context) {
    // Navigate to login with merchant role parameter
    context.go('/login?role=merchant');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image - Full Screen
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/meals.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Semi-transparent Overlay
          Container(
            color: Colors.black.withOpacity(0.50),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header with back button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.go('/landing'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Spacer
                const Spacer(),
                
                // Welcome Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      const Text(
                        'Welcome to SaveBite',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose how you\'d like to get started',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Role Selection Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      // "I want to buy" Button
                      _ModernRoleButton(
                        icon: Icons.shopping_bag_outlined,
                        label: 'I want to buy',
                        description: 'Browse and purchase surplus food',
                        onPressed: () => _navigateToConsumerAuth(context),
                        isPrimary: true,
                      ),
                      const SizedBox(height: 16),
                      
                      // "I want to sell" Button
                      _ModernRoleButton(
                        icon: Icons.storefront_outlined,
                        label: 'I want to sell',
                        description: 'List and sell your surplus food',
                        onPressed: () => _navigateToMerchantAuth(context),
                        isPrimary: false,
                      ),
                    ],
                  ),
                ),
                
                // Bottom Spacer
                const SizedBox(height: 64),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern iOS-Style Role Button Widget
class _ModernRoleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ModernRoleButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isPrimary 
                ? const Color(0xFF00615F)
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary 
                  ? const Color(0xFF00615F)
                  : Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.75),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
