import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../marketplace_surplus/domain/models/merchant_model.dart';
import '../../marketplace_surplus/state/providers/merchant_provider.dart';
import '../../orders_payments/state/providers/order_provider.dart';
import '../../orders_payments/domain/models/order_model.dart';
import '../../../shared/utils/merchant_display_name_utils.dart';
import '../../../shared/widgets/app_back_button.dart';

/// Order Tracking Screen
///
/// Loads order once from Firestore via [OrderProvider.getOrderById].
/// Displays [OrderStatus] and addresses from the order document (no simulated progress).
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
  OrderModel? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrder());
  }

  Future<void> _loadOrder() async {
    final orderProvider = context.read<OrderProvider>();
    final o = await orderProvider.getOrderById(widget.orderId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _order = o;
      _error = o == null ? 'Order not found' : null;
    });
  }

  String _resolveMerchantName() {
    final order = _order;
    if (order == null) return widget.merchantName ?? 'Store';
    try {
      final mp = context.read<MerchantProvider>();
      MerchantModel? m;
      for (final x in mp.merchants) {
        if (x.id == order.merchantId) {
          m = x;
          break;
        }
      }
      return consumerShopDisplayName(
        merchantId: order.merchantId,
        merchantProfile: m,
        fromFoodItem: order.merchantName,
      );
    } catch (_) {
      return order.merchantName;
    }
  }

  String _resolveAddress() {
    final order = _order;
    if (order == null) {
      return widget.merchantAddress ?? '';
    }
    if (order.fulfillmentType == FulfillmentType.delivery) {
      return order.deliveryAddress?.trim().isNotEmpty == true
          ? order.deliveryAddress!.trim()
          : '';
    }
    return order.pickupAddress?.trim().isNotEmpty == true
        ? order.pickupAddress!.trim()
        : '';
  }

  bool _resolveIsPickup() {
    final order = _order;
    if (order != null) {
      return order.fulfillmentType == FulfillmentType.pickup;
    }
    return widget.isPickup ?? true;
  }

  double _resolveTotal() {
    final order = _order;
    if (order != null) return order.totalPrice;
    return widget.totalAmount ?? 0.0;
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
              _resolveMerchantName(),
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

  Future<void> _cancelOrder() async {
    if (_order == null) return;
    await showDialog<void>(
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
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final orderProvider = context.read<OrderProvider>();
              Navigator.pop(context);
              final ok = await orderProvider.cancelOrder(widget.orderId);
              if (!mounted) return;
              if (ok) {
                await _loadOrder();
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Order cancelled'),
                    backgroundColor: AppColors.error,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      orderProvider.errorMessage ?? 'Could not cancel order',
                    ),
                  ),
                );
              }
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
    final appBar = AppBar(
      title: Text('Order Tracking', style: AppTypography.h3),
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: const AppBackButton(color: AppColors.textPrimary),
      actions: [
        if (!_loading && _error == null && _order != null)
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.textPrimary),
            onPressed: _showOrderDetails,
          ),
      ],
    );

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: appBar,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: appBar,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Text(
              _error ?? 'Unable to load order',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _buildMapView(),
          ),
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
              label: _resolveMerchantName(),
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

  /// Status from Firestore [OrderModel.orderStatus] (Pending / Completed / Cancelled display).
  Widget _buildStatusIndicator() {
    final s = _order!.orderStatus;
    final String statusText;
    final String statusDescription;
    final Color statusColor;
    final IconData statusIcon;

    if (s == OrderStatus.completed) {
      statusText = 'Completed';
      statusDescription = 'Thank you for your order.';
      statusColor = AppColors.success;
      statusIcon = Icons.done_all;
    } else if (s == OrderStatus.cancelled) {
      statusText = 'Cancelled';
      statusDescription = 'This order has been cancelled.';
      statusColor = AppColors.error;
      statusIcon = Icons.cancel;
    } else {
      statusText = 'Pending';
      statusDescription = 'Your order is being processed.';
      statusColor = AppColors.warning;
      statusIcon = Icons.schedule;
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
      child: Row(
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
                  _resolveMerchantName(),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Text(
                  _resolveAddress().isEmpty ? '—' : _resolveAddress(),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
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
    final status = _order!.orderStatus;
    final canCancel = status != OrderStatus.completed &&
        status != OrderStatus.cancelled;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed:
                status != OrderStatus.cancelled ? _contactMerchant : null,
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

        if (canCancel)
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
              _buildDetailRow('Merchant', _resolveMerchantName()),
              _buildDetailRow('Type', _resolveIsPickup() ? 'Self-Pickup' : 'Delivery'),
              _buildDetailRow('Total', '${AppConstants.currencySymbol}${_resolveTotal().toStringAsFixed(2)}'),
              _buildDetailRow(
                'Status',
                _order!.orderStatus.toString().split('.').last,
              ),
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
