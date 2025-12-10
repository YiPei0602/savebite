import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/constants/app_constants.dart';
import '../providers/food_provider.dart';
import '../models/food_item_model.dart';
import '../utils/price_utils.dart';
import 'merchant_details_screen.dart';

/// Home Screen
/// 
/// Main feed showing surplus food items with dynamic pricing.
/// Features: Search, category filters, dietary filters, location selector.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Load food items if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final foodProvider = context.read<FoodProvider>();
      if (foodProvider.allFoodItems.isEmpty && !foodProvider.isLoading) {
        foodProvider.loadFoodItems();
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
    // Debounce search input (300ms)
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<FoodProvider>().searchFoodItems(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Top Section: Location, Tagline & Search
            _buildTopSection(),
            
            // Dietary Filters
            _buildDietaryFilters(),
            
            // Categories Section
            _buildCategoriesSection(),
            
            // Main Feed: Surplus Near You
            _buildSurplusFeed(),
          ],
        ),
      ),
    );
  }

  /// Top Section: Curved Header with Floating Search
  Widget _buildTopSection() {
    const double headerHeight = 280;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Header background
            Container(
              height: headerHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    AppColors.primary.withOpacity(0.95),
                    AppColors.primary,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(60),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: location + tagline
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Location',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildLocationSelector(),
                            const SizedBox(height: AppConstants.paddingM),
                            Text(
                              'Fresh Food.\nHalf Price.\nZero Waste.',
                              style: AppTypography.h4.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                                fontSize: 32,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      // Right: Hero image
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 16),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Image.asset(
                            'assets/images/bag.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.fastfood,
                                size: 80,
                                color: Colors.white.withOpacity(0.5),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Floating search bar
            Positioned(
              left: AppConstants.paddingM,
              right: AppConstants.paddingM,
              bottom: -24,
              child: _buildSearchBar(),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  /// Location Selector with Dropdown
  Widget _buildLocationSelector() {
    return Consumer<FoodProvider>(
      builder: (context, foodProvider, child) {
        final selectedLocation = foodProvider.selectedLocation ?? 'Penang';
        
        return InkWell(
          onTap: () => _showLocationPicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM,
              vertical: AppConstants.paddingS,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.place, size: 14, color: Colors.white),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingXS),
                Text(
                  selectedLocation,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingXS),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Search Bar with Debounce
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search for surplus food...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    context.read<FoodProvider>().searchFoodItems('');
                  },
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

  /// Dietary Filters (Horizontal Chips)
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
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
            itemCount: dietaryTags.length,
            itemBuilder: (context, index) {
              final tag = dietaryTags[index];
              final isSelected = foodProvider.selectedDietaryTags.contains(tag);
              final tagName = tag.toString().split('.').last;
              final displayName = tagName[0].toUpperCase() + tagName.substring(1);

              return Padding(
                padding: const EdgeInsets.only(right: AppConstants.paddingS),
                child: FilterChip(
                  label: Text(displayName),
                  selected: isSelected,
                  onSelected: (_) => foodProvider.toggleDietaryTag(tag),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.accent,
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  checkmarkColor: Colors.white,
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Categories: 2x3 Grid Layout (Multi-select)
  Widget _buildCategoriesSection() {
    final categories = [
      {'label': 'Mystery Bag', 'category': FoodCategory.mysteryBag, 'icon': Icons.card_giftcard},
      {'label': 'Meals', 'category': FoodCategory.preparedMeals, 'icon': Icons.lunch_dining},
      {'label': 'Desserts', 'category': FoodCategory.desserts, 'icon': Icons.cake},
      {'label': 'Bread', 'category': FoodCategory.bakery, 'icon': Icons.bakery_dining},
      {'label': 'Beverages', 'category': FoodCategory.beverages, 'icon': Icons.local_drink_outlined},
      {'label': 'Snacks', 'category': FoodCategory.snacks, 'icon': Icons.fastfood},
    ];

    return Consumer<FoodProvider>(
      builder: (context, foodProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppConstants.paddingM,
                right: AppConstants.paddingM,
                bottom: 0,
              ),
              child: Text(
                'Category',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Transform.translate(
                offset: const Offset(0, -6),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final c = categories[index];
                    final String label = c['label'] as String;
                    final FoodCategory category = c['category'] as FoodCategory;
                    final bool isSelected = foodProvider.selectedCategories.contains(category);
                    
                    return GestureDetector(
                      onTap: () => foodProvider.toggleCategory(category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.08),
                              AppColors.primary.withOpacity(0.06),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border.withOpacity(0.25),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                c['icon'] as IconData,
                                color: AppColors.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              label,
                              style: AppTypography.bodyMedium.copyWith(
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
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Main Feed: Surplus Near You
  Widget _buildSurplusFeed() {
    return Consumer<FoodProvider>(
      builder: (context, foodProvider, child) {
        if (foodProvider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(AppConstants.paddingXL),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (foodProvider.errorMessage != null) {
          return Padding(
            padding: const EdgeInsets.all(AppConstants.paddingXL),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: AppConstants.paddingM),
                  Text(
                    'Error loading items',
                    style: AppTypography.h5,
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    foodProvider.errorMessage!,
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  ElevatedButton(
                    onPressed: () => foodProvider.loadFoodItems(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final items = foodProvider.displayedFoodItems;

        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppConstants.paddingXL),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: AppConstants.paddingM),
                  Text(
                    'No items found',
                    style: AppTypography.h5,
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    'Try adjusting your filters',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  OutlinedButton(
                    onPressed: () {
                      _searchController.clear();
                      foodProvider.clearFilters();
                    },
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Text(
                'Surplus Near You (${items.length})',
                style: AppTypography.h4,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildSurplusCard(item);
              },
            ),
          ],
        );
      },
    );
  }

  /// Surplus Food Card with Dynamic Pricing
  Widget _buildSurplusCard(FoodItemModel item) {
    // Compute dynamic discount and price
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

    final bool isClosingSoon = PriceUtils.isClosingSoon(
      closingTime: item.closingTime,
      thresholdMinutes: 30,
    );

    final String timeRemaining = PriceUtils.formatTimeRemaining(item.closingTime);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MerchantDetailsScreen(
                merchantName: item.merchantName,
                imageUrl: item.imageUrl,
                rating: item.rating ?? 4.5,
                pickupHoursRemaining: 2,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Image
            _buildCardImage(item.imageUrl),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Name
                  Text(
                    item.merchantName,
                    style: AppTypography.h5,
                  ),

                  const SizedBox(height: AppConstants.paddingS),

                  // Rating & Closing Soon Row
                  Row(
                    children: [
                      // Rating
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppConstants.paddingXS),
                      Text(
                        '${item.rating ?? 4.5}',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const Spacer(),

                      // Closing Soon Tag with Countdown
                      if (isClosingSoon)
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
                              const Icon(
                                Icons.access_time,
                                size: 12,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: AppConstants.paddingXS),
                              Text(
                                timeRemaining,
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

                  // Dynamic Price Section
                  Row(
                    children: [
                      // Original Price (Strikethrough)
                      Text(
                        '${AppConstants.currencySymbol}${item.originalPrice.toStringAsFixed(2)}',
                        style: AppTypography.bodyMedium.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(width: AppConstants.paddingS),

                      // Dynamic Discounted Price (Orange, Bold)
                      Text(
                        '${AppConstants.currencySymbol}${dynamicPrice.toStringAsFixed(2)}',
                        style: AppTypography.h5.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Spacer(),

                      // Dynamic Discount Percentage
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
                          '-$currentDiscount%',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textOnAccent,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  /// Card Image with Placeholder
  Widget _buildCardImage(String imageUrl) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
      ),
      child: Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: AppColors.primaryLight.withOpacity(0.3),
            child: Center(
              child: Icon(
                Icons.fastfood,
                size: 60,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            color: AppColors.surfaceVariant,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: AppColors.primary,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Show Location Picker Dialog
  void _showLocationPicker() {
    final foodProvider = context.read<FoodProvider>();
    final locations = foodProvider.getAvailableLocations();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusL)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Location',
                style: AppTypography.h4,
              ),
              const SizedBox(height: AppConstants.paddingM),
              ...locations.map((location) {
                final isSelected = foodProvider.selectedLocation == location;
                return ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  title: Text(
                    location,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
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
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
