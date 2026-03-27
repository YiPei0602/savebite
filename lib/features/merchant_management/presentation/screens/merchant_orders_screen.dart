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

  static const _activeStatuses = <OrderStatus>[
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.ready,
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
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.onTheWay:
        return 'On the way';
    }
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFF6B7280); // grey
      case OrderStatus.confirmed:
        return const Color(0xFF2563EB); // blue
      case OrderStatus.preparing:
        return const Color(0xFFF97316); // orange
      case OrderStatus.ready:
        return const Color(0xFF7C3AED); // purple
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
          length: 2,
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
                      final active = orders
                          .where((o) => _activeStatuses.contains(o.orderStatus))
                          .toList(growable: false);
                      final completed = orders
                          .where((o) =>
                              o.orderStatus == OrderStatus.completed ||
                              o.orderStatus == OrderStatus.cancelled)
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
                            emptySubtitle: 'Completed/cancelled orders will appear here.',
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
        primaryLabel = 'Start Preparing';
        primaryTarget = OrderStatus.preparing;
        break;
      case OrderStatus.preparing:
        primaryLabel = 'Mark as Ready';
        primaryTarget = OrderStatus.ready;
        break;
      case OrderStatus.ready:
        primaryLabel = 'Complete Order';
        primaryTarget = OrderStatus.completed;
        break;
      case OrderStatus.completed:
      case OrderStatus.cancelled:
      case OrderStatus.onTheWay:
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
                      onPressed: _busy ? null : () => _setStatus(OrderStatus.cancelled),
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
                      child: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
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

