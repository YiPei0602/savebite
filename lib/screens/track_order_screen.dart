import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/constants/app_constants.dart';

/// Track Order Screen
/// 
/// Displays real-time order tracking with status updates,
/// order details, and delivery information.
class TrackOrderScreen extends StatefulWidget {
  final String orderId;
  final Map<String, Map<String, dynamic>> cartItems;
  final double subtotal;
  final double totalSavings;
  final bool isSelfPickup;
  final String paymentMethod;

  const TrackOrderScreen({
    super.key,
    required this.orderId,
    required this.cartItems,
    required this.subtotal,
    required this.totalSavings,
    required this.isSelfPickup,
    required this.paymentMethod,
  });

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  int _currentStep = 0;
  String _statusMessage = 'Order Confirmed.';
  String _statusDetail = 'We\'re preparing your order...';

  @override
  void initState() {
    super.initState();
    _simulateOrderProgress();
  }

  void _simulateOrderProgress() {
    // Simulate order status updates
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentStep = 1;
          _statusMessage = 'Preparing.';
          _statusDetail = widget.isSelfPickup
              ? 'Your order is being prepared.'
              : 'Rider is on the way to pick up your order.';
        });
      }
    });

    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _currentStep = 2;
          _statusMessage = widget.isSelfPickup
              ? 'Ready for Pickup!'
              : 'Your rider is on the way to you.';
          _statusDetail = widget.isSelfPickup
              ? 'Your order is ready. Please collect at the pickup location.'
              : 'Contact rider if necessary.';
        });
      }
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
        title: Text(
          'Track Your Order',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map/Illustration Section
            _buildHeaderIllustration(),

            // Progress Stepper
            _buildProgressStepper(),

            const SizedBox(height: AppConstants.paddingL),

            // Status Card
            _buildStatusCard(),

            const SizedBox(height: AppConstants.paddingL),

            // Order Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderInfo(),
                  const SizedBox(height: AppConstants.paddingL),
                  _buildItemsList(),
                  const SizedBox(height: AppConstants.paddingL),
                  _buildPaymentInfo(),
                  const SizedBox(height: AppConstants.paddingXL),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header Illustration (Map or Delivery Animation)
  Widget _buildHeaderIllustration() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: const Color(0xFFB3E5FC),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Stack(
        children: [
          // Background illustration
          Center(
            child: _buildIllustrationForStep(_currentStep),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustrationForStep(int step) {
    if (step == 0) {
      // Order confirmed - Map with location pin
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              size: 60,
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Order Confirmed',
            style: AppTypography.h5.copyWith(
              color: const Color(0xFF1976D2),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else if (step == 1) {
      // Preparing - Store/Kitchen icon
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant,
              size: 60,
              color: Color(0xFFFF9800),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Preparing Your Order',
            style: AppTypography.h5.copyWith(
              color: const Color(0xFFFF9800),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else {
      // On the way / Ready
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isSelfPickup ? Icons.store : Icons.delivery_dining,
              size: 60,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isSelfPickup ? 'Ready for Pickup!' : 'On the Way!',
            style: AppTypography.h5.copyWith(
              color: const Color(0xFF4CAF50),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
  }

  /// Progress Stepper
  Widget _buildProgressStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXL),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Confirmed'),
          _buildStepLine(0),
          _buildStepIndicator(1, 'Preparing'),
          _buildStepLine(1),
          _buildStepIndicator(2, widget.isSelfPickup ? 'Ready' : 'On Way'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1976D2) : const Color(0xFFE0E0E0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isActive ? const Color(0xFF1976D2) : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: isActive ? const Color(0xFF1976D2) : const Color(0xFFE0E0E0),
      ),
    );
  }

  /// Status Card
  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
      padding: const EdgeInsets.all(AppConstants.paddingL),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _statusMessage,
                style: AppTypography.h4.copyWith(
                  color: const Color(0xFF1976D2),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                TimeOfDay.now().format(context),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            _statusDetail,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          // Show rider info if delivery and step 2
          if (!widget.isSelfPickup && _currentStep == 2) ...[
            const SizedBox(height: AppConstants.paddingM),
            const Divider(),
            const SizedBox(height: AppConstants.paddingM),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    color: Color(0xFF1976D2),
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ahmad Bin Ali',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '+60124917897',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Call rider
                  },
                  icon: const Icon(Icons.phone, color: Color(0xFF4CAF50)),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingS),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Track rider location
                },
                icon: const Icon(Icons.location_on, size: 18),
                label: const Text('Track Rider\'s Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1976D2),
                  side: const BorderSide(color: Color(0xFF1976D2)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Order Info
  Widget _buildOrderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          'Your order from:',
          'The Baker\'s Cottage',
        ),
        const SizedBox(height: AppConstants.paddingS),
        _buildInfoRow(
          'Your order ID:',
          widget.orderId,
          isLink: true,
        ),
        const SizedBox(height: AppConstants.paddingS),
        _buildInfoRow(
          widget.isSelfPickup ? 'Pickup Location:' : 'Delivery address:',
          widget.isSelfPickup
              ? '123 Gurney Drive, Penang, 10250'
              : 'Tower 1B, Ideal Residency Jalan Lembah, Taman Tun Sardon, 11700 Gelugor, Penang',
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: isLink ? const Color(0xFF1976D2) : AppColors.textSecondary,
              decoration: isLink ? TextDecoration.underline : null,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// Items List
  Widget _buildItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items:',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.paddingM),
        ...widget.cartItems.values.map((item) => _buildItemRow(item)),
        const SizedBox(height: AppConstants.paddingS),
        TextButton(
          onPressed: () {
            // Show more details
          },
          child: const Text('View more details'),
        ),
      ],
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
            child: Image.network(
              item['imageUrl'] as String,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 50,
                  height: 50,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.fastfood, size: 24),
                );
              },
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item['merchantName'] as String,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'x${item['quantity']}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${AppConstants.currencySymbol}${((item['price'] as double) * (item['quantity'] as int)).toStringAsFixed(2)}',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }

  /// Payment Info
  Widget _buildPaymentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paid with',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.paddingS),
        Text(
          _getPaymentMethodName(widget.paymentMethod),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'card':
        return 'Credit/Debit Card';
      case 'ewallet':
        return 'E-Wallet';
      case 'online_banking':
        return 'Online Banking';
      case 'cash':
        return 'Cash';
      default:
        return 'Unknown';
    }
  }
}
