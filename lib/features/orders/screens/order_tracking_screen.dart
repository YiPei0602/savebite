import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';

/// Order Tracking Screen
/// 
/// Live tracking for active orders with pickup/delivery status.
/// Shows map view with user and merchant locations.
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final String? merchantName;
  final String? merchantAddress;
  final bool? isPickup;
  final double? totalAmount;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.merchantName,
    this.merchantAddress,
    this.isPickup,
    this.totalAmount,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  // Order status
  String _currentStatus = 'preparing'; // preparing, ready, completed, cancelled
  
  // Timer for status updates (simulated)
  Timer? _statusTimer;
  int _preparationProgress = 0;

  // Estimated pickup time
  final String _estimatedTime = '6:30 PM';

  // Get order data from provider or widget
  String get _merchantName {
    if (widget.merchantName != null) {
      return widget.merchantName!;
    }
    // Try to get from OrderProvider
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final order = orderProvider.orders.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => orderProvider.activeOrders.firstWhere(
        (o) => o.id == widget.orderId,
        orElse: () => throw Exception('Order not found'),
      ),
    );
    return order.merchantName;
  }

  String get _merchantAddress {
    if (widget.merchantAddress != null) {
      return widget.merchantAddress!;
    }
    // Default address if not provided
    return '123 Merchant Street, Kuala Lumpur';
  }

  bool get _isPickup {
    if (widget.isPickup != null) {
      return widget.isPickup!;
    }
    // Try to get from OrderProvider
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final order = orderProvider.orders.firstWhere(
        (o) => o.id == widget.orderId,
        orElse: () => orderProvider.activeOrders.firstWhere(
          (o) => o.id == widget.orderId,
          orElse: () => throw Exception('Order not found'),
        ),
      );
      return order.fulfillmentType == FulfillmentType.pickup;
    } catch (e) {
      return true; // Default to pickup
    }
  }

  double get _totalAmount {
    if (widget.totalAmount != null) {
      return widget.totalAmount!;
    }
    // Try to get from OrderProvider
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final order = orderProvider.orders.firstWhere(
        (o) => o.id == widget.orderId,
        orElse: () => orderProvider.activeOrders.firstWhere(
          (o) => o.id == widget.orderId,
          orElse: () => throw Exception('Order not found'),
        ),
      );
      return order.totalPrice;
    } catch (e) {
      return 0.0; // Default amount
    }
  }

  @override
  void initState() {
    super.initState();
    _startStatusSimulation();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startStatusSimulation() {
    // Simulate order preparation progress
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_preparationProgress < 100) {
        setState(() {
          _preparationProgress += 20;
          if (_preparationProgress >= 100) {
            _currentStatus = 'ready';
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _contactMerchant() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Merchant', style: AppTypography.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _merchantName,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            _buildContactOption(Icons.phone, 'Call', '+60 12-345 6789'),
            const SizedBox(height: AppConstants.paddingS),
            _buildContactOption(Icons.message, 'Message', 'Send a message'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: AppTypography.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(IconData icon, String label, String value) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label: $value')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.bodyMedium),
                  Text(
                    value,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _cancelOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order?', style: AppTypography.h4),
        content: Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Order', style: AppTypography.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _currentStatus = 'cancelled');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order cancelled'),
                  backgroundColor: AppColors.error,
                ),
              );
              // Navigate back after a delay
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) Navigator.pop(context);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Cancel Order', style: AppTypography.buttonMedium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order Tracking', style: AppTypography.h3),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/order-history');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.textPrimary),
            onPressed: () {
              _showOrderDetails();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Half: Map View
          Expanded(
            flex: 3,
            child: _buildMapView(),
          ),

          // Bottom Sheet: Status and Actions
          _buildBottomSheet(),
        ],
      ),
    );
  }

  /// Top Half: Map View with User and Merchant Pins
  Widget _buildMapView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.1),
            AppColors.primary.withOpacity(0.15),
            AppColors.accent.withOpacity(0.1),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Map placeholder with grid pattern
          Center(
            child: Icon(
              Icons.map,
              size: 120,
              color: AppColors.primary.withOpacity(0.2),
            ),
          ),

          // Merchant Pin
          Positioned(
            top: 100,
            right: 80,
            child: _buildLocationPin(
              icon: Icons.store,
              label: _merchantName,
              color: AppColors.primary,
              isUser: false,
            ),
          ),

          // User Pin
          Positioned(
            bottom: 120,
            left: 60,
            child: _buildLocationPin(
              icon: Icons.person_pin_circle,
              label: 'You',
              color: AppColors.accent,
              isUser: true,
            ),
          ),

          // Distance indicator
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: AppConstants.paddingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_walk,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  Text(
                    '2.3 km away',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Order ID badge
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: AppConstants.paddingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Order #${widget.orderId}',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Location Pin Widget
  Widget _buildLocationPin({
    required IconData icon,
    required String label,
    required Color color,
    required bool isUser,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pin icon
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),

        // Pin stem
        Container(
          width: 3,
          height: 20,
          color: color,
        ),

        // Label
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingS,
            vertical: AppConstants.paddingXS,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Bottom Sheet: Status Indicator and Actions
  Widget _buildBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: AppConstants.paddingL),

              // Status Indicator
              _buildStatusIndicator(),

              const SizedBox(height: AppConstants.paddingL),

              // Merchant Info
              _buildMerchantInfo(),

              const SizedBox(height: AppConstants.paddingL),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// Status Indicator
  Widget _buildStatusIndicator() {
    String statusText;
    String statusDescription;
    Color statusColor;
    IconData statusIcon;

    switch (_currentStatus) {
      case 'preparing':
        statusText = 'Preparing Your Order';
        statusDescription = 'Estimated ready time: $_estimatedTime';
        statusColor = AppColors.warning;
        statusIcon = Icons.restaurant;
        break;
      case 'ready':
        statusText = 'Ready for Pickup';
        statusDescription = 'Your order is ready! Please collect by $_estimatedTime';
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'completed':
        statusText = 'Order Completed';
        statusDescription = 'Thank you for saving food!';
        statusColor = AppColors.success;
        statusIcon = Icons.done_all;
        break;
      case 'cancelled':
        statusText = 'Order Cancelled';
        statusDescription = 'This order has been cancelled';
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      default:
        statusText = 'Processing';
        statusDescription = '';
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Status icon and text
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: AppTypography.h5.copyWith(
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingXS),
                    Text(
                      statusDescription,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Progress bar (only for preparing status)
          if (_currentStatus == 'preparing') ...[
            const SizedBox(height: AppConstants.paddingM),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
              child: LinearProgressIndicator(
                value: _preparationProgress / 100,
                minHeight: 8,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: AppConstants.paddingXS),
            Text(
              '$_preparationProgress% complete',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Merchant Information
  Widget _buildMerchantInfo() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Row(
        children: [
          Icon(
            Icons.store,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _merchantName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Text(
                  _merchantAddress,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.directions),
            color: AppColors.primary,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening directions...'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Action Buttons: Contact Merchant and Cancel Order
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Contact Merchant Button (Outline)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _currentStatus != 'cancelled' ? _contactMerchant : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, size: 20),
                const SizedBox(width: AppConstants.paddingS),
                Text(
                  'Contact Merchant',
                  style: AppTypography.buttonMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppConstants.paddingS),

        // Cancel Order Link (Text Button)
        if (_currentStatus != 'completed' && _currentStatus != 'cancelled')
          TextButton(
            onPressed: _cancelOrder,
            child: Text(
              'Cancel Order',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.error,
                decoration: TextDecoration.underline,
              ),
            ),
          ),

        // Mark as Completed (for ready status)
        if (_currentStatus == 'ready')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _currentStatus = 'completed');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order marked as completed!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.paddingM,
                ),
              ),
              child: Text(
                'Mark as Picked Up',
                style: AppTypography.buttonMedium,
              ),
            ),
          ),
      ],
    );
  }

  /// Show Order Details Dialog
  void _showOrderDetails() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusL),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Details', style: AppTypography.h4),
              const SizedBox(height: AppConstants.paddingM),
              _buildDetailRow('Order ID', '#${widget.orderId}'),
              _buildDetailRow('Merchant', _merchantName),
              _buildDetailRow('Type', _isPickup ? 'Self-Pickup' : 'Delivery'),
              _buildDetailRow('Total', '${AppConstants.currencySymbol}${_totalAmount.toStringAsFixed(2)}'),
              _buildDetailRow('Estimated Time', _estimatedTime),
              const SizedBox(height: AppConstants.paddingL),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
      child: Row(
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
      ),
    );
  }
}
