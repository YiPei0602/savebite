import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

/// Merchant Orders Screen
/// 
/// View and manage incoming orders
class MerchantOrdersScreen extends StatefulWidget {
  const MerchantOrdersScreen({super.key});

  @override
  State<MerchantOrdersScreen> createState() => _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends State<MerchantOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<Map<String, dynamic>> _newOrders = [
    {
      'id': '#12345',
      'customer': 'John Doe',
      'items': 'Surplus Pastry Box x2',
      'total': 25.00,
      'time': '5 min ago',
      'status': 'pending',
    },
    {
      'id': '#12344',
      'customer': 'Jane Smith',
      'items': 'Mixed Rice Bowl x1',
      'total': 9.00,
      'time': '15 min ago',
      'status': 'pending',
    },
  ];

  final List<Map<String, dynamic>> _activeOrders = [
    {
      'id': '#12343',
      'customer': 'Ahmad Ali',
      'items': 'Vegetarian Combo x1',
      'total': 11.00,
      'time': '30 min ago',
      'status': 'preparing',
    },
  ];

  final List<Map<String, dynamic>> _completedOrders = [
    {
      'id': '#12342',
      'customer': 'Sarah Lee',
      'items': 'Surplus Pastry Box x1',
      'total': 12.50,
      'time': '2 hours ago',
      'status': 'completed',
    },
    {
      'id': '#12341',
      'customer': 'Michael Tan',
      'items': 'Mixed Rice Bowl x2',
      'total': 18.00,
      'time': '3 hours ago',
      'status': 'completed',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/merchant-dashboard');
            }
          },
        ),
        title: Text(
          'Orders',
          style: AppTypography.h4,
        ),
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
            Tab(text: 'New (${_newOrders.length})'),
            Tab(text: 'Active (${_activeOrders.length})'),
            const Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(_newOrders, 'new'),
          _buildOrdersList(_activeOrders, 'active'),
          _buildOrdersList(_completedOrders, 'completed'),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders, String type) {
    if (orders.isEmpty) {
      return _buildEmptyState(type);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index], type);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, String type) {
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order ${order['id']}',
                style: AppTypography.h5,
              ),
              _buildStatusBadge(order['status']),
            ],
          ),
          const SizedBox(height: 12),
          
          // Customer Info
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                order['customer'],
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Items
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
                  order['items'],
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Total & Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RM ${order['total'].toStringAsFixed(2)}',
                style: AppTypography.h5.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Text(
                order['time'],
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          
          // Action Buttons
          if (type == 'new') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectOrder(order),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'pending':
        color = AppColors.accent;
        label = 'New';
        break;
      case 'preparing':
        color = Colors.blue;
        label = 'Preparing';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        break;
      default:
        color = AppColors.textSecondary;
        label = status;
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
            style: AppTypography.h4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _acceptOrder(Map<String, dynamic> order) {
    setState(() {
      _newOrders.remove(order);
      order['status'] = 'preparing';
      _activeOrders.insert(0, order);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ${order['id']} accepted'),
        backgroundColor: Colors.green,
      ),
    );
    
    _tabController.animateTo(1);
  }

  void _rejectOrder(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: Text('Reject order ${order['id']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _newOrders.remove(order);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order ${order['id']} rejected'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _markReady(Map<String, dynamic> order) {
    setState(() {
      _activeOrders.remove(order);
      order['status'] = 'completed';
      _completedOrders.insert(0, order);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ${order['id']} marked as ready'),
        backgroundColor: Colors.green,
      ),
    );
    
    _tabController.animateTo(2);
  }
}
