import 'package:flutter/material.dart';
import 'dart:async';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/constants/app_constants.dart';
import 'cart_screen.dart';

/// Merchant Details Screen
/// 
/// Displays detailed information about a merchant and their available surplus items.
/// Opens when user taps a card from the Home Screen.
class MerchantDetailsScreen extends StatefulWidget {
  final String merchantName;
  final String imageUrl;
  final double rating;
  final int pickupHoursRemaining;

  const MerchantDetailsScreen({
    super.key,
    required this.merchantName,
    required this.imageUrl,
    required this.rating,
    this.pickupHoursRemaining = 2,
  });

  @override
  State<MerchantDetailsScreen> createState() => _MerchantDetailsScreenState();
}

class _MerchantDetailsScreenState extends State<MerchantDetailsScreen> {
  // Cart state
  final Map<String, int> _cart = {};
  int _totalItems = 0;
  double _totalPrice = 0.0;

  // Countdown timer
  late Timer _timer;
  late Duration _remainingTime;

  // Dummy surplus menu items
  final List<Map<String, dynamic>> _surplusItems = [
    {
      'id': '1',
      'name': 'Surplus Pastry Box',
      'description': 'Assorted fresh pastries',
      'imageUrl': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400',
      'price': 8.00,
      'originalPrice': 16.00,
      'quantityLeft': 3,
    },
    {
      'id': '2',
      'name': 'Mixed Bread Bundle',
      'description': 'Various bread types',
      'imageUrl': 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=400',
      'price': 5.00,
      'originalPrice': 12.00,
      'quantityLeft': 5,
    },
    {
      'id': '3',
      'name': 'Cake Slice Combo',
      'description': 'Delicious cake slices',
      'imageUrl': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400',
      'price': 10.00,
      'originalPrice': 20.00,
      'quantityLeft': 2,
    },
    {
      'id': '4',
      'name': 'Cookie Assortment',
      'description': 'Freshly baked cookies',
      'imageUrl': 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=400',
      'price': 6.00,
      'originalPrice': 14.00,
      'quantityLeft': 8,
    },
    {
      'id': '5',
      'name': 'Sandwich Pack',
      'description': 'Ready-to-eat sandwiches',
      'imageUrl': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400',
      'price': 12.00,
      'originalPrice': 24.00,
      'quantityLeft': 4,
    },
  ];

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

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      final itemId = item['id'] as String;
      final quantityLeft = item['quantityLeft'] as int;
      final currentQuantity = _cart[itemId] ?? 0;

      if (currentQuantity < quantityLeft) {
        _cart[itemId] = currentQuantity + 1;
        _totalItems++;
        _totalPrice += item['price'] as double;
      } else {
        // Show snackbar if max quantity reached
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum quantity reached for ${item['name']}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _removeFromCart(Map<String, dynamic> item) {
    setState(() {
      final itemId = item['id'] as String;
      final currentQuantity = _cart[itemId] ?? 0;

      if (currentQuantity > 0) {
        _cart[itemId] = currentQuantity - 1;
        _totalItems--;
        _totalPrice -= item['price'] as double;

        if (_cart[itemId] == 0) {
          _cart.remove(itemId);
        }
      }
    });
  }

  int _getItemQuantityInCart(String itemId) {
    return _cart[itemId] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
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
              _buildMerchantInfo(),

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
              _buildSurplusItemsList(),

              // Bottom padding for floating cart banner
              SliverToBoxAdapter(
                child: SizedBox(height: _totalItems > 0 ? 100 : 20),
              ),
            ],
          ),

          // Floating Cart Banner
          if (_totalItems > 0) _buildFloatingCartBanner(),
        ],
      ),
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
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Image
            Image.network(
              widget.imageUrl,
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
  Widget _buildMerchantInfo() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Name
            Text(
              widget.merchantName,
              style: AppTypography.h2,
            ),

            const SizedBox(height: AppConstants.paddingS),

            // Rating
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < widget.rating.floor()
                        ? Icons.star
                        : (index < widget.rating ? Icons.star_half : Icons.star_border),
                    color: AppColors.warning,
                    size: 20,
                  );
                }),
                const SizedBox(width: AppConstants.paddingS),
                Text(
                  '${widget.rating}',
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
  Widget _buildSurplusItemsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = _surplusItems[index];
          return _buildSurplusItemCard(item);
        },
        childCount: _surplusItems.length,
      ),
    );
  }

  /// Surplus Item Card (Horizontal Layout)
  Widget _buildSurplusItemCard(Map<String, dynamic> item) {
    final itemId = item['id'] as String;
    final quantityInCart = _getItemQuantityInCart(itemId);
    final quantityLeft = item['quantityLeft'] as int;

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
      child: Row(
        children: [
          // Left: Thumbnail Image
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppConstants.radiusM),
              bottomLeft: Radius.circular(AppConstants.radiusM),
            ),
            child: Image.network(
              item['imageUrl'] as String,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
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

          // Middle: Item Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name
                  Text(
                    item['name'] as String,
                    style: AppTypography.h5,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppConstants.paddingXS),

                  // Description
                  Text(
                    item['description'] as String,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppConstants.paddingS),

                  // Quantity Left (Green Text)
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: quantityLeft <= 3 ? AppColors.warning : AppColors.success,
                      ),
                      const SizedBox(width: AppConstants.paddingXS),
                      Text(
                        '$quantityLeft left',
                        style: AppTypography.bodySmall.copyWith(
                          color: quantityLeft <= 3 ? AppColors.warning : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppConstants.paddingS),

                  // Price
                  Row(
                    children: [
                      Text(
                        '${AppConstants.currencySymbol}${item['originalPrice'].toStringAsFixed(2)}',
                        style: AppTypography.bodySmall.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      Text(
                        '${AppConstants.currencySymbol}${item['price'].toStringAsFixed(2)}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Right: Add Button or Quantity Controls
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: quantityInCart == 0
                ? _buildAddButton(item)
                : _buildQuantityControls(item),
          ),
        ],
      ),
    );
  }

  /// Add Button (Primary Green)
  Widget _buildAddButton(Map<String, dynamic> item) {
    return ElevatedButton(
      onPressed: () => _addToCart(item),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, // Primary Green #00A86B
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
  Widget _buildQuantityControls(Map<String, dynamic> item) {
    final itemId = item['id'] as String;
    final quantity = _getItemQuantityInCart(itemId);

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
          // Minus Button
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            color: AppColors.primary,
            onPressed: () => _removeFromCart(item),
            padding: const EdgeInsets.all(AppConstants.paddingS),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),

          // Quantity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingS),
            child: Text(
              '$quantity',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),

          // Plus Button
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            color: AppColors.primary,
            onPressed: () => _addToCart(item),
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
  Widget _buildFloatingCartBanner() {
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
                      '$_totalItems',
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
                    '$_totalItems ${_totalItems == 1 ? 'item' : 'items'}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${AppConstants.currencySymbol}${_totalPrice.toStringAsFixed(2)}',
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
              onPressed: () {
                // Navigate to cart screen with current cart items
                final cartItems = <String, Map<String, dynamic>>{};
                
                // Convert current cart to proper format
                _cart.forEach((itemId, quantity) {
                  final item = _surplusItems.firstWhere(
                    (item) => item['id'] == itemId,
                  );
                  cartItems[itemId] = {
                    ...item,
                    'quantity': quantity,
                    'merchantName': widget.merchantName,
                    'maxQuantity': item['quantityLeft'],
                  };
                });

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartScreen(
                      initialCartItems: cartItems,
                    ),
                  ),
                );
              },
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
