import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/merchant_model.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/merchant_provider.dart';
import 'package:savebite/features/orders_payments/state/providers/order_provider.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';
import 'package:savebite/features/orders_payments/state/providers/cart_provider.dart';
import 'package:savebite/shared/utils/merchant_display_name_utils.dart';
import 'package:savebite/shared/widgets/app_back_button.dart';

/// Order History Screen
///
/// Displays user's past orders from OrderProvider with status and reorder functionality.
/// Used in the 'Orders' tab of main navigation.
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _selectedFilter = 'All';

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

  List<OrderModel> _getFilteredOrders(List<OrderModel> orders) {
    switch (_selectedFilter) {
      case 'Completed':
        return orders.where((o) => o.orderStatus == OrderStatus.completed).toList();
      case 'Cancelled':
        return orders.where((o) => o.orderStatus == OrderStatus.cancelled).toList();
      default:
        return orders;
    }
  }

  String _formatOrderStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.onTheWay:
        return 'On the way';
      default:
        return status.toString().split('.').last;
    }
  }

  void _reorderItems(
    BuildContext context,
    OrderModel order,
    CartProvider cartProvider,
    MerchantProvider merchantProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reorder', style: AppTypography.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add these items to your cart?',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppConstants.paddingM),
            ...(order.items.map((cartItem) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppConstants.paddingXS),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: Text(
                        cartItem.foodItem.name,
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            })),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              'From: ${_shopDisplayNameForOrder(order, merchantProvider)}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              for (final cartItem in order.items) {
                try {
                  cartProvider.addItem(
                    cartItem.foodItem,
                    quantity: cartItem.quantity,
                  );
                } catch (_) {}
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${order.totalItems} items added to cart'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Add to Cart', style: AppTypography.buttonMedium),
          ),
        ],
      ),
    );
  }

  void _viewOrderDetails(
    BuildContext context,
    OrderModel order,
    MerchantProvider merchantProvider,
  ) {
    final statusStr = _formatOrderStatus(order.orderStatus);
    final dateStr = DateFormat('d MMM yyyy').format(order.createdAt);
    final timeStr = DateFormat('h:mm a').format(order.createdAt);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppConstants.radiusL)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order Details', style: AppTypography.h3),
                      _buildStatusBadge(statusStr),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingL),
                  _buildDetailRow('Order ID', '#${order.id}'),
                  _buildDetailRow(
                    'Restaurant',
                    _shopDisplayNameForOrder(order, merchantProvider),
                  ),
                  _buildDetailRow('Date', '$dateStr, $timeStr'),
                  _buildDetailRow(
                    'Type',
                    order.fulfillmentType == FulfillmentType.pickup
                        ? 'Self-Pickup'
                        : 'Delivery',
                  ),
                  const SizedBox(height: AppConstants.paddingL),
                  Text('Items Ordered', style: AppTypography.h5),
                  const SizedBox(height: AppConstants.paddingM),
                  ...(order.items.map((cartItem) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingS),
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
                              '${cartItem.foodItem.name} x${cartItem.quantity}',
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  })),
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
                  const SizedBox(height: AppConstants.paddingL),
                  if (order.orderStatus == OrderStatus.completed)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _reorderItems(
                            context,
                            order,
                            context.read<CartProvider>(),
                            context.read<MerchantProvider>(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        child: Text('Reorder', style: AppTypography.buttonMedium),
                      ),
                    )
                  else if (order.orderStatus != OrderStatus.cancelled)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/order-tracking/${order.id}');
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        child:
                            Text('Track Order', style: AppTypography.buttonMedium),
                      ),
                    ),
                ],
              ),
            );
          },
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
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
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

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
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
        status,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              _selectedFilter == 'All'
                  ? 'You haven\'t placed any orders yet'
                  : 'No $_selectedFilter orders',
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

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppConstants.radiusL)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter Orders', style: AppTypography.h4),
              const SizedBox(height: AppConstants.paddingM),
              ListTile(
                leading:
                    const Icon(Icons.all_inclusive, color: AppColors.primary),
                title: Text('All Orders', style: AppTypography.bodyMedium),
                trailing: _selectedFilter == 'All'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedFilter = 'All');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.check_circle, color: AppColors.success),
                title: Text('Completed', style: AppTypography.bodyMedium),
                trailing: _selectedFilter == 'Completed'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedFilter = 'Completed');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: AppColors.error),
                title: Text('Cancelled', style: AppTypography.bodyMedium),
                trailing: _selectedFilter == 'Cancelled'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedFilter = 'Cancelled');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, OrderProvider, MerchantProvider>(
      builder: (context, authProvider, orderProvider, merchantProvider, _) {
        final paidOnly = orderProvider.orders
            .where((o) => o.paymentStatus == PaymentStatus.paid)
            .toList();
        final filteredOrders = _getFilteredOrders(paidOnly);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('Past Orders', style: AppTypography.h3),
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: const AppBackButton(color: AppColors.textPrimary),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list,
                    color: AppColors.textPrimary),
                onPressed: _showFilterOptions,
              ),
            ],
          ),
          body: orderProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildFilterChips(),
                    Expanded(
                      child: filteredOrders.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.all(AppConstants.paddingM),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = filteredOrders[index];
                                return _buildOrderCard(
                                  context,
                                  order,
                                  merchantProvider,
                                );
                              },
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Completed', 'Cancelled'];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: AppConstants.paddingS),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    OrderModel order,
    MerchantProvider merchantProvider,
  ) {
    final statusStr = _formatOrderStatus(order.orderStatus);
    final isCompleted = order.orderStatus == OrderStatus.completed;
    final dateStr = DateFormat('d MMM yyyy').format(order.createdAt);
    final timeStr = DateFormat('h:mm a').format(order.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: InkWell(
        onTap: () =>
            _viewOrderDetails(context, order, merchantProvider),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _shopDisplayNameForOrder(order, merchantProvider),
                      style: AppTypography.h5,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  _buildStatusBadge(statusStr),
                ],
              ),
              const SizedBox(height: AppConstants.paddingS),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: AppConstants.paddingXS),
                  Text(
                    '$dateStr, $timeStr',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingXS),
              Row(
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: AppConstants.paddingXS),
                  Text(
                    '${order.totalItems} ${order.totalItems == 1 ? 'item' : 'items'}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingM),
              const Divider(),
              const SizedBox(height: AppConstants.paddingM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingXS),
                      Text(
                        '${AppConstants.currencySymbol}${order.totalPrice.toStringAsFixed(2)}',
                        style: AppTypography.h5.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (isCompleted)
                    ElevatedButton(
                      onPressed: () => _reorderItems(
                        context,
                        order,
                        context.read<CartProvider>(),
                        merchantProvider,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingL,
                          vertical: AppConstants.paddingS,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusS),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.refresh, size: 16),
                          const SizedBox(width: AppConstants.paddingXS),
                          Text('Reorder', style: AppTypography.buttonSmall),
                        ],
                      ),
                    ),
                  if (!isCompleted && order.orderStatus != OrderStatus.cancelled)
                    OutlinedButton(
                      onPressed: () => _viewOrderDetails(
                        context,
                        order,
                        merchantProvider,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingM,
                          vertical: AppConstants.paddingS,
                        ),
                      ),
                      child: Text(
                        'View Details',
                        style: AppTypography.buttonSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

