import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/app/theme/app_colors.dart';
import 'package:savebite/app/theme/app_typography.dart';
import 'package:savebite/features/auth_profile_impact/domain/models/user_model.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';
import 'package:savebite/features/orders_payments/state/providers/order_provider.dart';
import 'package:savebite/shared/constants/app_constants.dart';

/// Merchant Orders Screen
///
/// View and manage incoming orders.
class MerchantOrdersScreen extends StatefulWidget {
  const MerchantOrdersScreen({super.key});

  @override
  State<MerchantOrdersScreen> createState() => _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends State<MerchantOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _merchantId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final merchantId = auth.currentUser?.merchantId ?? auth.currentUser?.id;
    if (merchantId != null && merchantId.isNotEmpty && merchantId != _merchantId) {
      _merchantId = merchantId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<OrderProvider>().loadMerchantOrders(merchantId);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, OrderProvider>(
      builder: (context, authProvider, orderProvider, _) {
        final role = authProvider.userRole;

        final orders = orderProvider.orders;
        final newOrders =
            orders.where((o) => o.status == OrderStatus.pending).toList();
        final activeOrders = orders.where((o) {
          return o.status == OrderStatus.confirmed ||
              o.status == OrderStatus.preparing ||
              o.status == OrderStatus.ready ||
              o.status == OrderStatus.onTheWay;
        }).toList();
        final completedOrders = orders.where((o) {
          return o.status == OrderStatus.completed ||
              o.status == OrderStatus.cancelled;
        }).toList();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(
                    role == UserRole.merchant ? '/merchant-dashboard' : '/home',
                  );
                }
              },
            ),
            title: Text('Orders', style: AppTypography.h4),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              labelStyle: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: 'New (${newOrders.length})'),
                Tab(text: 'Active (${activeOrders.length})'),
                Tab(text: 'Completed (${completedOrders.length})'),
              ],
            ),
          ),
          body: orderProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrdersList(newOrders, 'new'),
                    _buildOrdersList(activeOrders, 'active'),
                    _buildOrdersList(completedOrders, 'completed'),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, String type) {
    if (orders.isEmpty) return _buildEmptyState(type);

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index], type);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, String type) {
    final itemsSummary = order.items.isEmpty
        ? 'No items'
        : order.items
            .map((i) => '${i.foodItem.name} x${i.quantity}')
            .take(2)
            .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
              Text('Order ${order.id}', style: AppTypography.h5),
              _buildStatusBadge(order.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                order.userId,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  itemsSummary,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RM ${order.totalPrice.toStringAsFixed(2)}',
                style: AppTypography.h5.copyWith(color: AppColors.primary),
              ),
              Text(
                _timeAgo(order.createdAt),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          if (type == 'new') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectOrder(order),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _acceptOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
          if (type == 'active') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _markReady(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text('Mark as Ready'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    String label;

    switch (status) {
      case OrderStatus.pending:
        color = AppColors.accent;
        label = 'New';
        break;
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
        color = Colors.blue;
        label = 'Preparing';
        break;
      case OrderStatus.ready:
      case OrderStatus.onTheWay:
        color = Colors.purple;
        label = 'Ready';
        break;
      case OrderStatus.completed:
        color = Colors.green;
        label = 'Completed';
        break;
      case OrderStatus.cancelled:
        color = AppColors.error;
        label = 'Cancelled';
        break;
      default:
        color = AppColors.textSecondary;
        label = status.name;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    IconData icon;

    switch (type) {
      case 'new':
        message = 'No new orders';
        icon = Icons.inbox;
        break;
      case 'active':
        message = 'No active orders';
        icon = Icons.hourglass_empty;
        break;
      default:
        message = 'No completed orders';
        icon = Icons.check_circle_outline;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.h4.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptOrder(OrderModel order) async {
    final ok = await context
        .read<OrderProvider>()
        .updateOrderStatus(order.id, OrderStatus.preparing);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${order.id} accepted'),
          backgroundColor: Colors.green,
        ),
      );
      _tabController.animateTo(1);
    }
  }

  void _rejectOrder(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: Text('Reject order ${order.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context
                  .read<OrderProvider>()
                  .updateOrderStatus(order.id, OrderStatus.cancelled);
              if (!context.mounted) return;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order ${order.id} rejected'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _markReady(OrderModel order) async {
    final ok =
        await context.read<OrderProvider>().updateOrderStatus(order.id, OrderStatus.ready);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${order.id} marked as ready'),
          backgroundColor: Colors.green,
        ),
      );
      _tabController.animateTo(2);
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}

