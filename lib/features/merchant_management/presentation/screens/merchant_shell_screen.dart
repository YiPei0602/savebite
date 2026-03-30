import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/features/marketplace_surplus/data/services/merchant_service.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/auth_profile_impact/presentation/screens/profile_screen.dart';
import 'package:savebite/features/merchant_management/presentation/screens/merchant_dashboard_screen.dart';
import 'package:savebite/features/merchant_management/presentation/screens/merchant_orders_screen.dart';

/// Merchant main shell with bottom navigation (Home / Orders / Profile).
///
/// Orders tab uses a dedicated merchant order management screen.
class MerchantShellScreen extends StatefulWidget {
  const MerchantShellScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  State<MerchantShellScreen> createState() => _MerchantShellScreenState();
}

class _MerchantShellScreenState extends State<MerchantShellScreen> {
  late int _currentIndex = widget.initialTabIndex.clamp(0, 2);
  Timer? _merchantOpenSyncTimer;

  @override
  void didUpdateWidget(MerchantShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _currentIndex = widget.initialTabIndex.clamp(0, 2);
    }
  }

  /// Same tab order and widgets as consumer [HomeScreen], except Home is merchant dashboard.
  final List<Widget> _screens = const [
    MerchantDashboardScreen(),
    MerchantOrdersScreen(showBackButton: false),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncMerchantOpenState();
      _merchantOpenSyncTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _syncMerchantOpenState(),
      );
    });
  }

  void _syncMerchantOpenState() {
    if (!mounted) return;
    final uid = context.read<AuthProvider>().currentUser?.merchantId ??
        context.read<AuthProvider>().currentUser?.id;
    if (uid == null || uid.isEmpty) return;
    unawaited(MerchantService().syncOpenStateFromClosingTime(uid));
  }

  @override
  void dispose() {
    _merchantOpenSyncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.caption,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
