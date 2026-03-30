import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/orders_payments/domain/models/cart_item_model.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/merchant_model.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/merchant_provider.dart';
import 'package:savebite/features/orders_payments/state/providers/cart_provider.dart';
import 'package:savebite/shared/utils/merchant_display_name_utils.dart';
import 'package:savebite/shared/widgets/app_back_button.dart';

/// Cart Screen
///
/// Displays items from CartProvider with quantity controls and total savings.
/// Allows users to proceed to checkout.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CartProvider, MerchantProvider>(
      builder: (context, cartProvider, merchantProvider, _) {
        final items = cartProvider.items;
        final isEmpty = cartProvider.isEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            leading: const AppBackButton(color: AppColors.textPrimary),
            title: Text(
              'Your Cart',
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
            ),
            actions: [
              if (items.isNotEmpty)
                IconButton(
                  icon:
                      Icon(Icons.delete_outline, color: AppColors.textPrimary),
                  onPressed: () => _showClearCartDialog(context, cartProvider),
                ),
            ],
          ),
          body: isEmpty
              ? _buildEmptyCart(context)
              : _buildCartContent(context, cartProvider, merchantProvider),
        );
      },
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Cart?', style: AppTypography.h4),
        content: Text(
          'Remove all items from your cart?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () {
              cartProvider.clearCart();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Clear', style: AppTypography.buttonMedium),
          ),
        ],
      ),
    );
  }

  /// Empty Cart State
  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 100,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppConstants.paddingL),
            Text(
              'Your Cart is Empty',
              style: AppTypography.h3,
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              'Add items from the marketplace to get started',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingXL),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingXL,
                  vertical: AppConstants.paddingM,
                ),
              ),
              child: Text(
                'Browse Surplus Food',
                style: AppTypography.buttonMedium.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cart Content with Items
  Widget _buildCartContent(
    BuildContext context,
    CartProvider cartProvider,
    MerchantProvider merchantProvider,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            itemCount: cartProvider.items.length,
            itemBuilder: (context, index) {
              final cartItem = cartProvider.items[index];
              return _buildCartItem(
                context,
                cartProvider,
                cartItem,
                merchantProvider,
              );
            },
          ),
        ),
        _buildCartFooter(context, cartProvider),
      ],
    );
  }

  /// Cart Item Row
  Widget _buildCartItem(
    BuildContext context,
    CartProvider cartProvider,
    CartItemModel cartItem,
    MerchantProvider merchantProvider,
  ) {
    final item = cartItem.foodItem;
    MerchantModel? mFor(String id) {
      for (final m in merchantProvider.merchants) {
        if (m.id == id) return m;
      }
      return null;
    }

    final shopName = consumerShopDisplayName(
      merchantId: item.merchantId,
      merchantProfile: mFor(item.merchantId),
      fromFoodItem: item.merchantName,
    );
    final quantity = cartItem.quantity;
    final price = item.effectiveDiscountedPrice;
    final originalPrice = item.originalPrice;
    final itemSavings = cartItem.savings;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
              child: Image.network(
                item.imageUrl,
                width: MediaQuery.of(context).size.width * 0.2,
                height: MediaQuery.of(context).size.width * 0.2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: MediaQuery.of(context).size.width * 0.2,
                    color: AppColors.surfaceVariant,
                    child: const Icon(
                      Icons.fastfood,
                      color: AppColors.textTertiary,
                      size: 32,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: AppTypography.h5,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppConstants.paddingXS),
                  Text(
                    shopName,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    'Qty: $quantity',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Wrap(
                    spacing: AppConstants.paddingS,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${AppConstants.currencySymbol}${price.toStringAsFixed(2)}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${AppConstants.currencySymbol}${originalPrice.toStringAsFixed(2)}',
                        style: AppTypography.bodySmall.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    'Save ${AppConstants.currencySymbol}${itemSavings.toStringAsFixed(2)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Per-item total + quantity controls are handled elsewhere.
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Cart Footer: Total Savings and Checkout Button
  Widget _buildCartFooter(BuildContext context, CartProvider cartProvider) {
    final totalItems = cartProvider.itemCount;
    final subtotal = cartProvider.subtotal;
    final totalSavings = cartProvider.totalSavings;

    void proceedToCheckout() {
      if (cartProvider.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your cart is empty'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      context.push('/checkout');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: AppConstants.primaryCtaFooterBlockPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Subtotal ($totalItems ${totalItems == 1 ? 'item' : 'items'})',
                      style: AppTypography.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${AppConstants.currencySymbol}${subtotal.toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingS),
              Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.savings_outlined,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: AppConstants.paddingS),
                          Flexible(
                            child: Text(
                              'Total Savings',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${AppConstants.currencySymbol}${totalSavings.toStringAsFixed(2)}',
                      style: AppTypography.h5.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: proceedToCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.primaryCtaVerticalPadding,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.primaryCtaPillRadius,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Proceed to Checkout',
                          style: AppTypography.buttonMedium.copyWith(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      const Icon(Icons.arrow_forward,
                          size: 20, color: AppColors.textOnPrimary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

