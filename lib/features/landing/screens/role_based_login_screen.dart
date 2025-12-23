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
    // Navigate to welcome with consumer role parameter
    context.go('/welcome?role=consumer');
  }

  void _navigateToMerchantAuth(BuildContext context) {
    // Navigate to welcome with merchant role parameter
    context.go('/welcome?role=merchant');
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
                        'Choose your role to get started',
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
                        label: 'Consumer',
                        description: 'I want to buy surplus food',
                        onPressed: () => _navigateToConsumerAuth(context),
                      ),
                      const SizedBox(height: 16),
                      
                      // "I want to sell" Button
                      _ModernRoleButton(
                        icon: Icons.storefront_outlined,
                        label: 'Merchant',
                        description: 'I want to sell surplus food',
                        onPressed: () => _navigateToMerchantAuth(context),
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
class _ModernRoleButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onPressed;

  const _ModernRoleButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onPressed,
  });

  @override
  State<_ModernRoleButton> createState() => _ModernRoleButtonState();
}

class _ModernRoleButtonState extends State<_ModernRoleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Default color for both buttons
    final defaultColor = Colors.white.withOpacity(0.15);
    final defaultBorderColor = Colors.white.withOpacity(0.3);
    
    // Active/pressed color
    final activeColor = const Color(0xFF00615F);
    final activeBorderColor = const Color(0xFF00615F);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isPressed ? activeColor : defaultColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed ? activeBorderColor : defaultBorderColor,
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
                  color: _isPressed
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
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
                      widget.label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
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
