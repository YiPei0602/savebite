import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/food_item_model.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/food_provider.dart';
import 'package:savebite/features/orders_payments/state/providers/cart_provider.dart';
import 'package:savebite/shared/utils/price_utils.dart';

/// Merchant Details Screen
///
/// Displays detailed information about a merchant and their available surplus items.
/// Loads items from FoodProvider and uses CartProvider for cart state.
class MerchantDetailsScreen extends StatefulWidget {
  final String merchantId;
  final String? merchantName;
  final String? imageUrl;
  final double? rating;
  final int pickupHoursRemaining;

  const MerchantDetailsScreen({
    super.key,
    required this.merchantId,
    this.merchantName,
    this.imageUrl,
    this.rating,
    this.pickupHoursRemaining = 2,
  });

  @override
  State<MerchantDetailsScreen> createState() => _MerchantDetailsScreenState();
}

class _MerchantDetailsScreenState extends State<MerchantDetailsScreen> {
  // Countdown timer
  late Timer _timer;
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _remainingTime = Duration(hours: widget.pickupHoursRemaining);
    _startCountdown();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatCountdown() {
    final hours = _remainingTime.inHours;
    final minutes = _remainingTime.inMinutes.remainder(60);
    final seconds = _remainingTime.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours hours ${minutes}m';
    } else if (minutes > 0) {
      return '$minutes minutes ${seconds}s';
    } else {
      return '$seconds seconds';
    }
  }

  void _addToCart(CartProvider cartProvider, FoodItemModel item) {
    try {
      cartProvider.addItem(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} added to cart'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _removeFromCart(CartProvider cartProvider, FoodItemModel item) {
    final cartItem = cartProvider.getCartItem(item.id);
    if (cartItem != null && cartItem.quantity > 1) {
      cartProvider.decrementQuantity(cartItem.id);
    } else if (cartItem != null) {
      cartProvider.removeItem(cartItem.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FoodProvider, CartProvider>(
      builder: (context, foodProvider, cartProvider, _) {
        final merchantItems = foodProvider.allFoodItems
            .where((item) => item.merchantId == widget.merchantId)
            .where((item) => item.isAvailable && item.stock > 0)
            .toList();

        final merchantCartItems =
            cartProvider.itemsByMerchant[widget.merchantId] ?? [];
        final totalItemsFromMerchant = merchantCartItems.fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        );
        final totalPriceFromMerchant = merchantCartItems.fold<double>(
          0,
          (sum, item) => sum + item.subtotal,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Main Content
              CustomScrollView(
                slivers: [
                  // Header with Cover Image
                  _buildHeader(),

                  // Merchant Info
                  _buildMerchantInfo(merchantItems),

                  // Countdown Timer
                  _buildCountdownTimer(),

                  // Surplus Menu Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingM),
                      child: Text(
                        'Surplus Menu',
                        style: AppTypography.h4,
                      ),
                    ),
                  ),

                  // Surplus Items List
                  if (foodProvider.isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (merchantItems.isEmpty)
                    SliverFillRemaining(
                      child: Center(
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
                              'No surplus items available',
                              style: AppTypography.h5.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _buildSurplusItemsList(merchantItems, cartProvider),

                  // Bottom padding for floating cart banner
                  SliverToBoxAdapter(
                    child:
                        SizedBox(height: totalItemsFromMerchant > 0 ? 100 : 20),
                  ),
                ],
              ),

              // Floating Cart Banner
              if (totalItemsFromMerchant > 0)
                _buildFloatingCartBanner(
                  totalItems: totalItemsFromMerchant,
                  totalPrice: totalPriceFromMerchant,
                ),
            ],
          ),
        );
      },
    );
  }

  /// Header with Cover Image and 'Save Me' Badge
  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(AppConstants.paddingS),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Image
            Image.network(
              widget.imageUrl ??
                  'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  child: const Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // 'Save Me' Badge Overlay
            Positioned(
              top: 60,
              right: AppConstants.paddingM,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingM,
                  vertical: AppConstants.paddingS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.paddingXS),
                    Text(
                      'Save Me',
                      style: AppTypography.buttonMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Merchant Info: Name and Rating
  Widget _buildMerchantInfo(List<FoodItemModel> merchantItems) {
    final merchantName = widget.merchantName ??
        (merchantItems.isNotEmpty
            ? merchantItems.first.merchantName
            : 'Merchant ${widget.merchantId}');
    final rating = widget.rating ??
        (merchantItems.isNotEmpty ? (merchantItems.first.rating ?? 4.5) : 4.5);

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              merchantName,
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppConstants.paddingS),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < rating.floor()
                        ? Icons.star
                        : (index < rating
                            ? Icons.star_half
                            : Icons.star_border),
                    color: AppColors.warning,
                    size: 20,
                  );
                }),
                const SizedBox(width: AppConstants.paddingS),
                Text(
                  '$rating',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingXS),
                Text(
                  '(120 reviews)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Countdown Timer with Urgency
  Widget _buildCountdownTimer() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppConstants.paddingM),
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(
            color: AppColors.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingS),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup closes in',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingXS),
                  Text(
                    _formatCountdown(),
                    style: AppTypography.h4.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  /// Surplus Items List
  Widget _buildSurplusItemsList(
    List<FoodItemModel> items,
    CartProvider cartProvider,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          return _buildSurplusItemCard(item, cartProvider);
        },
        childCount: items.length,
      ),
    );
  }

  /// Surplus Item Card (Horizontal Layout)
  Widget _buildSurplusItemCard(FoodItemModel item, CartProvider cartProvider) {
    final quantityInCart = cartProvider.getItemQuantity(item.id);
    final dynamicPrice = PriceUtils.computeDiscountedPrice(
      originalPrice: item.originalPrice,
      discountPercent: item.discountRange != null
          ? PriceUtils.computeDynamicDiscount(
              minPercent: item.discountRange!.minPercent,
              maxPercent: item.discountRange!.maxPercent,
              closingTime: item.closingTime,
            )
          : item.discountPercentage,
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
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
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(
                        Icons.fastfood,
                        color: AppColors.textTertiary,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTypography.h5,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppConstants.paddingXS),
                        Text(
                          item.description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 14,
                              color: item.stock <= 3
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                            const SizedBox(width: AppConstants.paddingXS),
                            Text(
                              '${item.stock} left',
                              style: AppTypography.bodySmall.copyWith(
                                color: item.stock <= 3
                                    ? AppColors.warning
                                    : AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: [
                            Text(
                              '${AppConstants.currencySymbol}${item.originalPrice.toStringAsFixed(2)}',
                              style: AppTypography.bodySmall.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${AppConstants.currencySymbol}${dynamicPrice.toStringAsFixed(2)}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
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
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Center(
                child: quantityInCart == 0
                    ? _buildAddButton(item, cartProvider)
                    : _buildQuantityControls(item, cartProvider, quantityInCart),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Add Button (Primary Green)
  Widget _buildAddButton(FoodItemModel item, CartProvider cartProvider) {
    return ElevatedButton(
      onPressed: () => _addToCart(cartProvider, item),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: AppConstants.paddingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        elevation: 2,
      ),
      child: Text(
        'Add',
        style: AppTypography.buttonMedium,
      ),
    );
  }

  /// Quantity Controls (+ and -)
  Widget _buildQuantityControls(
    FoodItemModel item,
    CartProvider cartProvider,
    int quantity,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppColors.primary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            color: AppColors.primary,
            onPressed: () => _removeFromCart(cartProvider, item),
            padding: const EdgeInsets.all(AppConstants.paddingS),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: AppConstants.paddingS),
            child: Text(
              '$quantity',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            color: AppColors.primary,
            onPressed: () => _addToCart(cartProvider, item),
            padding: const EdgeInsets.all(AppConstants.paddingS),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  /// Floating Cart Banner at Bottom
  Widget _buildFloatingCartBanner({
    required int totalItems,
    required double totalPrice,
  }) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(AppConstants.paddingM),
        padding: const EdgeInsets.all(AppConstants.paddingL),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cart Icon with Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.shopping_bag,
                  color: AppColors.textOnPrimary,
                  size: 28,
                ),
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '$totalItems',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppConstants.paddingM),
            // Cart Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$totalItems ${totalItems == 1 ? 'item' : 'items'}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${AppConstants.currencySymbol}${totalPrice.toStringAsFixed(2)}',
                    style: AppTypography.h5.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // View Cart Button
            ElevatedButton(
              onPressed: () => context.push('/cart'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textOnPrimary,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingL,
                  vertical: AppConstants.paddingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
              child: Text(
                'View Cart',
                style: AppTypography.buttonMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

