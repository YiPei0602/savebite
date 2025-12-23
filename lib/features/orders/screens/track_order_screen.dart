import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'Track your order',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: AppColors.textPrimary),
            onPressed: () {
              // Support/Help action
            },
          ),
        ],
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
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: AppConstants.paddingS),
      decoration: BoxDecoration(
        color: const Color(0xFFB3E5FC), // Light blue background
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: _buildIllustrationForStep(_currentStep),
    );
  }

  Widget _buildIllustrationForStep(int step) {
    if (step == 0) {
      // Order confirmed - Map with location pin
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        child: Stack(
          children: [
            // Map-like background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _MapPatternPainter(),
              ),
            ),
            // Location pin in center
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1976D2).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (step == 1) {
      // Preparing - Barista/coffee shop illustration
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        child: Stack(
          children: [
            // Coffee shop counter illustration
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Espresso machine
                  Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 30,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Barista figure
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.brown,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Plant
                  Container(
                    width: 40,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.local_florist,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Rider on the way - Scooter illustration
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        child: Stack(
          children: [
            // Cloud-like background
            Positioned.fill(
              child: CustomPaint(
                painter: _CloudPatternPainter(),
              ),
            ),
            // Scooter with rider
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Rider helmet
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1976D2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Scooter body
                      Container(
                        width: 80,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: const Color(0xFF1976D2), width: 2),
                        ),
                        child: const Icon(
                          Icons.two_wheeler,
                          color: Color(0xFF1976D2),
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delivery box
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.brown,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Progress Stepper
  Widget _buildProgressStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXL),
      child: Row(
        children: [
          _buildStepIndicator(0),
          _buildStepLine(0),
          _buildStepIndicator(1),
          _buildStepLine(1),
          _buildStepIndicator(2),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step) {
    final isActive = _currentStep >= step;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1976D2) : Colors.grey[300],
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? const Color(0xFF1976D2) : Colors.grey[400]!,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '${step + 1}',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isActive ? const Color(0xFF1976D2) : Colors.grey[300],
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
          'Queens Waterfront Q1, Bayan Lepas',
        ),
        _buildInfoRow(
          'Your order ID:',
          widget.orderId,
          isLink: true,
        ),
        _buildInfoRow(
          widget.isSelfPickup ? 'Pickup Location:' : 'Delivery address:',
          widget.isSelfPickup
              ? 'Queens Waterfront Q1, Bayan Lepas'
              : '1B-28-01, IDEAL RESIDENCY, Jalan Lembah, Taman Tun Sardon, 11700 Gelugor, Pulau Pinang',
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
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
      ),
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
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1976D2),
          ),
          child: const Text(
            'View more details',
            style: TextStyle(decoration: TextDecoration.underline),
          ),
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

/// Custom Painter for Map Pattern Background
class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    // Draw grid lines
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Painter for Cloud Pattern Background
class _CloudPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Draw cloud-like shapes
    final path = Path();
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.2, size.height * 0.3), radius: 30));
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.3, size.height * 0.3), radius: 25));
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.8, size.height * 0.7), radius: 35));
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.7, size.height * 0.7), radius: 28));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
