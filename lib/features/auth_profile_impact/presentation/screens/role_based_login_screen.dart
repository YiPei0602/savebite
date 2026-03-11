import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Role-Based Login Screen
///
/// Displays a welcome hero image with role selection options.
class RoleBasedLoginScreen extends StatelessWidget {
  const RoleBasedLoginScreen({super.key});

  void _navigateToConsumerAuth(BuildContext context) {
    context.go('/welcome?role=consumer');
  }

  void _navigateToMerchantAuth(BuildContext context) {
    context.go('/welcome?role=merchant');
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5EC),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                const ColoredBox(color: Color(0xFFE8F5EC)),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/landing'),
                          icon: const Icon(Icons.arrow_back_ios_new),
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
                      'assets/images/welcome.png',
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
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 18 + bottomSafe),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - (18 + bottomSafe)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Welcome to SaveBite',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1C1C1C),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Choose your role to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6E6E6E),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _ModernRoleButton(
                            icon: Icons.shopping_bag_outlined,
                            label: 'Consumer',
                            description: 'I want to buy',
                            onPressed: () => _navigateToConsumerAuth(context),
                          ),
                          const SizedBox(height: 12),
                          _ModernRoleButton(
                            icon: Icons.storefront_outlined,
                            label: 'Merchant',
                            description: 'I want to sell',
                            onPressed: () => _navigateToMerchantAuth(context),
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
    const defaultColor = Color(0xFFF7F7F7);
    const defaultBorderColor = Color(0xFFE9E9E9);
    const activeColor = Color(0xFFE6F6F5);
    const activeBorderColor = Color(0xFF1CB5AF);

    return Material(
      color: defaultColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _isPressed ? activeColor : defaultColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed ? activeBorderColor : defaultBorderColor,
              width: _isPressed ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isPressed
                      ? const Color(0xFF1CB5AF).withOpacity(0.15)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: const Color(0xFF0B8F89),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _isPressed
                            ? const Color(0xFF0A6C67)
                            : const Color(0xFF1C1C1C),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6E6E6E),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF8A8A8A),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

