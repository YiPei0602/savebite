import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/features/marketplace_surplus/data/services/merchant_service.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/food_item_model.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/food_provider.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/merchant_provider.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';
import 'package:savebite/features/orders_payments/state/providers/order_provider.dart';
import 'package:timezone/timezone.dart' as tz;

/// Merchant Dashboard Screen
///
/// Main hub for merchants to manage their surplus food listings.
/// Loads items from FoodProvider and merchant info from MerchantProvider.
class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  List<FoodItemModel> _merchantListings = const [];
  bool _listingsLoading = true;

  Future<void> _maybeShowExpiredDismissDialog(String merchantId) async {
    final expired = _merchantListings
        .where(
          (i) =>
              i.listingStatus == ListingStatus.expired &&
              !i.dismissedFromMerchantDashboard,
        )
        .toList();
    if (expired.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Ended listings'),
          content: Text(
            '${expired.length} listing(s) are past closing time and saved as expired. '
            'Tap Remove to hide them from this screen.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final foodProvider = context.read<FoodProvider>();
                await foodProvider.dismissExpiredFromMerchantDashboard(merchantId);
                if (!mounted) return;
                await _refreshMerchantListings(runLifecycle: false);
                if (!mounted) return;
                await foodProvider.loadFoodItems(showLoadingIndicator: false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ended listings removed from your dashboard.'),
                  ),
                );
              },
              child: const Text('Remove'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _refreshMerchantListings({bool runLifecycle = true}) async {
    final foodProvider = context.read<FoodProvider>();
    final authProvider = context.read<AuthProvider>();
    final merchantId =
        authProvider.currentUser?.merchantId ?? authProvider.currentUser?.id;

    if (!mounted) return;
    setState(() => _listingsLoading = true);

    try {
      if (merchantId == null || merchantId.isEmpty) {
        if (mounted) {
          setState(() {
            _merchantListings = const [];
            _listingsLoading = false;
          });
        }
        return;
      }

      if (runLifecycle) {
        await MerchantService().syncOpenStateFromClosingTime(merchantId);
        await foodProvider.applyListingLifecycleForMerchant(merchantId);
      }
      final items = await foodProvider.getFoodItemsByMerchant(merchantId);
      if (!mounted) return;
      setState(() {
        _merchantListings = items;
        _listingsLoading = false;
      });
      await _maybeShowExpiredDismissDialog(merchantId);
      if (runLifecycle) {
        await foodProvider.loadFoodItems(showLoadingIndicator: false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _listingsLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final merchantId =
          authProvider.currentUser?.merchantId ?? authProvider.currentUser?.id;
      if (merchantId != null && merchantId.isNotEmpty) {
        context.read<OrderProvider>().loadMerchantOrders(merchantId);
      }
      await _refreshMerchantListings(runLifecycle: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<AuthProvider, FoodProvider, MerchantProvider, OrderProvider>(
      builder: (context, authProvider, foodProvider, merchantProvider, orderProvider, _) {
        final user = authProvider.currentUser;

        // Avoid showing another merchant's data: if this merchant isn't linked yet,
        // fall back to the user's uid (likely no items until backend integration).
        final merchantId = user?.merchantId ?? user?.id;

        final merchantItems = merchantId != null
            ? _merchantListings
                .where((item) => item.merchantId == merchantId)
                .toList()
            : <FoodItemModel>[];

        final merchantItemsForUi = merchantItems
            .where((item) => item.isVisibleOnMerchantDashboard)
            .toList();

        final activeItems = merchantItems
            .where(
              (item) =>
                  item.listingStatus == ListingStatus.active &&
                  item.isAvailable &&
                  item.stock > 0,
            )
            .length;
        final expiringSoon30Min = merchantItems
            .where(
              (item) =>
                  item.listingStatus == ListingStatus.active &&
                  item.isAvailable &&
                  item.stock > 0 &&
                  item.isExpiringSoon30Min,
            )
            .length;

        final orders = orderProvider.orders;
        final loc = tz.getLocation('Asia/Kuala_Lumpur');
        final now = tz.TZDateTime.now(loc);
        final startOfDay = tz.TZDateTime(loc, now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        final completedToday = orders.where((o) {
          if (o.orderStatus != OrderStatus.completed) return false;
          if (o.paymentStatus != PaymentStatus.paid) return false;
          final completedAt = o.completedAt;
          if (completedAt == null) return false;
          final c = tz.TZDateTime.from(completedAt, loc);
          return !c.isBefore(startOfDay) && c.isBefore(endOfDay);
        }).toList(growable: false);
        final completedTodayCount = completedToday.length;
        final todayRevenue = completedToday.fold<double>(
          0.0,
          (sum, o) => sum + o.totalPrice,
        );

        final merchantList =
            merchantProvider.merchants.where((m) => m.id == merchantId).toList();
        final merchant = merchantList.isEmpty ? null : merchantList.first;

        final merchantName = merchant?.name ??
            (merchantItems.isNotEmpty ? merchantItems.first.merchantName : null) ??
            user?.name ??
            'Your Store';

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(
                  merchantName: merchantName,
                ),
                _buildStatsSection(
                  activeItems: activeItems,
                  expiringSoon30Min: expiringSoon30Min,
                  completedTodayCount: completedTodayCount,
                  todayRevenue: todayRevenue,
                ),
                Expanded(
                  child: _listingsLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildListingsSection(merchantItemsForUi),
                ),
              ],
            ),
          ),

          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await context.push('/add-surplus');
              if (mounted) await _refreshMerchantListings(runLifecycle: false);
            },
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('Add Item', style: AppTypography.buttonMedium),
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required String merchantName,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(merchantName, style: AppTypography.h3),
                Text(
                  'Manage your surplus food',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () => context.push('/merchant-orders'),
            icon: Icon(Icons.receipt_long, color: AppColors.primary),
            tooltip: 'Orders',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection({
    required int activeItems,
    required int expiringSoon30Min,
    required int completedTodayCount,
    required double todayRevenue,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle_outline,
                  value: completedTodayCount.toString(),
                  label: 'Completed Today',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up,
                  value:
                      '${AppConstants.currencySymbol} ${todayRevenue.toStringAsFixed(2)}',
                  label: 'Revenue Today',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.inventory_2_outlined,
                  value: activeItems.toString(),
                  label: 'Active Items',
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.timer_outlined,
                  value: expiringSoon30Min.toString(),
                  label: '< 30 mins',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.h4.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListingsSection(List<FoodItemModel> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
          child: Text('My Listings', style: AppTypography.h4),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                      Text(
                        'No listings yet',
                        style: AppTypography.h5.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingS),
                      Text(
                        'Tap Add Item to create your first surplus listing',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingL,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildListingCard(items[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildListingCard(FoodItemModel item) {
    final isSoldOut = item.stock == 0 || !item.isAvailable;
    final discount = item.effectiveDiscountPercentage;
    final statusLabel = switch (item.listingStatus) {
      ListingStatus.expired => 'EXPIRED',
      ListingStatus.active => null,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 100,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.radiusM),
                  bottomLeft: Radius.circular(AppConstants.radiusM),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.imageUrl.startsWith('assets/')
                        ? Image.asset(item.imageUrl, fit: BoxFit.cover)
                        : Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.white,
                                child: Icon(
                                  Icons.fastfood,
                                  color: AppColors.textSecondary,
                                ),
                              );
                            },
                          ),
                    if (isSoldOut)
                      Container(
                        color: Colors.black.withOpacity(0.6),
                        child: Center(
                          child: Text(
                            'SOLD OUT',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: AppTypography.h5,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (statusLabel != null)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$discount% OFF',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.category.toString().split('.').last,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${AppConstants.currencySymbol} ${item.originalPrice.toStringAsFixed(2)}',
                                style: AppTypography.bodySmall.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${AppConstants.currencySymbol} ${item.effectiveDiscountedPrice.toStringAsFixed(2)}',
                              style: AppTypography.h5.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 14,
                              color: isSoldOut ? AppColors.error : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.stock} left',
                              style: AppTypography.caption.copyWith(
                                color:
                                    isSoldOut ? AppColors.error : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(
              width: 40,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
                onSelected: (value) async {
                  if (value == 'edit') {
                    await context.push('/add-surplus', extra: item);
                    if (mounted) await _refreshMerchantListings(runLifecycle: false);
                  } else if (value == 'delete') {
                    _showDeleteDialog(item);
                  } else if (value == 'soldOut') {
                    final messenger = ScaffoldMessenger.of(context);
                    await context.read<FoodProvider>().updateStock(item.id, 0);
                    if (mounted) {
                      await _refreshMerchantListings(runLifecycle: false);
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Marked as sold out')),
                        );
                      }
                    }
                  } else if (value == 'markAvailable') {
                    _showMarkAvailableDialog(item);
                  }
                },
                itemBuilder: (context) {
                  final isSoldOut = item.stock == 0;
                  return [
                    PopupMenuItem(
                      value: isSoldOut ? 'markAvailable' : 'soldOut',
                      child: Row(
                        children: [
                          Icon(
                            isSoldOut
                                ? Icons.add_circle_outline
                                : Icons.remove_circle_outline,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(isSoldOut ? 'Mark as available' : 'Mark sold out'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(FoodItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final foodProvider = context.read<FoodProvider>();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await foodProvider.deleteFoodItem(item.id);
              if (!mounted) return;
              await _refreshMerchantListings(runLifecycle: false);
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Item deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMarkAvailableDialog(FoodItemModel item) {
    showDialog<void>(
      context: context,
      builder: (_) => _MarkAvailableDialog(
        item: item,
        onUpdate: (quantity) async {
          await context.read<FoodProvider>().updateStock(item.id, quantity);
          if (mounted) {
            await _refreshMerchantListings(runLifecycle: false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Updated to $quantity available')),
              );
            }
          }
        },
      ),
    );
  }
}

/// Dialog for re-adding quantity when marking a sold-out item as available.
/// Uses StatefulWidget so the controller is disposed by Flutter when the route
/// is removed, avoiding "controller used after dispose" crash.
class _MarkAvailableDialog extends StatefulWidget {
  final FoodItemModel item;
  final Future<void> Function(int quantity) onUpdate;

  const _MarkAvailableDialog({
    required this.item,
    required this.onUpdate,
  });

  @override
  State<_MarkAvailableDialog> createState() => _MarkAvailableDialogState();
}

class _MarkAvailableDialogState extends State<_MarkAvailableDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity (1 or more)')),
      );
      return;
    }
    Navigator.of(context).pop();
    await widget.onUpdate(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark as available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter quantity for "${widget.item.name}":',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              hintText: 'e.g. 5',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => unawaited(_submit()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => unawaited(_submit()),
          child: const Text('Update'),
        ),
      ],
    );
  }
}

