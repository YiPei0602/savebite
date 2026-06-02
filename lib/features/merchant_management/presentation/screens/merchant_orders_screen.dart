import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';
import 'package:savebite/features/orders_payments/state/providers/order_provider.dart';
import 'package:savebite/features/merchant_management/presentation/screens/merchant_order_detail_screen.dart';
import 'package:savebite/shared/widgets/app_back_button.dart';
import 'package:savebite/shared/widgets/order/order_details_sheet.dart';
import 'package:savebite/shared/widgets/order/order_summary_card.dart';

class MerchantOrdersScreen extends StatefulWidget {
  const MerchantOrdersScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<MerchantOrdersScreen> createState() => _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends State<MerchantOrdersScreen> {
  bool _merchantOrdersInitialized = false;
  bool _initialPendingPromptShown = false;
  bool _newOrderDialogShowing = false;
  final Set<String> _seenOrderIds = <String>{};
  final Map<String, OrderStatus> _lastStatusByOrderId = <String, OrderStatus>{};

  bool _isMerchantRejectedOrder(OrderModel o) =>
      o.orderStatus == OrderStatus.cancelled &&
      o.cancellationReason == CancellationReason.merchantRejected;

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

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('New order received', style: AppTypography.h4),
          content: Text(
            'Order #${order.id} is waiting for your acceptance.',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openMerchantOrderDetail(context, order: order);
              },
              child: const Text('Review order'),
            ),
          ],
        ),
      ).whenComplete(() {
        _newOrderDialogShowing = false;
      });
    });
  }

  void _openOrderDetails(OrderModel order) {
    showOrderDetailsSheet(
      context,
      order: order,
      audience: OrderDetailsAudience.merchant,
    );
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
                            emptySubtitle:
                                'New orders will appear here instantly.',
                            onOrderTap: _openOrderDetails,
                          ),
                          _OrdersList(
                            orders: completed,
                            emptyTitle: 'No completed orders',
                            emptySubtitle:
                                'Fulfilled orders and buyer cancellations appear here.',
                            onOrderTap: _openOrderDetails,
                          ),
                          _OrdersList(
                            orders: rejected,
                            emptyTitle: 'No rejected orders',
                            emptySubtitle:
                                'Orders you decline while still pending appear here.',
                            onOrderTap: _openOrderDetails,
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
  const _OrdersList({
    required this.orders,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onOrderTap,
  });

  final List<OrderModel> orders;
  final String emptyTitle;
  final String emptySubtitle;
  final void Function(OrderModel order) onOrderTap;

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
        final awaitingAccept = order.orderStatus == OrderStatus.pending &&
            order.paymentStatus == PaymentStatus.paid;
        return OrderSummaryCard(
          order: order,
          audience: OrderSummaryAudience.merchant,
          highlightPending: awaitingAccept,
          onTap: () => onOrderTap(order),
        );
      },
    );
  }
}

class _InlineState extends StatelessWidget {
  const _InlineState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

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
