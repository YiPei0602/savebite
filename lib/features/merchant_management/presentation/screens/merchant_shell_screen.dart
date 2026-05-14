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
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';
import 'package:savebite/features/orders_payments/state/providers/order_provider.dart';

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
    final merchantId =
        context.watch<AuthProvider>().currentUser?.merchantId ??
            context.watch<AuthProvider>().currentUser?.id;

    return Scaffold(
      // Keep Orders (and merchant stream/notifications) alive while on Home tab.
      body: IndexedStack(
        index: _currentIndex,
        children: [
          MerchantDashboardScreen(
            onGoToOrdersTab: () => setState(() => _currentIndex = 1),
          ),
          const MerchantOrdersScreen(showBackButton: false),
          const ProfileScreen(),
        ],
      ),
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
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: MerchantOrdersTabIconWithBadge(
              merchantId: merchantId ?? '',
              isSelected: _currentIndex == 1,
            ),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Orders icon with badge count for unpaid orders awaiting acceptance.
class MerchantOrdersTabIconWithBadge extends StatelessWidget {
  const MerchantOrdersTabIconWithBadge({
    super.key,
    required this.merchantId,
    required this.isSelected,
  });

  final String merchantId;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color =
        isSelected ? AppColors.primary : AppColors.textSecondary;
    if (merchantId.isEmpty) {
      return Icon(Icons.receipt_long, color: color);
    }
    final orderProvider = context.read<OrderProvider>();
    return StreamBuilder<List<OrderModel>>(
      stream: orderProvider.watchMerchantOrders(merchantId),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? const <OrderModel>[];
        final pendingAccept = orders
            .where((o) =>
                o.orderStatus == OrderStatus.pending &&
                o.paymentStatus == PaymentStatus.paid)
            .length;
        if (pendingAccept <= 0) {
          return Icon(Icons.receipt_long, color: color);
        }
        return Badge(
          label: Text(
            pendingAccept > 9 ? '9+' : '$pendingAccept',
            style: const TextStyle(fontSize: 10),
          ),
          child: Icon(Icons.receipt_long, color: color),
        );
      },
    );
  }
}
