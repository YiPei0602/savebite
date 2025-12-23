import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../models/food_item_model.dart';
import '../providers/food_provider.dart';
import '../../cart/providers/cart_provider.dart';

class CategoryListingScreen extends StatefulWidget {
  const CategoryListingScreen({super.key, required this.category, this.items});

  final String category;
  final List<Map<String, dynamic>>? items;

  @override
  State<CategoryListingScreen> createState() => _CategoryListingScreenState();
}

class _CategoryListingScreenState extends State<CategoryListingScreen> {
  @override
  void initState() {
    super.initState();
    // Load food items when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodProvider>().loadFoodItems();
    });
  }

  bool _isDietaryTag(String categoryName) {
    final dietaryTags = ['halal', 'vegetarian', 'vegan', 'glutenfree'];
    return dietaryTags.contains(categoryName.toLowerCase());
  }

  bool _isCombinedCategory(String categoryName) {
    return false; // No longer using combined category
  }
  
  bool _isBakeryCategory(String categoryName) {
    return categoryName.toLowerCase() == 'bakery';
  }
  
  bool _shouldHideFilters(String categoryName) {
    // Hide filters for: Bakery, Mystery Bag, Meals, Beverages
    final hideFiltersCategories = ['bakery', 'mysterybag', 'preparedmeals', 'beverages'];
    return hideFiltersCategories.contains(categoryName.toLowerCase());
  }

  DietaryTag? _getDietaryTagFromString(String tagName) {
    try {
      return DietaryTag.values.firstWhere(
        (tag) => tag.name.toLowerCase() == tagName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  FoodCategory? _getCategoryFromString(String categoryName) {
    // Convert string to enum (handle enum names like "mysteryBag", "preparedMeals", "bakery")
    try {
      // First try exact match (enum name from navigation)
      return FoodCategory.values.firstWhere(
        (cat) => cat.name == categoryName,
      );
    } catch (e) {
      // If not found, try case-insensitive match
      try {
        return FoodCategory.values.firstWhere(
          (cat) => cat.name.toLowerCase() == categoryName.toLowerCase() ||
                   _getCategoryDisplayName(cat).toLowerCase() == categoryName.toLowerCase(),
        );
      } catch (e2) {
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
    // Check if it's a dietary tag
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
    
    // Handle Bakery category
    if (_isBakeryCategory(widget.category)) {
      return 'Bakery';
    }
    
    final categoryEnum = _getCategoryFromString(widget.category);
    if (categoryEnum != null) {
      return _getCategoryDisplayName(categoryEnum);
    }
    // Fallback: capitalize first letter of each word
    return widget.category
        .split(RegExp(r'(?=[A-Z])'))
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text(_getCategoryTitle(), style: AppTypography.h4),
        centerTitle: true,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              final cartItemCount = cartProvider.itemCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
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
          // Dietary Filters (only show if not already filtering by dietary tag and not in excluded categories)
          if (!_isDietaryTag(widget.category) && !_shouldHideFilters(widget.category)) _buildDietaryFilters(),
          
          // Items List
          Expanded(
            child: Consumer<FoodProvider>(
              builder: (context, foodProvider, child) {
                List<FoodItemModel> filteredItems;
                
                // Check if filtering by dietary tag
                if (_isDietaryTag(widget.category)) {
                  final tag = _getDietaryTagFromString(widget.category);
                  if (tag != null) {
                    filteredItems = foodProvider.allFoodItems
                        .where((item) => item.dietaryTags.contains(tag))
                        .toList();
                  } else {
                    filteredItems = foodProvider.allFoodItems;
                  }
                }
                // Handle Bakery category
                else if (_isBakeryCategory(widget.category)) {
                  filteredItems = foodProvider.allFoodItems
                      .where((item) => item.category == FoodCategory.bakery)
                      .toList();
                }
                // Regular category filter
                else {
                  final categoryEnum = _getCategoryFromString(widget.category);
                  filteredItems = categoryEnum != null
                      ? foodProvider.allFoodItems.where((item) => item.category == categoryEnum).toList()
                      : foodProvider.allFoodItems;
                }
                
                // Apply additional dietary filters if any are selected
                if (foodProvider.selectedDietaryTags.isNotEmpty && !_isDietaryTag(widget.category)) {
                  filteredItems = filteredItems.where((item) {
                    return foodProvider.selectedDietaryTags.any((tag) => item.dietaryTags.contains(tag));
                  }).toList();
                }

                if (foodProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (filteredItems.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) => _buildItemCard(context, filteredItems[index]),
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
            border: Border(
              bottom: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
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
              final displayName = tagName[0].toUpperCase() + tagName.substring(1).replaceAllMapped(
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
          Icon(Icons.search_off, size: 64, color: AppColors.textSecondary.withOpacity(0.6)),
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

  Widget _buildItemCard(BuildContext context, FoodItemModel item) {
    return Card(
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
            _buildCardImage(item.imageUrl),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTypography.h5,
                  ),
                  const SizedBox(height: AppConstants.paddingXS),
                  Text(
                    item.merchantName,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: AppConstants.paddingXS),
                      Text('1.8 km', style: AppTypography.bodySmall),
                      const SizedBox(width: AppConstants.paddingM),
                      const Icon(Icons.star, size: 16, color: AppColors.warning),
                      const SizedBox(width: AppConstants.paddingXS),
                      Text(
                        item.rating?.toStringAsFixed(1) ?? '4.5',
                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      if (item.isClosingSoon)
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
                              const Icon(Icons.access_time, size: 12, color: AppColors.error),
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
                        'RM ${item.discountedPrice.toStringAsFixed(2)}',
                        style: AppTypography.h5.copyWith(
                          color: AppColors.accent,
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
                          '-${item.discountPercentage}%',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textOnAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _addToCart(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingM),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        ),
                      ),
                      icon: const Icon(Icons.add_shopping_cart, size: 20, color: Colors.white),
                      label: Text('Add to Cart', style: AppTypography.buttonMedium.copyWith(color: Colors.white)),
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

  Widget _buildCardImage(String imageUrl) {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppColors.surfaceVariant,
      child: Image.network(
        imageUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.primaryLight.withOpacity(0.3),
          child: Center(
            child: Icon(Icons.fastfood, size: 60, color: AppColors.primary.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }
}
