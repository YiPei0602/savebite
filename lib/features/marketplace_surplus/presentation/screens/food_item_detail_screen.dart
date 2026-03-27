import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
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

/// Item-first add-to-cart: full-bleed hero, item info, compact merchant strip, qty, CTA.
class FoodItemDetailScreen extends StatefulWidget {
  const FoodItemDetailScreen({
    super.key,
    required this.item,
  });

  final FoodItemModel item;

  @override
  State<FoodItemDetailScreen> createState() => _FoodItemDetailScreenState();
}

class _FoodItemDetailScreenState extends State<FoodItemDetailScreen> {
  Timer? _clock;
  late int _quantity;
  bool _syncedQtyFromCart = false;
  Stream<MerchantModel?>? _merchantStream;

  @override
  void initState() {
    super.initState();
    _quantity = 1;
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _merchantStream ??=
        context.read<MerchantProvider>().watchMerchant(widget.item.merchantId);
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  FoodItemModel _resolveItem(FoodProvider fp) {
    for (final e in fp.allFoodItems) {
      if (e.id == widget.item.id) return e;
    }
    return widget.item;
  }

  void _syncQuantityFromCart(CartProvider cart) {
    if (_syncedQtyFromCart) return;
    final q = cart.getItemQuantity(widget.item.id);
    _syncedQtyFromCart = true;
    if (q > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _quantity = q);
      });
    }
  }

  void _applyCart(CartProvider cart, FoodItemModel item) {
    try {
      final existing = cart.getCartItem(item.id);
      if (existing != null) {
        cart.updateQuantity(existing.id, _quantity);
      } else {
        cart.addItem(item, quantity: _quantity);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} added to cart'),
            duration: const Duration(seconds: 1),
          ),
        );
        context.pushReplacement('/cart');
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<FoodProvider, CartProvider>(
      builder: (context, foodProvider, cartProvider, _) {
        _syncQuantityFromCart(cartProvider);
        final item = _resolveItem(foodProvider);
        return StreamBuilder<MerchantModel?>(
          stream: _merchantStream,
          builder: (context, snap) {
            final m = snap.data;
            final now = DateTime.now();
            final storeOpen = m == null
                ? true
                : (hasValidOperatingSchedule(m)
                    ? isMerchantOpenNowMalaysia(m)
                    : m.isOpen);
            final sellable =
                isSurplusSellableToConsumer(item, now) && storeOpen;
            final dur = durationUntilClosingMalaysia(m);
            final merchantName = consumerShopDisplayName(
              merchantId: item.merchantId,
              merchantProfile: m,
              fromFoodItem: item.merchantName,
            );
            final rating = item.rating ?? (m != null && m.rating > 0 ? m.rating : null);
            final reviewCount = m != null && m.reviewCount > 0 ? m.reviewCount : null;
            final unit = item.effectiveDiscountedPrice;
            final lineTotal = unit * _quantity;
            final media = MediaQuery.of(context);
            final imageHeight = media.size.height * 0.45;
            /// Pixels the content sheet overlaps the hero (floating layer).
            const sheetHeroOverlap = 35.0;
            const sheetTopRadius = 40.0;

            return Scaffold(
              backgroundColor: AppColors.background,
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                iconTheme: const IconThemeData(color: AppColors.textPrimary),
                leading: const AppBackButton(color: AppColors.textPrimary),
              ),
              body: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: imageHeight,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: imageHeight,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(
                            Icons.fastfood,
                            size: 64,
                            color: AppColors.textTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: imageHeight - sheetHeroOverlap,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: Colors.white,
                      elevation: 14,
                      shadowColor: Colors.black.withOpacity(0.18),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(sheetTopRadius),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Expanded(
                            child: SafeArea(
                              top: false,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  AppConstants.paddingM,
                                  AppConstants.paddingL,
                                  AppConstants.paddingM,
                                  AppConstants.paddingL,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: AppTypography.h4.copyWith(
                                        color: AppColors.textPrimary,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w700,
                                        height: 1.50,
                                      ),
                                    ),
                                    if (item.description.trim().isNotEmpty) ...[
                                      const SizedBox(height: AppConstants.paddingS),
                                      Text(
                                        item.description,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: AppConstants.paddingM),
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: AppConstants.paddingS,
                                      children: [
                                        Text(
                                          '${AppConstants.currencySymbol}${item.originalPrice.toStringAsFixed(2)}',
                                          style: AppTypography.bodyLarge.copyWith(
                                            decoration: TextDecoration.lineThrough,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          '${AppConstants.currencySymbol}${unit.toStringAsFixed(2)}',
                                          style: AppTypography.h5.copyWith(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppConstants.paddingL),
                                    _MerchantCompactStrip(
                                      merchantName: merchantName,
                                      rating: rating,
                                      reviewCount: reviewCount,
                                      dur: dur,
                                      storeOpen: storeOpen,
                                      stock: item.stock,
                                    ),
                                    const SizedBox(height: AppConstants.paddingL),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _RoundQtyButton(
                                          icon: Icons.remove,
                                          onPressed: sellable && _quantity > 1
                                              ? () => setState(() => _quantity--)
                                              : null,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppConstants.paddingL,
                                          ),
                                          child: Text(
                                            '$_quantity',
                                            style: AppTypography.h4.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        _RoundQtyButton(
                                          icon: Icons.add,
                                          onPressed: sellable &&
                                                  _quantity < item.stock
                                              ? () => setState(() => _quantity++)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SafeArea(
                            top: false,
                            child: Padding(
                              padding: AppConstants.primaryCtaStickyOuterPadding,
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: sellable
                                      ? () => _applyCart(cartProvider, item)
                                      : () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'This listing is unavailable.',
                                              ),
                                            ),
                                          );
                                        },
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
                                  child: Text(
                                    'Add to Cart – ${AppConstants.currencySymbol}${lineTotal.toStringAsFixed(2)}',
                                    style: AppTypography.buttonMedium.copyWith(
                                      color: AppColors.textOnPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _RoundQtyButton extends StatelessWidget {
  const _RoundQtyButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed != null ? AppColors.primary : AppColors.textTertiary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppColors.textOnPrimary, size: 22),
        ),
      ),
    );
  }
}

/// Soft pill for closing countdown — gentle urgency, not an error state.
class _ClosingTimeBadge extends StatelessWidget {
  const _ClosingTimeBadge({
    required this.dur,
    required this.storeOpen,
  });

  final Duration dur;
  final bool storeOpen;

  /// Light wash (not solid red).
  static const Color _softRose = Color(0xFFFFE8EC);
  static const Color _roseInk = Color(0xFFB71C1C);

  @override
  Widget build(BuildContext context) {
    final openCountdown = dur > Duration.zero && storeOpen;
    final bg = openCountdown
        ? _softRose
        : AppColors.surfaceVariant.withOpacity(0.7);
    final ink = openCountdown ? _roseInk : AppColors.textSecondary;

    final label = dur > Duration.zero
        ? '${MalaysiaStoreTimeUtils.formatHhMmSs(dur)} · until close (MY)'
        : 'Closed (Malaysia)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 15,
            color: ink,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: ink,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantCompactStrip extends StatelessWidget {
  const _MerchantCompactStrip({
    required this.merchantName,
    required this.rating,
    required this.reviewCount,
    required this.dur,
    required this.storeOpen,
    required this.stock,
  });

  final String merchantName;
  final double? rating;
  final int? reviewCount;
  final Duration? dur;
  final bool storeOpen;
  final int stock;

  @override
  Widget build(BuildContext context) {
    final showRating = rating != null && rating! > 0;
    final showReviews = reviewCount != null && reviewCount! > 0;
    final showClosing = dur != null;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            merchantName,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (showRating || showReviews) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (showRating) ...[
                  ...List.generate(5, (index) {
                    final r = rating!;
                    return Icon(
                      index < r.floor()
                          ? Icons.star
                          : (index < r ? Icons.star_half : Icons.star_border),
                      color: AppColors.warning,
                      size: 16,
                    );
                  }),
                  const SizedBox(width: 6),
                  Text(
                    rating!.toStringAsFixed(1),
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (showReviews) ...[
                  if (showRating) const SizedBox(width: 6),
                  Text(
                    '($reviewCount reviews)',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppConstants.paddingM,
            runSpacing: 4,
            children: [
              if (showClosing)
                _ClosingTimeBadge(
                  dur: dur!,
                  storeOpen: storeOpen,
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: stock <= 3 ? AppColors.warning : AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$stock left',
                    style: AppTypography.bodySmall.copyWith(
                      color: stock <= 3 ? AppColors.warning : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
