import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/features/auth_profile_impact/domain/models/user_model.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';

/// Unified back button used across secondary pages.
///
/// Behavior:
/// 1) Pop current route when possible.
/// 2) Otherwise, fallback to role home route.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.color,
    this.fallbackRoute,
  });

  final Color? color;
  final String? fallbackRoute;

  static String _roleHomePath(BuildContext context) {
    final role = context.read<AuthProvider>().userRole;
    return role == UserRole.merchant ? '/merchant-dashboard' : '/home';
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(fallbackRoute ?? _roleHomePath(context));
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: color),
      tooltip: 'Back',
      onPressed: () => _handleBack(context),
    );
  }
}
