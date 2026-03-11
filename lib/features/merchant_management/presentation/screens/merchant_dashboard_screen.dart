import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/food_item_model.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/food_provider.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/merchant_provider.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final foodProvider = context.read<FoodProvider>();
      if (foodProvider.allFoodItems.isEmpty && !foodProvider.isLoading) {
        foodProvider.loadFoodItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, FoodProvider, MerchantProvider>(
      builder: (context, authProvider, foodProvider, merchantProvider, _) {
        final user = authProvider.currentUser;

        // Avoid showing another merchant's data: if this merchant isn't linked yet,
        // fall back to the user's uid (likely no items until backend integration).
        final merchantId = user?.merchantId ?? user?.id;

        final merchantItems = foodProvider.allFoodItems
            .where((item) => merchantId != null && item.merchantId == merchantId)
            .toList();

        final activeItems =
            merchantItems.where((item) => item.isAvailable && item.stock > 0).length;
        final soldOutItems =
            merchantItems.where((item) => item.stock == 0 || !item.isAvailable).length;

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
            child: foodProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _buildHeader(merchantName),
                      _buildStatsSection(activeItems, soldOutItems),
                      Expanded(child: _buildListingsSection(merchantItems)),
                    ],
                  ),
          ),

          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/add-surplus'),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('Add Item', style: AppTypography.buttonMedium),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String merchantName) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      color: AppColors.surface,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/merchant-dashboard');
              }
            },
            icon: const Icon(Icons.arrow_back),
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 8),
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

          IconButton(
            onPressed: () => context.push('/donation-prompt'),
            icon: const Icon(Icons.volunteer_activism, color: Colors.green),
            tooltip: 'Donate',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(int activeItems, int soldOutItems) {
    const todayRevenueText = '—';

    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.inventory_2_outlined,
              value: activeItems.toString(),
              label: 'Active Items',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_outline,
              value: soldOutItems.toString(),
              label: 'Sold Out',
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.trending_up,
              value: '${AppConstants.currencySymbol} $todayRevenueText',
              label: 'Today',
              color: AppColors.accent,
            ),
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
    final discount = item.discountPercentage;

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
                              '${AppConstants.currencySymbol} ${item.discountedPrice.toStringAsFixed(2)}',
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
                onSelected: (value) {
                  if (value == 'edit') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit (coming soon)')),
                      );
                  } else if (value == 'delete') {
                      _showDeleteDialog(item);
                    } else if (value == 'soldOut') {
                      context.read<FoodProvider>().updateStock(item.id, 0);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked as sold out')),
                      );
                  }
                },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'soldOut',
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle_outline, size: 20),
                          SizedBox(width: 12),
                          Text('Mark sold out'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
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
              Navigator.pop(context);
              await context.read<FoodProvider>().deleteFoodItem(item.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

