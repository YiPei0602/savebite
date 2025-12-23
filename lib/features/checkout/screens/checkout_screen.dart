import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../cart/providers/cart_provider.dart';

/// Checkout Screen
/// 
/// Final step before placing an order.
/// Includes fulfillment method, payment selection, and order summary.
class CheckoutScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>>? cartItems;
  final double? subtotal;
  final double? totalSavings;

  const CheckoutScreen({
    super.key,
    this.cartItems,
    this.subtotal,
    this.totalSavings,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Fulfillment method: true = Self-Pickup, false = Delivery
  bool _isSelfPickup = true;

  // Selected payment method
  String _selectedPaymentMethod = 'card';

  // Delivery fee (only if delivery is selected)
  final double _deliveryFee = 2.00;

  // Get cart data from provider or widget
  Map<String, Map<String, dynamic>> get _cartItems {
    if (widget.cartItems != null) {
      return widget.cartItems!;
    }
    // Read from CartProvider
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    // Convert CartItemModel list to Map format
    final Map<String, Map<String, dynamic>> items = {};
    for (var item in cartProvider.items) {
      items[item.id] = {
        'id': item.id,
        'name': item.foodItem.name,
        'merchantName': item.foodItem.merchantName,
        'imageUrl': item.foodItem.imageUrl,
        'price': item.foodItem.discountedPrice,
        'originalPrice': item.foodItem.originalPrice,
        'quantity': item.quantity,
        'maxQuantity': item.foodItem.stock,
      };
    }
    return items;
  }

  double get _subtotal {
    return widget.subtotal ?? Provider.of<CartProvider>(context, listen: false).subtotal;
  }

  double get _totalSavings {
    return widget.totalSavings ?? Provider.of<CartProvider>(context, listen: false).totalSavings;
  }

  double get _total {
    double total = _subtotal;
    if (!_isSelfPickup) {
      total += _deliveryFee;
    }
    return total;
  }

  void _placeOrder() {
    // Generate order ID
    final orderId = 'SB${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );

    // Simulate order processing
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loading dialog

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF212121),
                  size: 60,
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),
              Text(
                'Order Placed!',
                style: AppTypography.h3.copyWith(
                  color: const Color(0xFF212121),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.paddingS),
              Text(
                'Your order has been successfully placed.',
                style: AppTypography.bodyMedium.copyWith(
                  color: const Color(0xFF616161),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingXS),
              Text(
                'Order #$orderId',
                style: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFF9E9E9E),
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Close dialog
                    Navigator.pop(context);
                    
                    // Navigate to Track Order screen with all required data
                    context.push('/track-order', extra: {
                      'orderId': orderId,
                      'cartItems': _cartItems,
                      'subtotal': _subtotal,
                      'totalSavings': _totalSavings,
                      'isSelfPickup': _isSelfPickup,
                      'paymentMethod': _selectedPaymentMethod,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF212121),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingM,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                  child: Text(
                    'Track Order',
                    style: AppTypography.buttonMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            // Check if we can pop, otherwise go back to cart
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/cart');
            }
          },
        ),
        title: Text(
          'Checkout',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Fulfillment Method (Delivery Options)
                  _buildFulfillmentSection(),

                  const SizedBox(height: AppConstants.paddingL),

                  // Section 2: Order Summary
                  _buildOrderSummary(),

                  const SizedBox(height: AppConstants.paddingL),

                  // Section 3: Payment Method
                  _buildPaymentSection(),

                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),

          // Bottom: Place Order Button
          _buildPlaceOrderButton(),
        ],
      ),
    );
  }

  /// Section 1: Fulfillment Method (Self-Pickup vs Delivery)
  Widget _buildFulfillmentSection() {
    return Container(
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
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Text(
              'Fulfillment Method',
              style: AppTypography.h4,
            ),

            const SizedBox(height: AppConstants.paddingM),

            // Toggle Switch: Self-Pickup vs Delivery
            Row(
              children: [
                  // Self-Pickup Option
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isSelfPickup = true),
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingM,
                        ),
                        decoration: BoxDecoration(
                          color: _isSelfPickup
                              ? const Color(0xFF00695C)
                              : const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.store,
                              color: _isSelfPickup
                                  ? Colors.white
                                  : const Color(0xFF00695C),
                              size: 28,
                            ),
                            const SizedBox(height: AppConstants.paddingXS),
                            Text(
                              'Self-Pickup',
                              style: AppTypography.bodyMedium.copyWith(
                                color: _isSelfPickup
                                    ? Colors.white
                                    : const Color(0xFF00695C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingXS),
                            Text(
                              'Free',
                              style: AppTypography.bodySmall.copyWith(
                                color: _isSelfPickup
                                    ? Colors.white
                                    : const Color(0xFF00695C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppConstants.paddingS),

                  // Delivery Option
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isSelfPickup = false),
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingM,
                        ),
                        decoration: BoxDecoration(
                          color: !_isSelfPickup
                              ? const Color(0xFF00695C)
                              : const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.delivery_dining,
                              color: !_isSelfPickup
                                  ? Colors.white
                                  : const Color(0xFF00695C),
                              size: 28,
                            ),
                            const SizedBox(height: AppConstants.paddingXS),
                            Text(
                              'Delivery',
                              style: AppTypography.bodyMedium.copyWith(
                                color: !_isSelfPickup
                                    ? Colors.white
                                    : const Color(0xFF00695C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingXS),
                            Text(
                              '${AppConstants.currencySymbol}${_deliveryFee.toStringAsFixed(2)}',
                              style: AppTypography.bodySmall.copyWith(
                                color: !_isSelfPickup
                                    ? Colors.white
                                    : const Color(0xFF00695C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: AppConstants.paddingL),

            // Pickup Point Information (if Self-Pickup)
            if (_isSelfPickup) _buildPickupPointInfo(),

            // Delivery Address (if Delivery)
            if (!_isSelfPickup) _buildDeliveryAddressInfo(),
          ],
        ),
      ),
    );
  }

  /// Pickup Point Information with Static Map Placeholder
  Widget _buildPickupPointInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pickup Location',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: AppConstants.paddingS),

        // Static Map Placeholder with realistic design
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            child: Stack(
              children: [
                // Map background with streets pattern
                CustomPaint(
                  size: Size.infinite,
                  painter: _MapPainter(),
                ),

                // Blue dot (current location)
                Positioned(
                  left: 60,
                  top: 60,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),

                // Red location pin (destination)
                Positioned(
                  right: 50,
                  top: 40,
                  child: Icon(
                    Icons.location_on,
                    size: 36,
                    color: const Color(0xFFE53935),
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),

                // Location recenter button (bottom right)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location,
                      size: 20,
                      color: Color(0xFF757575),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppConstants.paddingM),

        // Merchant Address
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
          child: Row(
            children: [
              Icon(
                Icons.store,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppConstants.paddingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Baker\'s Cottage',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingXS),
                    Text(
                      '123 Gurney Drive, Penang, 10250',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppConstants.paddingS),

        // Pickup Time
        Row(
          children: [
            Icon(
              Icons.access_time,
              color: AppColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: AppConstants.paddingXS),
            Text(
              'Pickup: Today, 6:00 PM - 8:00 PM',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Delivery Address Information
  Widget _buildDeliveryAddressInfo() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Row(
        children: [
          Icon(
            Icons.home,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: AppConstants.paddingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Address',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Text(
                  'Tower 1B, Ideal Residency Jalan Lembah, Taman Tun Sardon, 11700 Gelugor, Penang',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: AppColors.primary,
            onPressed: () {
              // TODO: Edit address
            },
          ),
        ],
      ),
    );
  }

  /// Section 2: Payment Method Selector
  Widget _buildPaymentSection() {
    return Container(
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
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Text(
              'Payment Method',
              style: AppTypography.h4,
            ),

            const SizedBox(height: AppConstants.paddingM),

            // Payment Options
            _buildPaymentOption(
              'card',
              'Credit/Debit Card',
              Icons.credit_card,
              'Visa, Mastercard, Amex',
              const Color(0xFF2196F3), // Blue
            ),

            const SizedBox(height: AppConstants.paddingS),

            _buildPaymentOption(
              'ewallet',
              'E-Wallet',
              Icons.account_balance_wallet,
              'Touch \'n Go, GrabPay, Boost',
              const Color(0xFFFF9800), // Orange
            ),

            const SizedBox(height: AppConstants.paddingS),

            _buildPaymentOption(
              'online_banking',
              'Online Banking',
              Icons.account_balance,
              'Maybank, CIMB, Public Bank',
              const Color(0xFF9C27B0), // Purple
            ),
          ],
        ),
      ),
    );
  }

  /// Payment Option Radio Button
  Widget _buildPaymentOption(
    String value,
    String title,
    IconData icon,
    String subtitle,
    Color accentColor,
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(AppConstants.radiusS),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingS),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withOpacity(0.2)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Icon(
                icon,
                color: isSelected ? accentColor : AppColors.textSecondary,
                size: 24,
              ),
            ),

            const SizedBox(width: AppConstants.paddingM),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? accentColor : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingXS),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Radio Button
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? accentColor : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// Section 3: Order Summary
  Widget _buildOrderSummary() {
    return Container(
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
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Text(
              'Order Summary',
              style: AppTypography.h4,
            ),

            const SizedBox(height: AppConstants.paddingM),

            // Subtotal
            _buildSummaryRow(
              'Subtotal',
              '${AppConstants.currencySymbol}${_subtotal.toStringAsFixed(2)}',
            ),

            // Delivery Fee (if applicable)
            if (!_isSelfPickup) ...[
              const SizedBox(height: AppConstants.paddingS),
              _buildSummaryRow(
                'Delivery Fee',
                '${AppConstants.currencySymbol}${_deliveryFee.toStringAsFixed(2)}',
              ),
            ],

            const SizedBox(height: AppConstants.paddingS),

            // Total Savings (Green)
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingS),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Savings',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '-${AppConstants.currencySymbol}${_totalSavings.toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingM),

            const Divider(),

            const SizedBox(height: AppConstants.paddingM),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTypography.h4,
                ),
                Text(
                  '${AppConstants.currencySymbol}${_total.toStringAsFixed(2)}',
                  style: AppTypography.h3.copyWith(
                    color: const Color(0xFFFF5722),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Summary Row Helper
  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Bottom: Place Order Button
  Widget _buildPlaceOrderButton() {
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
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.paddingL,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 24),
                  const SizedBox(width: AppConstants.paddingS),
                  Text(
                    'Place Order - ${AppConstants.currencySymbol}${_total.toStringAsFixed(2)}',
                    style: AppTypography.buttonLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Painter for Map Background
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Map background color (light gray)
    final bgPaint = Paint()..color = const Color(0xFFE8E8E8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Street colors
    final streetPaint = Paint()
      ..color = const Color(0xFFD0D0D0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final mainStreetPaint = Paint()
      ..color = const Color(0xFFC0C0C0)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    // Draw horizontal streets
    for (double y = 20; y < size.height; y += 30) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        y % 60 == 20 ? mainStreetPaint : streetPaint,
      );
    }

    // Draw vertical streets
    for (double x = 20; x < size.width; x += 30) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        x % 60 == 20 ? mainStreetPaint : streetPaint,
      );
    }

    // Draw some building blocks (light rectangles)
    final buildingPaint = Paint()..color = const Color(0xFFF5F5F5);
    
    // Building 1
    canvas.drawRect(
      Rect.fromLTWH(10, 10, 35, 25),
      buildingPaint,
    );
    
    // Building 2
    canvas.drawRect(
      Rect.fromLTWH(size.width - 60, 15, 40, 30),
      buildingPaint,
    );
    
    // Building 3
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - 20, size.height - 50, 40, 35),
      buildingPaint,
    );

    // Draw a curved road (blue line representing a river or main road)
    final roadPaint = Paint()
      ..color = const Color(0xFFBBDEFB)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.6,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.9,
      size.width,
      size.height * 0.8,
    );
    canvas.drawPath(path, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
