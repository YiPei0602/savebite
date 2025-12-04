import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/constants/app_constants.dart';

/// Checkout Screen
/// 
/// Final step before placing an order.
/// Includes fulfillment method, payment selection, and order summary.
class CheckoutScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> cartItems;
  final double subtotal;
  final double totalSavings;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.totalSavings,
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
  final double _deliveryFee = 5.00;

  // Service fee
  final double _serviceFee = 2.00;

  double get _total {
    double total = widget.subtotal + _serviceFee;
    if (!_isSelfPickup) {
      total += _deliveryFee;
    }
    return total;
  }

  void _placeOrder() {
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
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 60,
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),
              Text(
                'Order Placed!',
                style: AppTypography.h3.copyWith(
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppConstants.paddingS),
              Text(
                'Your order has been successfully placed.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingXS),
              Text(
                'Order #SB${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Go back to home (pop all screens)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(
                    'Back to Home',
                    style: AppTypography.buttonMedium,
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
        title: Text('Checkout', style: AppTypography.h3),
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
                  // Section 1: Fulfillment Method
                  _buildFulfillmentSection(),

                  const SizedBox(height: AppConstants.paddingL),

                  // Section 2: Payment Method
                  _buildPaymentSection(),

                  const SizedBox(height: AppConstants.paddingL),

                  // Section 3: Order Summary
                  _buildOrderSummary(),

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
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Row(
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
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.store,
                              color: _isSelfPickup
                                  ? AppColors.textOnPrimary
                                  : AppColors.textSecondary,
                              size: 28,
                            ),
                            const SizedBox(height: AppConstants.paddingXS),
                            Text(
                              'Self-Pickup',
                              style: AppTypography.bodyMedium.copyWith(
                                color: _isSelfPickup
                                    ? AppColors.textOnPrimary
                                    : AppColors.textPrimary,
                                fontWeight: _isSelfPickup
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingXS),
                            Text(
                              'Free',
                              style: AppTypography.bodySmall.copyWith(
                                color: _isSelfPickup
                                    ? AppColors.textOnPrimary
                                    : AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

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
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.delivery_dining,
                              color: !_isSelfPickup
                                  ? AppColors.textOnPrimary
                                  : AppColors.textSecondary,
                              size: 28,
                            ),
                            const SizedBox(height: AppConstants.paddingXS),
                            Text(
                              'Delivery',
                              style: AppTypography.bodyMedium.copyWith(
                                color: !_isSelfPickup
                                    ? AppColors.textOnPrimary
                                    : AppColors.textPrimary,
                                fontWeight: !_isSelfPickup
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingXS),
                            Text(
                              '${AppConstants.currencySymbol}${_deliveryFee.toStringAsFixed(2)}',
                              style: AppTypography.bodySmall.copyWith(
                                color: !_isSelfPickup
                                    ? AppColors.textOnPrimary
                                    : AppColors.textSecondary,
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

        // Static Map Placeholder
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Stack(
            children: [
              // Map placeholder with grid pattern
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryLight.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.map,
                      size: 60,
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),

              // Location Pin
              Center(
                child: Icon(
                  Icons.location_on,
                  size: 40,
                  color: AppColors.error,
                ),
              ),
            ],
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
                  '456 Jalan Sultan Ahmad Shah, Penang, 10050',
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
            ),

            const SizedBox(height: AppConstants.paddingS),

            _buildPaymentOption(
              'stripe',
              'Stripe',
              Icons.payment,
              'Secure payment via Stripe',
            ),

            const SizedBox(height: AppConstants.paddingS),

            _buildPaymentOption(
              'ewallet',
              'E-Wallet',
              Icons.account_balance_wallet,
              'Touch \'n Go, GrabPay, Boost',
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
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(AppConstants.radiusS),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
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
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
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
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
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
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
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
              '${AppConstants.currencySymbol}${widget.subtotal.toStringAsFixed(2)}',
            ),

            const SizedBox(height: AppConstants.paddingS),

            // Service Fee
            _buildSummaryRow(
              'Service Fee',
              '${AppConstants.currencySymbol}${_serviceFee.toStringAsFixed(2)}',
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
                    '-${AppConstants.currencySymbol}${widget.totalSavings.toStringAsFixed(2)}',
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
                    color: AppColors.primary,
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
                backgroundColor: AppColors.primary, // #00A86B
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
