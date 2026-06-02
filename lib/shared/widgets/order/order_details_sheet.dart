import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/orders/buyer_order_progress.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';
import 'package:savebite/features/orders_payments/state/providers/order_provider.dart';
import 'package:savebite/shared/widgets/merchant_order_customer_name.dart';
import 'package:savebite/shared/widgets/order/order_display_utils.dart';

enum OrderDetailsAudience { consumer, merchant }

/// Opens the shared order details bottom sheet for consumer or merchant.
Future<void> showOrderDetailsSheet(
  BuildContext context, {
  required OrderModel order,
  required OrderDetailsAudience audience,
  String? storeName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppConstants.radiusL),
      ),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.80,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          if (audience == OrderDetailsAudience.merchant) {
            return _MerchantOrderDetailsSheet(
              orderId: order.id,
              initialOrder: order,
              scrollController: scrollController,
            );
          }
          return _ConsumerOrderDetailsSheet(
            order: order,
            storeName: storeName ?? order.merchantName,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

class _ConsumerOrderDetailsSheet extends StatelessWidget {
  const _ConsumerOrderDetailsSheet({
    required this.order,
    required this.storeName,
    required this.scrollController,
  });

  final OrderModel order;
  final String storeName;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          OrderDetailsBody(
            order: order,
            audience: OrderDetailsAudience.consumer,
            storeName: storeName,
          ),
          if (order.orderStatus != OrderStatus.completed &&
              order.orderStatus != OrderStatus.cancelled) ...[
            const SizedBox(height: AppConstants.paddingL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/order-tracking/${order.id}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  'Track Order',
                  style: AppTypography.buttonMedium,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppConstants.paddingL),
        ],
      ),
    );
  }
}

class _MerchantOrderDetailsSheet extends StatelessWidget {
  const _MerchantOrderDetailsSheet({
    required this.orderId,
    required this.initialOrder,
    required this.scrollController,
  });

  final String orderId;
  final OrderModel initialOrder;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.read<OrderProvider>();
    return StreamBuilder<OrderModel?>(
      stream: orderProvider.watchOrderById(orderId),
      initialData: initialOrder,
      builder: (context, snapshot) {
        final order = snapshot.data ?? initialOrder;
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              OrderDetailsBody(
                order: order,
                audience: OrderDetailsAudience.merchant,
              ),
              const SizedBox(height: AppConstants.paddingL),
              _MerchantOrderActions(order: order),
              const SizedBox(height: AppConstants.paddingL),
            ],
          ),
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingL),
      ],
    );
  }
}

/// Shared order detail fields (list shows summary only).
class OrderDetailsBody extends StatelessWidget {
  const OrderDetailsBody({
    super.key,
    required this.order,
    required this.audience,
    this.storeName,
  });

  final OrderModel order;
  final OrderDetailsAudience audience;
  final String? storeName;

  @override
  Widget build(BuildContext context) {
    final statusLabel = formatOrderStatusLabel(order.orderStatus);
    final cancelNote = order.orderStatus == OrderStatus.cancelled
        ? (audience == OrderDetailsAudience.consumer
            ? BuyerOrderProgress.cancellationHistoryDetailNote(order)
            : null)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Order Details', style: AppTypography.h3),
            _DetailStatusBadge(label: statusLabel),
          ],
        ),
        const SizedBox(height: AppConstants.paddingL),
        _DetailRow('Order ID', '#${order.id}'),
        _DetailRow('Date', formatOrderDateTime(order.createdAt)),
        _DetailRow('Type', fulfillmentTypeDetailLabel(order.fulfillmentType)),
        if (audience == OrderDetailsAudience.merchant)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    'Customer',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: MerchantOrderCustomerName(
                    order: order,
                    prefixWithCustomerLabel: false,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          )
        else if ((storeName ?? '').isNotEmpty)
          _DetailRow('Restaurant', storeName!),
        if (order.fulfillmentType == FulfillmentType.pickup &&
            (order.pickupAddress ?? '').trim().isNotEmpty)
          _DetailRow('Pickup', order.pickupAddress!.trim()),
        if (order.fulfillmentType == FulfillmentType.delivery &&
            (order.deliveryAddress ?? '').trim().isNotEmpty)
          _DetailRow('Delivery', order.deliveryAddress!.trim()),
        _DetailRow('Payment', paymentMethodLabel(order.paymentMethod)),
        if (cancelNote != null && cancelNote.isNotEmpty) ...[
          const SizedBox(height: AppConstants.paddingM),
          Text(
            cancelNote,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
        if (order.fulfillmentType == FulfillmentType.delivery) ...[
          const SizedBox(height: AppConstants.paddingM),
          Text('Rider', style: AppTypography.h5),
          const SizedBox(height: AppConstants.paddingS),
          if ((order.riderName ?? '').isEmpty &&
              (order.riderPhone ?? '').isEmpty &&
              (order.riderVehicleInfo ?? '').isEmpty &&
              (order.riderNote ?? '').isEmpty)
            Text(
              audience == OrderDetailsAudience.merchant
                  ? 'Add rider details below when dispatching delivery.'
                  : 'The store has not added rider details yet.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            if ((order.riderName ?? '').isNotEmpty)
              _DetailRow('Name', order.riderName!),
            if ((order.riderPhone ?? '').isNotEmpty)
              _DetailRow('Phone', order.riderPhone!),
            if ((order.riderVehicleInfo ?? '').isNotEmpty)
              _DetailRow('Vehicle', order.riderVehicleInfo!),
            if ((order.riderNote ?? '').isNotEmpty)
              _DetailRow('Note', order.riderNote!),
          ],
        ],
        const SizedBox(height: AppConstants.paddingL),
        Text('Items Ordered', style: AppTypography.h5),
        const SizedBox(height: AppConstants.paddingM),
        ...order.items.map((cartItem) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: Text(
                    cartItem.foodItem.name,
                    style: AppTypography.bodyMedium,
                  ),
                ),
                Text(
                  'x${cartItem.quantity}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
        if (order.deliveryFee > 0) ...[
          const SizedBox(height: AppConstants.paddingS),
          _DetailRow(
            'Delivery fee',
            '${AppConstants.currencySymbol}${order.deliveryFee.toStringAsFixed(2)}',
          ),
        ],
        if (order.totalSavings > 0) ...[
          _DetailRow(
            'Savings',
            '-${AppConstants.currencySymbol}${order.totalSavings.toStringAsFixed(2)}',
          ),
        ],
        const SizedBox(height: AppConstants.paddingL),
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Paid', style: AppTypography.h5),
              Text(
                '${AppConstants.currencySymbol}${order.totalPrice.toStringAsFixed(2)}',
                style: AppTypography.h4.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStatusBadge extends StatelessWidget {
  const _DetailStatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    switch (label) {
      case 'Completed':
        backgroundColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        break;
      case 'Cancelled':
        backgroundColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        break;
      default:
        backgroundColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingS,
        vertical: AppConstants.paddingXS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MerchantOrderActions extends StatefulWidget {
  const _MerchantOrderActions({required this.order});

  final OrderModel order;

  @override
  State<_MerchantOrderActions> createState() => _MerchantOrderActionsState();
}

class _MerchantOrderActionsState extends State<_MerchantOrderActions> {
  bool _busy = false;
  bool _riderSaveBusy = false;

  late TextEditingController _riderNameC;
  late TextEditingController _riderPhoneC;
  late TextEditingController _riderVehicleC;
  late TextEditingController _riderNoteC;

  OrderModel get order => widget.order;

  @override
  void initState() {
    super.initState();
    _initRiderControllers(order);
  }

  @override
  void didUpdateWidget(covariant _MerchantOrderActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != order.id ||
        oldWidget.order.riderUpdatedAt != order.riderUpdatedAt) {
      _riderNameC.text = order.riderName ?? '';
      _riderPhoneC.text = order.riderPhone ?? '';
      _riderVehicleC.text = order.riderVehicleInfo ?? '';
      _riderNoteC.text = order.riderNote ?? '';
    }
  }

  void _initRiderControllers(OrderModel o) {
    _riderNameC = TextEditingController(text: o.riderName ?? '');
    _riderPhoneC = TextEditingController(text: o.riderPhone ?? '');
    _riderVehicleC = TextEditingController(text: o.riderVehicleInfo ?? '');
    _riderNoteC = TextEditingController(text: o.riderNote ?? '');
  }

  bool get _hasRiderCoreDetails {
    return _riderNameC.text.trim().isNotEmpty &&
        _riderPhoneC.text.trim().isNotEmpty &&
        _riderVehicleC.text.trim().isNotEmpty;
  }

  bool _validateRiderCoreDetails() {
    if (_hasRiderCoreDetails) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please fill rider name, phone, and vehicle plate first.'),
      ),
    );
    return false;
  }

  @override
  void dispose() {
    _riderNameC.dispose();
    _riderPhoneC.dispose();
    _riderVehicleC.dispose();
    _riderNoteC.dispose();
    super.dispose();
  }

  Future<bool> _saveRiderDetails({bool showSuccessSnackBar = true}) async {
    if (_riderSaveBusy) return false;
    setState(() => _riderSaveBusy = true);
    final ok = await context.read<OrderProvider>().updateOrderRiderDetails(
          orderId: order.id,
          riderName: _riderNameC.text,
          riderPhone: _riderPhoneC.text,
          riderVehicleInfo: _riderVehicleC.text,
          riderNote: _riderNoteC.text,
        );
    if (!mounted) return false;
    setState(() => _riderSaveBusy = false);
    if (ok == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<OrderProvider>().errorMessage ??
                'Unable to save rider details',
          ),
        ),
      );
      return false;
    }
    if (showSuccessSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rider details saved')),
      );
    }
    return true;
  }

  Future<void> _saveRiderAndStartPreparing() async {
    if (_busy || _riderSaveBusy) return;
    if (!_validateRiderCoreDetails()) return;

    final saved = await _saveRiderDetails(showSuccessSnackBar: false);
    if (!saved || !mounted) return;
    await _setStatus(OrderStatus.preparing);
  }

  Future<void> _setStatus(OrderStatus status) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await context.read<OrderProvider>().updateOrderStatus(
          order.id,
          status,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<OrderProvider>().errorMessage ??
                'Unable to update status',
          ),
        ),
      );
      return;
    }
    if (status == OrderStatus.confirmed &&
        order.orderStatus == OrderStatus.pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order accepted')),
      );
    }
  }

  Future<void> _confirmRejectPending() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject this order?', style: AppTypography.h4),
        content: Text(
          'The customer will see this order as cancelled. You won\'t need to prepare or hand it off.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep order'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (!mounted || go != true) return;

    if (_busy) return;
    setState(() => _busy = true);
    final ok = await context.read<OrderProvider>().rejectPendingOrderAsMerchant(
          order.id,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Order rejected'
              : context.read<OrderProvider>().errorMessage ??
                  'Unable to reject order',
        ),
      ),
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  ({String? label, OrderStatus? target}) _primaryAction() {
    switch (order.orderStatus) {
      case OrderStatus.pending:
        return (label: 'Accept Order', target: OrderStatus.confirmed);
      case OrderStatus.confirmed:
        if (order.fulfillmentType == FulfillmentType.pickup) {
          return (label: 'Start preparing', target: OrderStatus.preparing);
        }
        return (label: 'Finding driver', target: OrderStatus.findingDriver);
      case OrderStatus.findingDriver:
        return (label: null, target: null);
      case OrderStatus.preparing:
        return (label: 'Mark as ready', target: OrderStatus.ready);
      case OrderStatus.ready:
        if (order.fulfillmentType == FulfillmentType.pickup) {
          return (label: null, target: null);
        }
        return (label: 'Hand off to driver', target: OrderStatus.pickedUpByDriver);
      case OrderStatus.pickedUpByDriver:
        return (label: 'Out for delivery', target: OrderStatus.onTheWay);
      case OrderStatus.onTheWay:
        return (label: 'Mark delivered', target: OrderStatus.completed);
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return (label: null, target: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = order.orderStatus;
    final showActions =
        status != OrderStatus.completed && status != OrderStatus.cancelled;
    final primary = _primaryAction();
    final showRiderAssignment = order.fulfillmentType == FulfillmentType.delivery &&
        (status == OrderStatus.findingDriver ||
            (status == OrderStatus.ready && !_hasRiderCoreDetails));
    final isFindingDriver = status == OrderStatus.findingDriver;

    if (!showActions) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showRiderAssignment) ...[
          Text(
            'Rider / delivery partner',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _riderNameC,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _riderPhoneC,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone (WhatsApp)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _riderVehicleC,
            decoration: const InputDecoration(
              labelText: 'Vehicle Plate Number',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _riderNoteC,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: isFindingDriver || _riderSaveBusy
                  ? null
                  : () => _saveRiderDetails(),
              icon: _riderSaveBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save rider details'),
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
        ],
        if (isFindingDriver) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_busy || _riderSaveBusy)
                  ? null
                  : _saveRiderAndStartPreparing,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: (_busy || _riderSaveBusy)
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save rider & start preparing'),
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
        ],
        if (order.fulfillmentType == FulfillmentType.pickup &&
            status == OrderStatus.ready) ...[
          Text(
            'Ready for customer pickup. They will confirm collection in the app.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
        ],
        if (primary.label != null && primary.target != null)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _busy ? null : () => _setStatus(primary.target!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(primary.label!),
                ),
              ),
              if (status == OrderStatus.pending) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _busy ? null : _confirmRejectPending,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ],
            ],
          ),
        if (order.fulfillmentType == FulfillmentType.delivery &&
            status == OrderStatus.ready) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : () => _setStatus(OrderStatus.onTheWay),
            child: const Text('Out for delivery (skip handoff step)'),
          ),
        ],
      ],
    );
  }
}
