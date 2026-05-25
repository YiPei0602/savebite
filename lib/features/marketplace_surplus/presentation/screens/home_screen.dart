import 'package:flutter/material.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/marketplace_surplus/presentation/screens/home_content_screen.dart';
import 'package:savebite/features/orders_payments/presentation/screens/order_history_screen.dart';
import 'package:savebite/features/auth_profile_impact/presentation/screens/profile_screen.dart';

/// Main Screen
///
/// Main navigation hub with bottom navigation bar.
/// Contains 3 tabs: Home, Orders, and Profile.
///
/// Deep links may pass [initialTabIndex] (0 Home, 1 Orders, 2 Profile).
class HomeScreen extends StatefulWidget {
  /// Number of bottom navigation tabs (Home, Orders, Profile).
  static const int tabCount = 3;

  const HomeScreen({super.key, this.initialTabIndex = 0});

  /// Bottom nav index when the screen first builds (clamped to 0..2).
  final int initialTabIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex =
      widget.initialTabIndex.clamp(0, HomeScreen.tabCount - 1);

  final List<Widget> _screens = const [
    HomeContentScreen(),
    OrderHistoryScreen(),
    ProfileScreen(),
  ];

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

