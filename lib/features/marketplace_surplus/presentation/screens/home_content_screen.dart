import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/shared/utils/price_utils.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/food_item_model.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/merchant_model.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/food_provider.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/merchant_provider.dart';
import 'package:savebite/shared/utils/merchant_display_name_utils.dart';
import 'package:savebite/shared/utils/surplus_sellability_utils.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/core/constants/app_constants.dart';

const Color _homeSecondaryGrey = Color(0xFF60646C);
const Color _homeAccentSoft = Color(0xFFFFF1E8);

final List<BoxShadow> _elevationLow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 10,
    offset: const Offset(0, 4),
  ),
];

final List<BoxShadow> _elevationMedium = [
  BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 16,
    offset: const Offset(0, 8),
  ),
];

/// Home Content Screen
///
/// Consumer marketplace home feed (UI-first).
/// Focuses on modern marketplace layout: greeting, location, search, categories,
/// and recommended deals near you.
class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  static const List<String> _supportedLocations = <String>[
    'Johor',
    'Kuala Lumpur',
    'Penang',
    'Selangor',
  ];

  bool _merchantMatchesSelectedLocation(
    MerchantModel? merchant,
    String selectedLocation,
  ) {
    final addr = (merchant?.address ?? '').toLowerCase();
    final selected = selectedLocation.toLowerCase();
    if (addr.isEmpty || selected.isEmpty) return false;

    switch (selected) {
      case 'johor':
        return addr.contains('johor');
      case 'kuala lumpur':
        return addr.contains('kuala lumpur') ||
            addr.contains('wilayah persekutuan kuala lumpur') ||
            addr.contains('w.p. kuala lumpur');
      case 'penang':
        return addr.contains('penang') || addr.contains('pulau pinang');
      case 'selangor':
        return addr.contains('selangor');
      default:
        return addr.contains(selected);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final foodProvider = context.read<FoodProvider>();
      if (foodProvider.allFoodItems.isEmpty && !foodProvider.isLoading) {
        foodProvider.loadFoodItems();
      }
      if (foodProvider.selectedLocation == null) {
        foodProvider.setLocation('Penang');
      }
      final mp = context.read<MerchantProvider>();
      if (mp.merchants.isEmpty && !mp.isLoading) {
        mp.loadMerchants();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<FoodProvider>().searchFoodItems(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppConstants.paddingS),
                Consumer<FoodProvider>(
                  builder: (context, foodProvider, _) {
                    final current = (foodProvider.selectedLocation != null &&
                            _supportedLocations
                                .contains(foodProvider.selectedLocation))
                        ? foodProvider.selectedLocation!
                        : 'Penang';

                    return _GreetingHeader(
                      location: current,
                      onLocationTap: _showLocationPicker,
                      onNotificationsTap: () => context.push('/notifications'),
                    );
                  },
                ),
                const SizedBox(height: AppConstants.paddingM),
                _SearchBar(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onClear: () {
                    _searchController.clear();
                    context.read<FoodProvider>().searchFoodItems('');
                    setState(() {});
                  },
                ),
                const SizedBox(height: AppConstants.paddingL),
                const _SectionTitle(title: 'Categories'),
                const SizedBox(height: AppConstants.paddingM),
                _CategoryGrid(
                  onCategoryTap: (action) {
                    if (action.route != null) {
                      context.push(action.route!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppConstants.paddingL),
                const _SectionTitle(title: 'Recommended Near You'),
                const SizedBox(height: AppConstants.paddingM),
                Consumer2<FoodProvider, MerchantProvider>(
                  builder: (context, foodProvider, merchantProvider, _) {
                    if (foodProvider.isLoading || merchantProvider.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: AppConstants.paddingL),
                        child: _PremiumLoadingState(),
                      );
                    }

                    if (foodProvider.errorMessage != null) {
                      return _InlineErrorState(
                        message: 'Unable to load recommendations.',
                        detail: foodProvider.errorMessage!,
                        onRetry: () => foodProvider.loadFoodItems(),
                      );
                    }

                    final now = DateTime.now();
                    MerchantModel? mFor(String id) {
                      for (final m in merchantProvider.merchants) {
                        if (m.id == id) return m;
                      }
                      return null;
                    }

                    final selectedLocation = foodProvider.selectedLocation;
                    final items = foodProvider.displayedFoodItems.toList()
                      ..sort((a, b) {
                        final ua =
                            isConsumerListingUnavailableForDisplay(a, now)
                                ? 1
                                : 0;
                        final ub =
                            isConsumerListingUnavailableForDisplay(b, now)
                                ? 1
                                : 0;
                        if (ua != ub) return ua.compareTo(ub);
                        return b.createdAt.compareTo(a.createdAt);
                      });
                    final filteredByLocation = (selectedLocation == null ||
                            selectedLocation.trim().isEmpty)
                        ? items
                        : items
                            .where(
                              (item) => _merchantMatchesSelectedLocation(
                                mFor(item.merchantId),
                                selectedLocation,
                              ),
                            )
                            .toList(growable: false);

                    if (filteredByLocation.isEmpty) {
                      return _InlineEmptyState(
                        title: 'No recommendations yet',
                        subtitle:
                            'Surplus deals will appear here once merchants publish listings.',
                        onExploreTap: () =>
                            context.push('/category/mysteryBag'),
                      );
                    }

                    final recommended =
                        filteredByLocation.take(10).toList(growable: false);
                    return Column(
                      children: [
                        for (final item in recommended.take(6)) ...[
                          _WideDealCard(
                            item: item,
                            shopDisplayName: consumerShopDisplayName(
                              merchantId: item.merchantId,
                              merchantProfile: mFor(item.merchantId),
                              fromFoodItem: item.merchantName,
                            ),
                            unavailable: isConsumerListingUnavailableForDisplay(
                                item, now),
                            onTap: () => context.push(
                              '/merchant/${item.merchantId}/item/${item.id}',
                              extra: item,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingM),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppConstants.paddingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show Location Picker Dialog
  void _showLocationPicker() {
    final foodProvider = context.read<FoodProvider>();
    const locations = _supportedLocations;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppConstants.radiusL)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Location', style: AppTypography.h4),
              const SizedBox(height: AppConstants.paddingM),
              ...locations.map((location) {
                final isSelected = foodProvider.selectedLocation == location;
                return ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: isSelected ? AppColors.primary : _homeSecondaryGrey,
                  ),
                  title: Text(
                    location,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    foodProvider.setLocation(location);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final String location;
  final VoidCallback onLocationTap;
  final VoidCallback onNotificationsTap;

  const _GreetingHeader({
    required this.location,
    required this.onLocationTap,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final rawFirstName = authProvider.currentUser?.firstName.trim();
        final firstName = (rawFirstName == null || rawFirstName.isEmpty)
            ? 'there'
            : rawFirstName;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _LocationSelector(location: location, onTap: onLocationTap),
                const Spacer(),
                _NotificationButton(onTap: onNotificationsTap),
              ],
            ),
            const SizedBox(height: 14),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Hello, ',
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.w400,
                      color: _homeSecondaryGrey,
                    ),
                  ),
                  TextSpan(
                    text: '$firstName 👋',
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Together, good food deserves a second chance',
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NotificationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppConstants.radiusL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            border: Border.all(color: AppColors.border.withOpacity(0.6)),
            boxShadow: _elevationLow,
          ),
          child: const Icon(
            Icons.notifications_none,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _LocationSelector extends StatelessWidget {
  final String location;
  final VoidCallback onTap;

  const _LocationSelector({
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxTextWidth = MediaQuery.sizeOf(context).width * 0.42;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place, color: _homeSecondaryGrey, size: 18),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxTextWidth),
              child: Text(
                location,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down, color: _homeSecondaryGrey),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: _elevationLow,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search surplus food, stores, or meals',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: _homeSecondaryGrey,
          ),
          prefixIcon: const Icon(Icons.search, color: _homeSecondaryGrey),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: _homeSecondaryGrey),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingM,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.h3.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _CategoryAction {
  final String shortLabel;
  final String imagePath;
  final String? route;

  const _CategoryAction({
    required this.shortLabel,
    required this.imagePath,
    required this.route,
  });
}

class _CategoryGrid extends StatelessWidget {
  final void Function(_CategoryAction action) onCategoryTap;

  const _CategoryGrid({required this.onCategoryTap});

  static const _actions = <_CategoryAction>[
    _CategoryAction(
      shortLabel: 'Mystery',
      imagePath: 'assets/images/mysterybag.png',
      route: '/category/mysteryBag',
    ),
    _CategoryAction(
      shortLabel: 'Meals',
      imagePath: 'assets/images/meals.png',
      route: '/category/preparedMeals',
    ),
    _CategoryAction(
      shortLabel: 'Bakeries',
      imagePath: 'assets/images/bakeries.png',
      route: '/category/bakery',
    ),
    _CategoryAction(
      shortLabel: 'Drinks',
      imagePath: 'assets/images/beverages.png',
      route: '/category/beverages',
    ),
    _CategoryAction(
      shortLabel: 'Snacks',
      imagePath: 'assets/images/snacks.png',
      route: '/category/snacks',
    ),
    _CategoryAction(
      shortLabel: 'Veggie',
      imagePath: 'assets/images/vegetarian.png',
      route: '/category/vegetarian',
    ),
    _CategoryAction(
      shortLabel: 'Halal',
      imagePath: 'assets/images/halal.png',
      route: '/category/halal',
    ),
    _CategoryAction(
      shortLabel: 'Groceries',
      imagePath: 'assets/images/groceries.png',
      route: '/category/groceries',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final action = _actions[index];
          return _CategoryCard(
            shortLabel: action.shortLabel,
            imagePath: action.imagePath,
            onTap: () => onCategoryTap(action),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String shortLabel;
  final String imagePath;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.shortLabel,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.fastfood_rounded,
                            color: AppColors.primary,
                            size: 28,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  shortLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final FoodItemModel item;
  final VoidCallback onTap;

  const _StoreCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final discountRange = item.discountRange;
    final int currentDiscount = discountRange != null
        ? PriceUtils.computeDynamicDiscount(
            minPercent: discountRange.minPercent,
            maxPercent: discountRange.maxPercent,
            closingTime: item.closingTime,
          )
        : item.discountPercentage;

    final double dynamicPrice = PriceUtils.computeDiscountedPrice(
      originalPrice: item.originalPrice,
      discountPercent: currentDiscount,
    );

    final pickupText = PriceUtils.formatTimeRemaining(item.closingTime);

    return SizedBox(
      width: 190,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              border: Border.all(color: AppColors.border.withOpacity(0.55)),
              boxShadow: _elevationMedium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppConstants.radiusL),
                  ),
                  child: SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _NetworkImage(imageUrl: item.imageUrl),
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '-$currentDiscount%',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textOnAccent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.merchantName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            '${item.rating ?? 4.5}',
                            style: AppTypography.caption.copyWith(
                              color: _homeSecondaryGrey,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.place,
                              size: 14, color: _homeSecondaryGrey),
                          const SizedBox(width: 4),
                          Text(
                            '— km',
                            style: AppTypography.caption.copyWith(
                              color: _homeSecondaryGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: _homeSecondaryGrey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Pickup: $pickupText',
                              style: AppTypography.caption.copyWith(
                                color: _homeSecondaryGrey,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            '${AppConstants.currencySymbol}${item.originalPrice.toStringAsFixed(2)}',
                            style: AppTypography.caption.copyWith(
                              color: _homeSecondaryGrey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${AppConstants.currencySymbol}${dynamicPrice.toStringAsFixed(2)}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
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
  }
}

class _WideDealCard extends StatelessWidget {
  final FoodItemModel item;
  final String shopDisplayName;
  final bool unavailable;
  final VoidCallback onTap;

  const _WideDealCard({
    required this.item,
    required this.shopDisplayName,
    required this.unavailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final discountRange = item.discountRange;
    final int currentDiscount = discountRange != null
        ? PriceUtils.computeDynamicDiscount(
            minPercent: discountRange.minPercent,
            maxPercent: discountRange.maxPercent,
            closingTime: item.closingTime,
          )
        : item.discountPercentage;

    final double dynamicPrice = PriceUtils.computeDiscountedPrice(
      originalPrice: item.originalPrice,
      discountPercent: currentDiscount,
    );

    final pickupText = unavailable
        ? 'Unavailable'
        : PriceUtils.formatTimeRemaining(item.closingTime);

    final card = Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppConstants.radiusL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            border: Border.all(color: AppColors.border.withOpacity(0.55)),
            boxShadow: _elevationMedium,
          ),
          child: Row(
            // Important: avoid `stretch` inside an unbounded-height scroll view.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppConstants.radiusL),
                ),
                child: SizedBox(
                  width: 118,
                  height: 126,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _NetworkImage(imageUrl: item.imageUrl),
                      if (!unavailable)
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '-$currentDiscount%',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textOnAccent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      if (unavailable)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.45),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Unavailable',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w800,
                                ),
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
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        shopDisplayName,
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.w800,
                          color: unavailable
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.name,
                        style: AppTypography.bodySmall.copyWith(
                          color: unavailable
                              ? AppColors.textTertiary
                              : _homeSecondaryGrey,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            '${item.rating ?? 4.5}',
                            style: AppTypography.caption.copyWith(
                              color: _homeSecondaryGrey,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: _homeSecondaryGrey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              unavailable
                                  ? 'Unavailable'
                                  : 'Pickup: $pickupText',
                              style: AppTypography.caption.copyWith(
                                color: unavailable
                                    ? AppColors.textTertiary
                                    : _homeSecondaryGrey,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            '${AppConstants.currencySymbol}${item.originalPrice.toStringAsFixed(2)}',
                            style: AppTypography.caption.copyWith(
                              color: _homeSecondaryGrey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${AppConstants.currencySymbol}${dynamicPrice.toStringAsFixed(2)}',
                            style: AppTypography.h5.copyWith(
                              color: unavailable
                                  ? AppColors.textTertiary
                                  : AppColors.accent,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (unavailable) {
      return Opacity(opacity: 0.72, child: card);
    }
    return card;
  }
}

class _NetworkImage extends StatelessWidget {
  final String imageUrl;

  const _NetworkImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl, fit: BoxFit.cover);
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.surfaceVariant,
          child: Center(
            child: Icon(
              Icons.fastfood,
              size: 42,
              color: _homeSecondaryGrey.withOpacity(0.7),
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppColors.surfaceVariant,
          child: const Center(
            child: SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}

class _PremiumLoadingState extends StatefulWidget {
  const _PremiumLoadingState();

  @override
  State<_PremiumLoadingState> createState() => _PremiumLoadingStateState();
}

class _PremiumLoadingStateState extends State<_PremiumLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shimmerStrength = 0.08 + (_controller.value * 0.08);
        final shimmer = AppColors.primary.withOpacity(shimmerStrength);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LoadingBlock(
              widthFactor: 0.42,
              height: 16,
              color: shimmer,
            ),
            const SizedBox(height: 10),
            _LoadingBlock(
              widthFactor: 0.68,
              height: 14,
              color: shimmer,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 235,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppConstants.paddingM),
                itemBuilder: (context, index) {
                  return Container(
                    width: 190,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                      boxShadow: _elevationLow,
                      border:
                          Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: shimmer,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppConstants.radiusL),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              _LoadingBlock(
                                widthFactor: 1.0,
                                height: 12,
                                color: shimmer,
                              ),
                              const SizedBox(height: 8),
                              _LoadingBlock(
                                widthFactor: 0.7,
                                height: 10,
                                color: shimmer,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  final double widthFactor;
  final double height;
  final Color color;

  const _LoadingBlock({
    required this.widthFactor,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onExploreTap;

  const _InlineEmptyState({
    required this.title,
    required this.subtitle,
    required this.onExploreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.border.withOpacity(0.45)),
        boxShadow: _elevationLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: _homeAccentSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: AppColors.accent,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTypography.h5.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(color: _homeSecondaryGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onExploreTap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              backgroundColor: _homeAccentSoft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.explore_outlined, size: 18),
            label: const Text('Explore categories'),
          ),
        ],
      ),
    );
  }
}

class _InlineErrorState extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;

  const _InlineErrorState({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
        boxShadow: _elevationLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: AppTypography.bodySmall.copyWith(color: _homeSecondaryGrey),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}
