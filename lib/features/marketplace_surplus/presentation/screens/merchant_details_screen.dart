import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/marketplace_surplus/data/services/merchant_service.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/food_item_model.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/merchant_model.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/food_provider.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/merchant_provider.dart';
import 'package:savebite/features/orders_payments/state/providers/cart_provider.dart';
import 'package:savebite/shared/utils/malaysia_store_time_utils.dart';
import 'package:savebite/shared/utils/merchant_display_name_utils.dart';
import 'package:savebite/shared/utils/merchant_schedule_utils.dart';
import 'package:savebite/shared/utils/surplus_sellability_utils.dart';
import 'package:savebite/shared/widgets/app_back_button.dart';

/// Merchant Details Screen
///
/// Displays detailed information about a merchant and their available surplus items.
/// Loads items from FoodProvider and uses CartProvider for cart state.
class MerchantDetailsScreen extends StatefulWidget {
  final String merchantId;
  final String? merchantName;
  final String? imageUrl;
  final double? rating;

  const MerchantDetailsScreen({
    super.key,
    required this.merchantId,
    this.merchantName,
    this.imageUrl,
    this.rating,
  });

  @override
  State<MerchantDetailsScreen> createState() => _MerchantDetailsScreenState();
}

class _MerchantDetailsScreenState extends State<MerchantDetailsScreen> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncStoreAndListings());
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _syncStoreAndListings() async {
    if (!mounted) return;
    final food = context.read<FoodProvider>();
    final id = widget.merchantId;
    await MerchantService().syncOpenStateFromClosingTime(id);
    await food.applyListingLifecycleForMerchant(id);
    await food.loadFoodItems(showLoadingIndicator: false);
  }

  /// Compact merchant strip: rating/reviews (if any), closing countdown (if any).
  Widget _buildMerchantCompact(
    MerchantModel? merchant,
    List<FoodItemModel> merchantItems, {
    required bool storeOpen,
  }) {
    final dur = durationUntilClosingMalaysia(merchant);
    final rating = widget.rating ??
        (merchantItems.isNotEmpty ? merchantItems.first.rating : null) ??
        (merchant != null && merchant.rating > 0 ? merchant.rating : null);
    final reviewCount = merchant?.reviewCount ?? 0;
    final showRating = rating != null && rating > 0;
    final showReviews = reviewCount > 0;

    if (!showRating && !showReviews && dur == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingM,
        0,
        AppConstants.paddingM,
        AppConstants.paddingS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showRating || showReviews)
            Row(
              children: [
                if (showRating) ...[
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
                  const SizedBox(width: 8),
                  Text(
                    '$rating',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (showReviews) ...[
                  const SizedBox(width: 8),
                  Text(
                    '($reviewCount reviews)',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          if (dur != null) ...[
            if (showRating || showReviews) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.schedule,
                  size: 20,
                  color: storeOpen ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dur > Duration.zero
                            ? MalaysiaStoreTimeUtils.formatHhMmSs(dur)
                            : 'Closed',
                        style: AppTypography.h5.copyWith(
                          color: storeOpen
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dur > Duration.zero
                            ? 'Time until closing (Malaysia)'
                            : 'Past store closing time (Malaysia)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<FoodProvider, CartProvider, MerchantProvider>(
      builder: (context, foodProvider, cartProvider, merchantProvider, _) {
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

        return StreamBuilder<MerchantModel?>(
          stream: merchantProvider.watchMerchant(widget.merchantId),
          builder: (context, snapshot) {
            final merchant = snapshot.data;
            final now = DateTime.now();
            final storeOpen = merchant == null
                ? true
                : (hasValidOperatingSchedule(merchant)
                    ? isMerchantOpenNowMalaysia(merchant)
                    : merchant.isOpen);
            final merchantItems = foodProvider.allFoodItems
                .where((item) => item.merchantId == widget.merchantId)
                .where(
                  (item) =>
                      !isListingPastStoreSessionMalaysia(merchant) &&
                      item.isConsumerVisibleNow() &&
                      item.stock > 0,
                )
                .toList()
              ..sort((a, b) {
                final ua = isConsumerListingUnavailableForDisplay(
                  a,
                  now,
                  merchantStoreOpen: storeOpen,
                )
                    ? 1
                    : 0;
                final ub = isConsumerListingUnavailableForDisplay(
                  b,
                  now,
                  merchantStoreOpen: storeOpen,
                )
                    ? 1
                    : 0;
                if (ua != ub) return ua.compareTo(ub);
                return b.createdAt.compareTo(a.createdAt);
              });

            return Scaffold(
              backgroundColor: AppColors.background,
              body: Stack(
                children: [
                  // Main Content
                  CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        backgroundColor: AppColors.background,
                        elevation: 0,
                        leading: const AppBackButton(color: AppColors.textPrimary),
                        title: Text(
                          consumerShopDisplayName(
                            merchantId: widget.merchantId,
                            merchantProfile: merchant,
                            fromFoodItem: widget.merchantName ??
                                (merchantItems.isNotEmpty
                                    ? merchantItems.first.merchantName
                                    : null),
                          ),
                          style: AppTypography.h5.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildMerchantCompact(
                          merchant,
                          merchantItems,
                          storeOpen: storeOpen,
                        ),
                      ),

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
                                const Icon(
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
                        _buildSurplusItemsList(
                          merchantItems,
                          cartProvider,
                          merchantStoreOpen: storeOpen,
                        ),

                      // Bottom padding for floating cart banner
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: totalItemsFromMerchant > 0 ? 100 : 20,
                        ),
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
      },
    );
  }

  /// Surplus Items List
  Widget _buildSurplusItemsList(
    List<FoodItemModel> items,
    CartProvider cartProvider, {
    required bool merchantStoreOpen,
  }) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          return _buildSurplusItemCard(
            item,
            cartProvider,
            merchantStoreOpen: merchantStoreOpen,
          );
        },
        childCount: items.length,
      ),
    );
  }

  /// Surplus Item Card (Horizontal Layout)
  Widget _buildSurplusItemCard(
    FoodItemModel item,
    CartProvider cartProvider, {
    required bool merchantStoreOpen,
  }) {
    final now = DateTime.now();
    final quantityInCart = cartProvider.getItemQuantity(item.id);
    final dynamicPrice = item.effectiveDiscountedPrice;
    final unavailable = isConsumerListingUnavailableForDisplay(
      item,
      now,
      merchantStoreOpen: merchantStoreOpen,
    );
    final sellable =
        isSurplusSellableToConsumer(item, now) && merchantStoreOpen;

    final card = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      child: Material(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.shadow.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          onTap: unavailable
              ? null
              : sellable
                  ? () => context.push(
                        '/merchant/${widget.merchantId}/item/${item.id}',
                        extra: item,
                      )
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This listing is unavailable.'),
                        ),
                      );
                    },
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
                    Image.network(
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
                    if (unavailable)
                      Container(
                        color: Colors.black.withOpacity(0.45),
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Unavailable',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
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
                Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (quantityInCart > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$quantityInCart',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      if (quantityInCart > 0) const SizedBox(height: 8),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (unavailable) return Opacity(opacity: 0.72, child: card);
    return card;
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
