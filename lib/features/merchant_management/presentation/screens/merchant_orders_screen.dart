import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';
import 'package:savebite/features/orders_payments/state/providers/order_provider.dart';
import 'package:savebite/shared/widgets/app_back_button.dart';

class MerchantOrdersScreen extends StatefulWidget {
  const MerchantOrdersScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<MerchantOrdersScreen> createState() => _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends State<MerchantOrdersScreen> {
  final _customerLabelCache = <String, String>{};
  final _customerInFlight = <String, Future<String>>{};

  bool _merchantOrdersInitialized = false;
  bool _initialPendingPromptShown = false;
  bool _newOrderDialogShowing = false;
  final Set<String> _seenOrderIds = <String>{};
  final Map<String, OrderStatus> _lastStatusByOrderId = <String, OrderStatus>{};

  bool _isMerchantRejectedOrder(OrderModel o) =>
      o.orderStatus == OrderStatus.cancelled &&
      o.cancellationReason == CancellationReason.merchantRejected;

  /// Completed tab: fulfilled + any cancelled that is **not** a merchant-at-pending reject.
  bool _inMerchantCompletedBucket(OrderModel o) {
    if (o.orderStatus == OrderStatus.completed) return true;
    if (o.orderStatus != OrderStatus.cancelled) return false;
    return !_isMerchantRejectedOrder(o);
  }

  static const _activeStatuses = <OrderStatus>[
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.findingDriver,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.pickedUpByDriver,
    OrderStatus.onTheWay,
  ];

  @override
  void dispose() {
    _customerInFlight.clear();
    super.dispose();
  }

  Future<String> _loadCustomerLabel(String userId) {
    if (_customerLabelCache.containsKey(userId)) {
      return Future.value(_customerLabelCache[userId]!);
    }
    if (_customerInFlight.containsKey(userId)) {
      return _customerInFlight[userId]!;
    }

    final f = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get()
        .timeout(const Duration(seconds: 6))
        .then((doc) {
      final data = doc.data();
      if (data == null) return 'Customer: $userId';
      final email = (data['email'] as String?)?.trim();
      final firstName = (data['firstName'] as String?)?.trim();
      final lastName = (data['lastName'] as String?)?.trim();
      final fullName =
          [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');

      final label = (fullName.isNotEmpty)
          ? fullName
          : (email != null && email.isNotEmpty)
              ? email
              : 'Customer: $userId';
      _customerLabelCache[userId] = label;
      return label;
    }).catchError((_) {
      final label = 'Customer: $userId';
      _customerLabelCache[userId] = label;
      return label;
    });

    _customerInFlight[userId] = f;
    return f;
  }

  String _formatStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.findingDriver:
        return 'Finding driver';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.pickedUpByDriver:
        return 'Driver picked up';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.onTheWay:
        return 'On the way';
    }
  }

  void _handleMerchantOrdersSnapshot(List<OrderModel> orders) {
    if (!_merchantOrdersInitialized) {
      _seenOrderIds
        ..clear()
        ..addAll(orders.map((o) => o.id));
      _lastStatusByOrderId
        ..clear()
        ..addEntries(orders.map((o) => MapEntry(o.id, o.orderStatus)));
      _merchantOrdersInitialized = true;
      final waitingOrders = orders
          .where((o) =>
              o.orderStatus == OrderStatus.pending &&
              o.paymentStatus == PaymentStatus.paid)
          .toList(growable: false);
      if (!_initialPendingPromptShown && waitingOrders.isNotEmpty) {
        _initialPendingPromptShown = true;
        _scheduleMerchantSnackBar(
          waitingOrders.length == 1
              ? 'New order waiting for acceptance'
              : '${waitingOrders.length} orders waiting for acceptance',
        );
        _scheduleNewOrderDialog(waitingOrders.first);
      }
      return;
    }

    for (final o in orders) {
      if (!_seenOrderIds.contains(o.id)) {
        _seenOrderIds.add(o.id);
        _lastStatusByOrderId[o.id] = o.orderStatus;
        // Only ping merchant for paid rescues awaiting acceptance (not unpaid/draft paths).
        if (o.orderStatus == OrderStatus.pending &&
            o.paymentStatus == PaymentStatus.paid) {
          _scheduleMerchantSnackBar('New order received');
          _scheduleNewOrderDialog(o);
        }
      } else {
        final prev = _lastStatusByOrderId[o.id];
        if (prev != null &&
            prev != OrderStatus.cancelled &&
            o.orderStatus == OrderStatus.cancelled) {
          final msg =
              _isMerchantRejectedOrder(o) ? 'Order rejected' : 'Order cancelled';
          _scheduleMerchantSnackBar(msg);
        }
        _lastStatusByOrderId[o.id] = o.orderStatus;
      }
    }
  }

  void _scheduleMerchantSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _scheduleNewOrderDialog(OrderModel order) {
    if (_newOrderDialogShowing) return;
    _newOrderDialogShowing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _newOrderDialogShowing = false;
        return;
      }

      final id = order.id;
      final shortId = id.length <= 6 ? id : id.substring(id.length - 6);
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('New order received', style: AppTypography.h4),
          content: Text(
            'Order #$shortId is waiting for your acceptance.',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Review order'),
            ),
          ],
        ),
      ).whenComplete(() {
        _newOrderDialogShowing = false;
      });
    });
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFF6B7280); // grey
      case OrderStatus.confirmed:
        return const Color(0xFF2563EB); // blue
      case OrderStatus.findingDriver:
        return const Color(0xFF7C3AED); // violet
      case OrderStatus.preparing:
        return const Color(0xFFF97316); // orange
      case OrderStatus.ready:
        return const Color(0xFF7C3AED); // purple / ready
      case OrderStatus.pickedUpByDriver:
        return const Color(0xFF0891B2); // cyan
      case OrderStatus.completed:
        return const Color(0xFF16A34A); // green
      case OrderStatus.cancelled:
        return const Color(0xFFDC2626); // red
      case OrderStatus.onTheWay:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, OrderProvider>(
      builder: (context, authProvider, orderProvider, _) {
        final user = authProvider.currentUser;
        final merchantId = user?.merchantId ?? user?.id;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              leading: widget.showBackButton ? const AppBackButton() : null,
              title: Text('Orders', style: AppTypography.h3),
              bottom: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Rejected'),
                ],
              ),
            ),
            body: (merchantId == null || merchantId.isEmpty)
                ? Center(
                    child: Text(
                      'Merchant session missing. Please log in again.',
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  )
                : StreamBuilder<List<OrderModel>>(
                    stream: orderProvider.watchMerchantOrders(merchantId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _InlineState(
                          icon: Icons.error_outline,
                          title: 'Unable to load orders',
                          subtitle: snapshot.error.toString(),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final orders = snapshot.data ?? const <OrderModel>[];
                      _handleMerchantOrdersSnapshot(orders);
                      final active = orders
                          .where((o) => _activeStatuses.contains(o.orderStatus))
                          .toList(growable: false);
                      final completed = orders
                          .where(_inMerchantCompletedBucket)
                          .toList(growable: false);
                      final rejected = orders
                          .where(_isMerchantRejectedOrder)
                          .toList(growable: false);

                      return TabBarView(
                        children: [
                          _OrdersList(
                            orders: active,
                            emptyTitle: 'No active orders',
                            emptySubtitle: 'New orders will appear here instantly.',
                            customerLabel: _loadCustomerLabel,
                            formatStatus: _formatStatus,
                            statusColor: _statusColor,
                          ),
                          _OrdersList(
                            orders: completed,
                            emptyTitle: 'No completed orders',
                            emptySubtitle:
                                'Fulfilled orders and buyer cancellations appear here.',
                            customerLabel: _loadCustomerLabel,
                            formatStatus: _formatStatus,
                            statusColor: _statusColor,
                          ),
                          _OrdersList(
                            orders: rejected,
                            emptyTitle: 'No rejected orders',
                            emptySubtitle:
                                'Orders you decline while still pending appear here.',
                            customerLabel: _loadCustomerLabel,
                            formatStatus: _formatStatus,
                            statusColor: _statusColor,
                          ),
                        ],
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<OrderModel> orders;
  final String emptyTitle;
  final String emptySubtitle;

  final Future<String> Function(String userId) customerLabel;
  final String Function(OrderStatus status) formatStatus;
  final Color Function(OrderStatus status) statusColor;

  const _OrdersList({
    required this.orders,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.customerLabel,
    required this.formatStatus,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _InlineState(
        icon: Icons.receipt_long,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(
          order: order,
          customerLabel: customerLabel,
          formatStatus: formatStatus,
          statusColor: statusColor,
        );
      },
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderModel order;
  final Future<String> Function(String userId) customerLabel;
  final String Function(OrderStatus status) formatStatus;
  final Color Function(OrderStatus status) statusColor;

  const _OrderCard({
    required this.order,
    required this.customerLabel,
    required this.formatStatus,
    required this.statusColor,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _busy = false;
  bool _riderSaveBusy = false;

  late final TextEditingController _riderNameC;
  late final TextEditingController _riderPhoneC;
  late final TextEditingController _riderVehicleC;
  late final TextEditingController _riderNoteC;

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    _riderNameC = TextEditingController(text: o.riderName ?? '');
    _riderPhoneC = TextEditingController(text: o.riderPhone ?? '');
    _riderVehicleC = TextEditingController(text: o.riderVehicleInfo ?? '');
    _riderNoteC = TextEditingController(text: o.riderNote ?? '');
  }

  @override
  void didUpdateWidget(covariant _OrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) {
      _riderNameC.text = widget.order.riderName ?? '';
      _riderPhoneC.text = widget.order.riderPhone ?? '';
      _riderVehicleC.text = widget.order.riderVehicleInfo ?? '';
      _riderNoteC.text = widget.order.riderNote ?? '';
      return;
    }
    if (oldWidget.order.riderUpdatedAt != widget.order.riderUpdatedAt) {
      _riderNameC.text = widget.order.riderName ?? '';
      _riderPhoneC.text = widget.order.riderPhone ?? '';
      _riderVehicleC.text = widget.order.riderVehicleInfo ?? '';
      _riderNoteC.text = widget.order.riderNote ?? '';
    }
  }

  @override
  void dispose() {
    _riderNameC.dispose();
    _riderPhoneC.dispose();
    _riderVehicleC.dispose();
    _riderNoteC.dispose();
    super.dispose();
  }

  Future<void> _saveRiderDetails() async {
    if (_riderSaveBusy) return;
    setState(() => _riderSaveBusy = true);
    final ok = await context.read<OrderProvider>().updateOrderRiderDetails(
          orderId: widget.order.id,
          riderName: _riderNameC.text,
          riderPhone: _riderPhoneC.text,
          riderVehicleInfo: _riderVehicleC.text,
          riderNote: _riderNoteC.text,
        );
    if (!mounted) return;
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
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rider details saved')),
    );
  }

  Future<void> _setStatus(OrderStatus status) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await context.read<OrderProvider>().updateOrderStatus(
          widget.order.id,
          status,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<OrderProvider>().errorMessage ?? 'Unable to update status',
          ),
        ),
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
          widget.order.id,
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
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order.orderStatus;
    final statusText = widget.formatStatus(status);
    final createdAtText = DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt);
    final id = order.id;
    final shortId = id.length <= 6 ? id : id.substring(id.length - 6);
    final statusColor = widget.statusColor(status);

    final bool showActions = status != OrderStatus.completed && status != OrderStatus.cancelled;

    final String? primaryLabel;
    final OrderStatus? primaryTarget;
    switch (status) {
      case OrderStatus.pending:
        primaryLabel = 'Accept Order';
        primaryTarget = OrderStatus.confirmed;
        break;
      case OrderStatus.confirmed:
        if (order.fulfillmentType == FulfillmentType.pickup) {
          primaryLabel = 'Start preparing';
          primaryTarget = OrderStatus.preparing;
        } else {
          primaryLabel = 'Finding driver';
          primaryTarget = OrderStatus.findingDriver;
        }
        break;
      case OrderStatus.findingDriver:
        primaryLabel = 'Start preparing';
        primaryTarget = OrderStatus.preparing;
        break;
      case OrderStatus.preparing:
        primaryLabel = 'Mark as ready';
        primaryTarget = OrderStatus.ready;
        break;
      case OrderStatus.ready:
        if (order.fulfillmentType == FulfillmentType.pickup) {
          primaryLabel = 'Complete order';
          primaryTarget = OrderStatus.completed;
        } else {
          primaryLabel = 'Hand off to driver';
          primaryTarget = OrderStatus.pickedUpByDriver;
        }
        break;
      case OrderStatus.pickedUpByDriver:
        primaryLabel = 'Out for delivery';
        primaryTarget = OrderStatus.onTheWay;
        break;
      case OrderStatus.onTheWay:
        primaryLabel = 'Mark delivered';
        primaryTarget = OrderStatus.completed;
        break;
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        primaryLabel = null;
        primaryTarget = null;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: ID + time
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #$shortId',
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.fulfillmentType == FulfillmentType.delivery
                        ? 'Delivery'
                        : 'Pickup',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              createdAtText,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),

            const SizedBox(height: 12),

            // Middle: customer + items
            FutureBuilder<String>(
              future: widget.customerLabel(order.userId),
              builder: (context, snap) {
                final label = snap.data ?? 'Customer: ${order.userId}';
                return Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Items',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            ...order.items.map((ci) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ci.foodItem.name,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'x${ci.quantity}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 14),

            // Bottom: total + status badge
            Row(
              children: [
                Text(
                  'Total',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${AppConstants.currencySymbol}${order.totalPrice.toStringAsFixed(2)}',
                  style: AppTypography.h5.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withOpacity(0.35)),
                  ),
                  child: Text(
                    statusText,
                    style: AppTypography.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            if (order.fulfillmentType == FulfillmentType.delivery) ...[
              const SizedBox(height: 16),
              Text(
                'Rider / delivery partner',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (showActions) ...[
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
                    labelText: 'Vehicle / plate (optional)',
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
                    onPressed: _riderSaveBusy ? null : _saveRiderDetails,
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
              ] else ...[
                if ((order.riderName ?? '').isNotEmpty ||
                    (order.riderPhone ?? '').isNotEmpty ||
                    (order.riderVehicleInfo ?? '').isNotEmpty ||
                    (order.riderNote ?? '').isNotEmpty) ...[
                  Text(
                    [
                      if ((order.riderName ?? '').isNotEmpty)
                        'Name: ${order.riderName}',
                      if ((order.riderPhone ?? '').isNotEmpty)
                        'Phone: ${order.riderPhone}',
                      if ((order.riderVehicleInfo ?? '').isNotEmpty)
                        'Vehicle: ${order.riderVehicleInfo}',
                      if ((order.riderNote ?? '').isNotEmpty)
                        'Note: ${order.riderNote}',
                    ].join('\n'),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ] else
                  Text(
                    'No rider details saved',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ],

            if (showActions && primaryLabel != null && primaryTarget != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy ? null : () => _setStatus(primaryTarget!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        ),
                        elevation: 0,
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
                          : Text(primaryLabel),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
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
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed:
                        _busy ? null : () => _setStatus(OrderStatus.onTheWay),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.divider.withOpacity(0.8)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                    ),
                    child: const Text('Out for delivery (skip handoff step)'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InlineState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

