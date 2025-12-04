import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/constants/app_constants.dart';
import 'checkout_screen.dart';

/// Cart Screen
/// 
/// Displays items added to cart with quantity controls and total savings.
/// Allows users to proceed to checkout.
class CartScreen extends StatefulWidget {
  // Accept cart items from previous screen (in real app, use state management)
  final Map<String, Map<String, dynamic>>? initialCartItems;

  const CartScreen({
    super.key,
    this.initialCartItems,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Cart items: itemId -> {item data, quantity}
  late Map<String, Map<String, dynamic>> _cartItems;

  // Dummy cart items for demonstration
  final Map<String, Map<String, dynamic>> _dummyCartItems = {
    '1': {
      'id': '1',
      'name': 'Surplus Pastry Box',
      'merchantName': 'The Baker\'s Cottage',
      'imageUrl': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400',
      'price': 8.00,
      'originalPrice': 16.00,
      'quantity': 2,
      'maxQuantity': 3,
    },
    '2': {
      'id': '2',
      'name': 'Mixed Bread Bundle',
      'merchantName': 'The Baker\'s Cottage',
      'imageUrl': 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=400',
      'price': 5.00,
      'originalPrice': 12.00,
      'quantity': 1,
      'maxQuantity': 5,
    },
    '3': {
      'id': '3',
      'name': 'Cake Slice Combo',
      'merchantName': 'The Baker\'s Cottage',
      'imageUrl': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400',
      'price': 10.00,
      'originalPrice': 20.00,
      'quantity': 1,
      'maxQuantity': 2,
    },
  };

  @override
  void initState() {
    super.initState();
    _cartItems = widget.initialCartItems ?? _dummyCartItems;
  }

  // Calculate totals
  double get _subtotal {
    return _cartItems.values.fold(0.0, (sum, item) {
      return sum + (item['price'] as double) * (item['quantity'] as int);
    });
  }

  double get _originalTotal {
    return _cartItems.values.fold(0.0, (sum, item) {
      return sum + (item['originalPrice'] as double) * (item['quantity'] as int);
    });
  }

  double get _totalSavings {
    return _originalTotal - _subtotal;
  }

  int get _totalItems {
    return _cartItems.values.fold(0, (sum, item) {
      return sum + (item['quantity'] as int);
    });
  }

  void _incrementQuantity(String itemId) {
    setState(() {
      final item = _cartItems[itemId]!;
      final currentQuantity = item['quantity'] as int;
      final maxQuantity = item['maxQuantity'] as int;

      if (currentQuantity < maxQuantity) {
        item['quantity'] = currentQuantity + 1;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum quantity reached for ${item['name']}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _decrementQuantity(String itemId) {
    setState(() {
      final item = _cartItems[itemId]!;
      final currentQuantity = item['quantity'] as int;

      if (currentQuantity > 1) {
        item['quantity'] = currentQuantity - 1;
      } else {
        // Remove item if quantity becomes 0
        _showRemoveItemDialog(itemId);
      }
    });
  }

  void _removeItem(String itemId) {
    setState(() {
      _cartItems.remove(itemId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item removed from cart'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showRemoveItemDialog(String itemId) {
    final item = _cartItems[itemId]!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Item?', style: AppTypography.h4),
        content: Text(
          'Do you want to remove "${item['name']}" from your cart?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeItem(itemId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Remove', style: AppTypography.buttonMedium),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: _cartItems,
          subtotal: _subtotal,
          totalSavings: _totalSavings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Your Cart', style: AppTypography.h3),
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Clear Cart?', style: AppTypography.h4),
                    content: Text(
                      'Remove all items from your cart?',
                      style: AppTypography.bodyMedium,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: AppTypography.bodyMedium),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _cartItems.clear());
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: Text('Clear', style: AppTypography.buttonMedium),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _cartItems.isEmpty ? _buildEmptyCart() : _buildCartContent(),
    );
  }

  /// Empty Cart State
  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 100,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppConstants.paddingL),
            Text(
              'Your Cart is Empty',
              style: AppTypography.h3,
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              'Add items from the marketplace to get started',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingXL),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingXL,
                  vertical: AppConstants.paddingM,
                ),
              ),
              child: Text(
                'Browse Surplus Food',
                style: AppTypography.buttonMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cart Content with Items
  Widget _buildCartContent() {
    return Column(
      children: [
        // Cart Items List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            itemCount: _cartItems.length,
            itemBuilder: (context, index) {
              final itemId = _cartItems.keys.elementAt(index);
              final item = _cartItems[itemId]!;
              return _buildCartItem(itemId, item);
            },
          ),
        ),

        // Footer: Total Savings and Checkout Button
        _buildCartFooter(),
      ],
    );
  }

  /// Cart Item Row
  Widget _buildCartItem(String itemId, Map<String, dynamic> item) {
    final quantity = item['quantity'] as int;
    final price = item['price'] as double;
    final originalPrice = item['originalPrice'] as double;
    final itemTotal = price * quantity;
    final itemSavings = (originalPrice - price) * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
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
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
              child: Image.network(
                item['imageUrl'] as String,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: AppColors.surfaceVariant,
                    child: const Icon(
                      Icons.fastfood,
                      color: AppColors.textTertiary,
                      size: 32,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: AppConstants.paddingM),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name
                  Text(
                    item['name'] as String,
                    style: AppTypography.h5,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppConstants.paddingXS),

                  // Merchant Name
                  Text(
                    item['merchantName'] as String,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingS),

                  // Price
                  Row(
                    children: [
                      Text(
                        '${AppConstants.currencySymbol}${price.toStringAsFixed(2)}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      Text(
                        '${AppConstants.currencySymbol}${originalPrice.toStringAsFixed(2)}',
                        style: AppTypography.bodySmall.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppConstants.paddingS),

                  // Savings for this item
                  Text(
                    'Save ${AppConstants.currencySymbol}${itemSavings.toStringAsFixed(2)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppConstants.paddingS),

            // Quantity Stepper and Total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Item Total Price
                Text(
                  '${AppConstants.currencySymbol}${itemTotal.toStringAsFixed(2)}',
                  style: AppTypography.h5.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: AppConstants.paddingS),

                // Quantity Stepper (- 1 +)
                _buildQuantityStepper(itemId, quantity),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Quantity Stepper (- 1 +)
  Widget _buildQuantityStepper(String itemId, int quantity) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus Button
          InkWell(
            onTap: () => _decrementQuantity(itemId),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppConstants.radiusS),
              bottomLeft: Radius.circular(AppConstants.radiusS),
            ),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingS),
              child: const Icon(
                Icons.remove,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Quantity Display
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM,
              vertical: AppConstants.paddingS,
            ),
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Text(
              '$quantity',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Plus Button
          InkWell(
            onTap: () => _incrementQuantity(itemId),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(AppConstants.radiusS),
              bottomRight: Radius.circular(AppConstants.radiusS),
            ),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingS),
              child: const Icon(
                Icons.add,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cart Footer: Total Savings and Checkout Button
  Widget _buildCartFooter() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subtotal Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal ($_totalItems ${_totalItems == 1 ? 'item' : 'items'})',
                    style: AppTypography.bodyMedium,
                  ),
                  Text(
                    '${AppConstants.currencySymbol}${_subtotal.toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingS),

              // Total Savings Row (Highlighted in Green)
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: AppConstants.paddingS),
                        Text(
                          'Total Savings',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${AppConstants.currencySymbol}${_totalSavings.toStringAsFixed(2)}',
                      style: AppTypography.h5.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.paddingL),

              // Proceed to Checkout Button (Full Width)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingL,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Proceed to Checkout',
                        style: AppTypography.buttonLarge,
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
