import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/merchant_model.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/merchant_provider.dart';
import 'package:savebite/features/orders_payments/state/providers/order_provider.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';
import 'package:savebite/features/orders/buyer_order_progress.dart';
import 'package:savebite/shared/utils/merchant_display_name_utils.dart';
import 'package:savebite/shared/widgets/app_back_button.dart';
import 'package:savebite/shared/widgets/order/order_details_sheet.dart';
import 'package:savebite/shared/widgets/order/order_summary_card.dart';

/// Order History Screen — consumer orders list + shared detail sheet.
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  static const _filters = ['All', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final orderProvider = context.read<OrderProvider>();
      final mp = context.read<MerchantProvider>();
      if (mp.merchants.isEmpty && !mp.isLoading) {
        mp.loadMerchants();
      }
      if (authProvider.currentUser != null) {
        orderProvider.loadUserOrders(authProvider.currentUser!.id);
      }
    });
  }

  String _shopDisplayNameForOrder(
    OrderModel order,
    MerchantProvider merchantProvider,
  ) {
    MerchantModel? m;
    for (final x in merchantProvider.merchants) {
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
  }

  List<OrderModel> _getFilteredOrders(
    List<OrderModel> orders,
    String filter,
  ) {
    switch (filter) {
      case 'Completed':
        return orders
            .where((o) => o.orderStatus == OrderStatus.completed)
            .toList();
      case 'Cancelled':
        return orders
            .where((o) => o.orderStatus == OrderStatus.cancelled)
            .toList();
      default:
        return orders;
    }
  }

  void _openOrderDetails(
    BuildContext context,
    OrderModel order,
    MerchantProvider merchantProvider,
  ) {
    showOrderDetailsSheet(
      context,
      order: order,
      audience: OrderDetailsAudience.consumer,
      storeName: _shopDisplayNameForOrder(order, merchantProvider),
    );
  }

  Widget _buildEmptyState(String filter) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 100,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppConstants.paddingL),
            Text('No Orders Found', style: AppTypography.h3),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              filter == 'All'
                  ? 'You haven\'t placed any orders yet'
                  : 'No $filter orders',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList({
    required List<OrderModel> orders,
    required String filter,
    required MerchantProvider merchantProvider,
  }) {
    if (orders.isEmpty) {
      return _buildEmptyState(filter);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final storeName = _shopDisplayNameForOrder(order, merchantProvider);
        return OrderSummaryCard(
          order: order,
          audience: OrderSummaryAudience.consumer,
          storeName: storeName,
          cancelSubtitle: BuyerOrderProgress.cancellationHistorySubtitle(order),
          onTap: () => _openOrderDetails(context, order, merchantProvider),
        );
      },
    );
  }

  PreferredSizeWidget _buildOrdersAppBar() {
    return AppBar(
      title: Text('Orders', style: AppTypography.h3),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: const AppBackButton(color: AppColors.textPrimary),
      bottom: TabBar(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        labelStyle: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
        ),
        tabs: _filters.map((f) => Tab(text: f)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, OrderProvider, MerchantProvider>(
      builder: (context, authProvider, orderProvider, merchantProvider, _) {
        final paidOnly = orderProvider.orders
            .where((o) => o.paymentStatus == PaymentStatus.paid)
            .toList();

        return DefaultTabController(
          length: _filters.length,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildOrdersAppBar(),
            body: orderProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: _filters.map((filter) {
                      final filteredOrders =
                          _getFilteredOrders(paidOnly, filter);
                      return _buildOrdersList(
                        orders: filteredOrders,
                        filter: filter,
                        merchantProvider: merchantProvider,
                      );
                    }).toList(),
                  ),
          ),
        );
      },
    );
  }
}
