import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/constants/app_constants.dart';
import 'cart_screen.dart';

class CategoryListingScreen extends StatefulWidget {
  const CategoryListingScreen({super.key, required this.category, required this.items});

  final String category;
  final List<Map<String, dynamic>> items;

  @override
  State<CategoryListingScreen> createState() => _CategoryListingScreenState();
}

class _CategoryListingScreenState extends State<CategoryListingScreen> {
  // Cart items: itemId -> {item data, quantity}
  final Map<String, Map<String, dynamic>> _cartItems = {};

  int get _cartItemCount {
    return _cartItems.values.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  void _addToCart(Map<String, dynamic> item) {
    final itemId = item['restaurantName'] as String;
    
    setState(() {
      if (_cartItems.containsKey(itemId)) {
        // Increment quantity
        _cartItems[itemId]!['quantity'] = (_cartItems[itemId]!['quantity'] as int) + 1;
      } else {
        // Add new item
        _cartItems[itemId] = {
          'id': itemId,
          'name': 'Surplus Bag',
          'merchantName': item['restaurantName'],
          'imageUrl': item['imageUrl'],
          'price': item['discountedPrice'],
          'originalPrice': item['originalPrice'],
          'quantity': 1,
          'maxQuantity': 5,
        };
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to cart'),
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: _navigateToCart,
        ),
      ),
    );
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(initialCartItems: _cartItems),
      ),
    );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.category, style: AppTypography.h4),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
                onPressed: _navigateToCart,
              ),
              if (_cartItemCount > 0)
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
                      '$_cartItemCount',
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
          ),
        ],
      ),
      body: widget.items.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              itemCount: widget.items.length,
              itemBuilder: (context, index) => _buildItemCard(context, widget.items[index]),
            ),
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
            'Please check back later for fresh surplus items.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: InkWell(
        onTap: () => _addToCart(item),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardImage(item['imageUrl'] as String),
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['restaurantName'] as String,
                  style: AppTypography.h5,
                ),
                const SizedBox(height: AppConstants.paddingS),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: AppConstants.paddingXS),
                    Text('${item['distance']} km', style: AppTypography.bodySmall),
                    const SizedBox(width: AppConstants.paddingM),
                    const Icon(Icons.star, size: 16, color: AppColors.warning),
                    const SizedBox(width: AppConstants.paddingXS),
                    Text('${item['rating']}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
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
                      '${AppConstants.currencySymbol}${(item['originalPrice'] as double).toStringAsFixed(2)}',
                      style: AppTypography.bodyMedium.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Text(
                      '${AppConstants.currencySymbol}${(item['discountedPrice'] as double).toStringAsFixed(2)}',
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
                        '-${((1 - (item['discountedPrice'] as double) / (item['originalPrice'] as double)) * 100).toInt()}%',
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
                    icon: const Icon(Icons.add_shopping_cart, size: 20),
                    label: Text('Add to Cart', style: AppTypography.buttonMedium),
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
