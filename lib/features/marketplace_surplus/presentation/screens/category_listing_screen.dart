import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/food_item_model.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/food_provider.dart';
import 'package:savebite/features/orders_payments/state/providers/cart_provider.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/merchant_model.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/merchant_provider.dart';
import 'package:savebite/shared/utils/merchant_display_name_utils.dart';
import 'package:savebite/shared/utils/surplus_sellability_utils.dart';
import 'package:savebite/shared/widgets/app_back_button.dart';

class CategoryListingScreen extends StatefulWidget {
  const CategoryListingScreen({super.key, required this.category, this.items});

  final String category;
  final List<Map<String, dynamic>>? items;

  @override
  State<CategoryListingScreen> createState() => _CategoryListingScreenState();
}

class _CategoryListingScreenState extends State<CategoryListingScreen> {
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
      context.read<FoodProvider>().loadFoodItems();
      final mp = context.read<MerchantProvider>();
      if (mp.merchants.isEmpty && !mp.isLoading) {
        mp.loadMerchants();
      }
    });
  }

  bool _isDietaryTag(String categoryName) {
    final dietaryTags = ['halal', 'vegetarian', 'vegan', 'glutenfree'];
    return dietaryTags.contains(categoryName.toLowerCase());
  }

  bool _isCombinedCategory(String categoryName) {
    return false;
  }

  bool _isBakeryCategory(String categoryName) {
    return categoryName.toLowerCase() == 'bakery';
  }

  bool _shouldHideFilters(String categoryName) {
    final hideFiltersCategories = [
      'bakery',
      'mysterybag',
      'preparedmeals',
      'beverages'
    ];
    return hideFiltersCategories.contains(categoryName.toLowerCase());
  }

  DietaryTag? _getDietaryTagFromString(String tagName) {
    try {
      return DietaryTag.values.firstWhere(
        (tag) => tag.name.toLowerCase() == tagName.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  FoodCategory? _getCategoryFromString(String categoryName) {
    try {
      return FoodCategory.values.firstWhere(
        (cat) => cat.name == categoryName,
      );
    } catch (_) {
      try {
        return FoodCategory.values.firstWhere(
          (cat) =>
              cat.name.toLowerCase() == categoryName.toLowerCase() ||
              _getCategoryDisplayName(cat).toLowerCase() ==
                  categoryName.toLowerCase(),
        );
      } catch (_) {
        return null;
      }
    }
  }

  String _getCategoryDisplayName(FoodCategory category) {
    switch (category) {
      case FoodCategory.mysteryBag:
        return 'Mystery Bag';
      case FoodCategory.preparedMeals:
        return 'Meals';
      case FoodCategory.desserts:
        return 'Desserts';
      case FoodCategory.bakery:
        return 'Bread';
      case FoodCategory.beverages:
        return 'Beverages';
      case FoodCategory.groceries:
        return 'Groceries';
      case FoodCategory.snacks:
        return 'Snacks';
      case FoodCategory.meats:
        return 'Meats';
      case FoodCategory.vegetables:
        return 'Vegetables';
      case FoodCategory.dairy:
        return 'Dairy';
      case FoodCategory.other:
        return 'Other';
    }
  }

  String _getCategoryTitle() {
    if (_isDietaryTag(widget.category)) {
      final tag = _getDietaryTagFromString(widget.category);
      if (tag != null) {
        switch (tag) {
          case DietaryTag.halal:
            return 'Halal';
          case DietaryTag.vegetarian:
            return 'Vegetarian';
          case DietaryTag.vegan:
            return 'Vegan';
          case DietaryTag.glutenFree:
            return 'Gluten-Free';
          default:
            return widget.category;
        }
      }
    }

    if (_isBakeryCategory(widget.category)) {
      return 'Bakery';
    }

    final categoryEnum = _getCategoryFromString(widget.category);
    if (categoryEnum != null) {
      return _getCategoryDisplayName(categoryEnum);
    }

    return widget.category
        .split(RegExp(r'(?=[A-Z])'))
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        leading: const AppBackButton(color: AppColors.textPrimary),
        title: Text(_getCategoryTitle(), style: AppTypography.h4),
        centerTitle: true,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              final cartItemCount = cartProvider.itemCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: AppColors.textPrimary),
                    onPressed: () => context.push('/cart'),
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$cartItemCount',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isDietaryTag(widget.category) &&
              !_shouldHideFilters(widget.category))
            _buildDietaryFilters(),
          Expanded(
            child: Consumer2<FoodProvider, MerchantProvider>(
              builder: (context, foodProvider, merchantProvider, child) {
                List<FoodItemModel> filteredItems;

                if (foodProvider.isLoading || merchantProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final now = DateTime.now();
                MerchantModel? mFor(String id) {
                  for (final m in merchantProvider.merchants) {
                    if (m.id == id) return m;
                  }
                  return null;
                }

                final pool = foodProvider.displayedFoodItems.toList();

                if (_isDietaryTag(widget.category)) {
                  final tag = _getDietaryTagFromString(widget.category);
                  if (tag != null) {
                    filteredItems = pool
                        .where((item) => item.dietaryTags.contains(tag))
                        .toList();
                  } else {
                    filteredItems = pool;
                  }
                } else if (_isBakeryCategory(widget.category)) {
                  filteredItems = pool
                      .where((item) =>
                          item.effectiveCategories.contains(FoodCategory.bakery))
                      .toList();
                } else {
                  final categoryEnum = _getCategoryFromString(widget.category);
                  filteredItems = categoryEnum != null
                      ? pool
                          .where((item) =>
                              item.effectiveCategories.contains(categoryEnum))
                          .toList()
                      : pool;
                }

                if (foodProvider.selectedDietaryTags.isNotEmpty &&
                    !_isDietaryTag(widget.category)) {
                  filteredItems = filteredItems.where((item) {
                    return foodProvider.selectedDietaryTags
                        .any((tag) => item.dietaryTags.contains(tag));
                  }).toList();
                }

                final selectedLocation = foodProvider.selectedLocation;
                if (selectedLocation != null &&
                    selectedLocation.trim().isNotEmpty) {
                  filteredItems = filteredItems
                      .where(
                        (item) => _merchantMatchesSelectedLocation(
                          mFor(item.merchantId),
                          selectedLocation,
                        ),
                      )
                      .toList();
                }

                if (filteredItems.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) => _buildItemCard(
                    context,
                    filteredItems[index],
                    merchantProfile: mFor(filteredItems[index].merchantId),
                    now: now,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryFilters() {
    return Consumer<FoodProvider>(
      builder: (context, foodProvider, child) {
        final dietaryTags = [
          DietaryTag.halal,
          DietaryTag.vegetarian,
          DietaryTag.vegan,
          DietaryTag.glutenFree,
        ];

        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: const Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
            itemCount: dietaryTags.length,
            itemBuilder: (context, index) {
              final tag = dietaryTags[index];
              final isSelected = foodProvider.selectedDietaryTags.contains(tag);
              final tagName = tag.toString().split('.').last;
              final displayName = tagName[0].toUpperCase() +
                  tagName.substring(1).replaceAllMapped(
                        RegExp(r'([A-Z])'),
                        (match) => ' ${match.group(1)}',
                      );

              return Padding(
                padding: const EdgeInsets.only(right: AppConstants.paddingS),
                child: ChoiceChip(
                  label: Text(
                    displayName,
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => foodProvider.toggleDietaryTag(tag),
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primary,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingM,
                    vertical: AppConstants.paddingXS,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off,
              size: 64, color: AppColors.textSecondary.withOpacity(0.6)),
          const SizedBox(height: AppConstants.paddingM),
          Text('No items found', style: AppTypography.h5),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            'Please check back later for fresh surplus items in this category.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    FoodItemModel item, {
    MerchantModel? merchantProfile,
    required DateTime now,
  }) {
    final unavailable = isConsumerListingUnavailableForDisplay(item, now);
    final shopName = consumerShopDisplayName(
      merchantId: item.merchantId,
      merchantProfile: merchantProfile,
      fromFoodItem: item.merchantName,
    );

    final card = Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: InkWell(
        onTap: () => context.push('/merchant/${item.merchantId}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardImage(item.imageUrl, unavailable: unavailable),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTypography.h5),
                  const SizedBox(height: AppConstants.paddingXS),
                  Text(
                    shopName,
                    style: AppTypography.bodySmall.copyWith(
                      color: unavailable
                          ? AppColors.textTertiary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: AppConstants.paddingXS),
                      Text('1.8 km', style: AppTypography.bodySmall),
                      const SizedBox(width: AppConstants.paddingM),
                      const Icon(Icons.star, size: 16, color: AppColors.warning),
                      const SizedBox(width: AppConstants.paddingXS),
                      Text(
                        item.rating?.toStringAsFixed(1) ?? '4.5',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (unavailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingS,
                            vertical: AppConstants.paddingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textTertiary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppConstants.radiusS),
                          ),
                          child: Text(
                            'Unavailable',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (item.isClosingSoon)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingS,
                            vertical: AppConstants.paddingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConstants.radiusS),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time,
                                  size: 12, color: AppColors.error),
                              const SizedBox(width: AppConstants.paddingXS),
                              Text(
                                'Closing Soon',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  Row(
                    children: [
                      Text(
                        'RM ${item.originalPrice.toStringAsFixed(2)}',
                        style: AppTypography.bodyMedium.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      Text(
                        'RM ${item.effectiveDiscountedPrice.toStringAsFixed(2)}',
                        style: AppTypography.h5.copyWith(
                          color: unavailable
                              ? AppColors.textTertiary
                              : AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingS,
                          vertical: AppConstants.paddingXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(AppConstants.radiusS),
                        ),
                        child: Text(
                          '-${item.effectiveDiscountPercentage}%',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textOnAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: unavailable
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'This listing is unavailable.',
                                  ),
                                ),
                              );
                            }
                          : () => _addToCart(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: unavailable
                            ? AppColors.textTertiary
                            : AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        ),
                      ),
                      icon: Icon(
                        Icons.add_shopping_cart,
                        size: 20,
                        color: unavailable
                            ? Colors.white.withOpacity(0.7)
                            : Colors.white,
                      ),
                      label: Text(
                        unavailable ? 'Unavailable' : 'Add to Cart',
                        style: AppTypography.buttonMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (unavailable) return Opacity(opacity: 0.72, child: card);
    return card;
  }

  void _addToCart(FoodItemModel item) {
    final cartProvider = context.read<CartProvider>();
    cartProvider.addItem(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
  }

  Widget _buildCardImage(String imageUrl, {bool unavailable = false}) {
    Widget imageBody;
    if (imageUrl.isEmpty) {
      imageBody = Container(
        color: AppColors.primaryLight.withOpacity(0.3),
        child: Center(
          child: Icon(
            Icons.fastfood,
            size: 60,
            color: AppColors.primary.withOpacity(0.5),
          ),
        ),
      );
    } else if (imageUrl.startsWith('assets/')) {
      imageBody = Image.asset(
        imageUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      imageBody = Image.network(
        imageUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.primaryLight.withOpacity(0.3),
          child: Center(
            child: Icon(
              Icons.fastfood,
              size: 60,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageBody,
          if (unavailable)
            Container(
              color: Colors.black.withOpacity(0.45),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Unavailable',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

