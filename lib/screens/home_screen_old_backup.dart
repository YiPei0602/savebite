import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/constants/app_constants.dart';
import '../core/widgets/header_clipper.dart';
import 'merchant_details_screen.dart';
import 'category_listing_screen.dart';

/// Home Screen
/// 
/// Main feed showing surplus food items near the user's location.
/// Features: Location selector, search bar, category filters, and food cards.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedLocation = 'Penang';
  String _selectedCategory = '';
  String _selectedMode = 'Delivery';
  bool _nearMeOnly = false;

  // Dummy data for surplus food items
  final List<Map<String, dynamic>> _surplusItems = [
    {
      'restaurantName': 'Nasi Kandar Pelita',
      'imageUrl': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800',
      'distance': 2.3,
      'rating': 4.5,
      'originalPrice': 25.00,
      'discountedPrice': 12.50,
      'closingSoon': true,
      'category': 'Halal',
    },
    {
      'restaurantName': 'The Baker\'s Cottage',
      'imageUrl': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800',
      'distance': 1.8,
      'rating': 4.7,
      'originalPrice': 18.00,
      'discountedPrice': 8.00,
      'closingSoon': true,
      'category': 'Bakery',
    },
    {
      'restaurantName': 'Green Leaf Cafe',
      'imageUrl': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
      'distance': 3.5,
      'rating': 4.3,
      'originalPrice': 22.00,
      'discountedPrice': 11.00,
      'closingSoon': false,
      'category': 'Vegetarian',
    },
    {
      'restaurantName': 'KFC Gurney Plaza',
      'imageUrl': 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=800',
      'distance': 4.2,
      'rating': 4.6,
      'originalPrice': 30.00,
      'discountedPrice': 15.00,
      'closingSoon': true,
      'category': 'Fast Food',
    },
    {
      'restaurantName': 'Mystery Bag - Baker\'s Surprise',
      'imageUrl': 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800',
      'distance': 1.2,
      'rating': 4.2,
      'originalPrice': 28.00,
      'discountedPrice': 10.00,
      'closingSoon': false,
      'category': 'Mystery Bag',
    },
    {
      'restaurantName': 'Bubble Tea Station',
      'imageUrl': 'https://images.unsplash.com/photo-1525385133512-2f3bdd039054?w=800',
      'distance': 2.8,
      'rating': 4.4,
      'originalPrice': 15.00,
      'discountedPrice': 7.50,
      'closingSoon': false,
      'category': 'Beverages',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Top Section: Location, Tagline & Search (extends into SafeArea)
            _buildTopSection(),
            
            // Categories Section with title
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
            // Header background with custom curve clipper
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
                              'Looking to\nSave Meals,\nSave Money?\nGet It!',
                              style: AppTypography.h4.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                fontSize: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      // Right: Hero image (bag) - positioned lower and to the right
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
                              // Fallback to mysterybag if bag.png fails
                              return Image.asset(
                                'assets/images/mysterybag.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.fastfood,
                                  size: 80,
                                  color: Colors.white.withOpacity(0.5),
                                ),
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
    return InkWell(
      onTap: () {
        _showLocationPicker();
      },
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
              _selectedLocation,
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
  }

  /// Prominent Search Bar
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
        decoration: InputDecoration(
          hintText: 'Search for surplus food...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingM,
          ),
        ),
        onTap: () {
          // TODO: Navigate to search screen
        },
      ),
    );
  }

  /// Categories: 2x3 Grid Layout with Premium Tiles
  Widget _buildCategoriesSection() {
    final categories = [
      {'label': 'Mystery Bag', 'asset': 'assets/icons/mystery_bag.png', 'fallback': Icons.card_giftcard},
      {'label': 'Meals', 'asset': 'assets/icons/meals.png', 'fallback': Icons.lunch_dining},
      {'label': 'Desserts', 'asset': 'assets/icons/desserts.png', 'fallback': Icons.cake},
      {'label': 'Bread', 'asset': 'assets/icons/bread.png', 'fallback': Icons.bakery_dining},
      {'label': 'Beverages', 'asset': 'assets/icons/beverages.png', 'fallback': Icons.local_drink_outlined},
      {'label': 'Snacks', 'asset': 'assets/icons/snacks.png', 'fallback': Icons.fastfood},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
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
        // Grid
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
              final bool isSelected = _selectedCategory == label;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = label;
                    _nearMeOnly = false;
                  });
                  final filtered = _filterByCategory(label);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryListingScreen(
                        category: label,
                        items: filtered,
                      ),
                    ),
                  );
                },
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
                      // Frosted circle hosting the colorful asset icon
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
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            c['asset'] as String,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              c['fallback'] as IconData,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
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
  }

  /// Main Feed: Surplus Near You
  Widget _buildSurplusFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Text(
            'Surplus Near You',
            style: AppTypography.h4,
          ),
        ),

        // Food Cards List (shrink-wrapped inside SingleChildScrollView)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
          itemCount: _surplusItems.length,
          itemBuilder: (context, index) {
            final item = _surplusItems[index];
            return _buildSurplusCard(item);
          },
        ),
      ],
    );
  }

  List<Map<String, dynamic>> get _filteredItems => _filterByCategory(_selectedCategory);

  List<Map<String, dynamic>> _filterByCategory(String category) {
    Iterable<Map<String, dynamic>> items = _surplusItems;
    switch (category) {
      case 'Mystery Bag':
        items = items.where((e) => (e['category'] as String) == 'Mystery Bag');
        break;
      case 'Meals':
        items = items.where((e) => (e['category'] as String) == 'Halal' || (e['category'] as String) == 'Fast Food');
        break;
      case 'Desserts':
        items = items.where((e) => (e['category'] as String) == 'Bakery');
        break;
      case 'Bread':
        items = items.where((e) => (e['category'] as String) == 'Bakery');
        break;
      case 'Beverages':
        items = items.where((e) => (e['category'] as String) == 'Beverages');
        break;
      case 'Snacks':
        items = items.where((e) => (e['category'] as String) == 'Fast Food');
        break;
      default:
        // show all
        break;
    }
    if (_nearMeOnly) {
      items = items.where((e) => (e['distance'] as double) <= 3.0);
    }
    return items.toList();
  }

  /// Surplus Food Card
  Widget _buildSurplusCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to merchant details screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MerchantDetailsScreen(
                merchantName: item['restaurantName'] as String,
                imageUrl: item['imageUrl'] as String,
                rating: item['rating'] as double,
                pickupHoursRemaining: 2,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Image
            _buildCardImage(item['imageUrl'] as String),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Name
                  Text(
                    item['restaurantName'] as String,
                    style: AppTypography.h5,
                  ),

                  const SizedBox(height: AppConstants.paddingS),

                  // Distance & Rating Row
                  Row(
                    children: [
                      // Distance
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppConstants.paddingXS),
                      Text(
                        '${item['distance']} km',
                        style: AppTypography.bodySmall,
                      ),

                      const SizedBox(width: AppConstants.paddingM),

                      // Rating
                      Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppConstants.paddingXS),
                      Text(
                        '${item['rating']}',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const Spacer(),

                      // Closing Soon Tag
                      if (item['closingSoon'] as bool)
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
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: AppColors.error,
                              ),
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

                  // Price Section
                  Row(
                    children: [
                      // Original Price (Strikethrough)
                      Text(
                        '${AppConstants.currencySymbol}${item['originalPrice'].toStringAsFixed(2)}',
                        style: AppTypography.bodyMedium.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(width: AppConstants.paddingS),

                      // Discounted Price (Orange, Bold)
                      Text(
                        '${AppConstants.currencySymbol}${item['discountedPrice'].toStringAsFixed(2)}',
                        style: AppTypography.h5.copyWith(
                          color: AppColors.accent, // Bright Orange
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Spacer(),

                      // Discount Percentage
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
                          '-${((1 - (item['discountedPrice'] as double) / (item['originalPrice'] as double)) * 100).toInt()}%',
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
    return Stack(
      children: [
        // Image
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
          ),
          child: Image.network(
            imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to colored placeholder
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
        ),
      ],
    );
  }

  /// Show Location Picker Dialog
  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusL)),
      ),
      builder: (context) {
        final locations = ['Penang', 'Kuala Lumpur', 'Johor Bahru', 'Ipoh', 'Melaka'];
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
                return ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: location == _selectedLocation
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  title: Text(
                    location,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: location == _selectedLocation
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: location == _selectedLocation
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: location == _selectedLocation
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _selectedLocation = location);
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
