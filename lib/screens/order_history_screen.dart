import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/constants/app_constants.dart';
import 'order_tracking_screen.dart';

/// Order History Screen
/// 
/// Displays user's past orders with status and reorder functionality.
/// Used in the 'Orders' tab of main navigation.
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  // Filter: All, Completed, Cancelled
  String _selectedFilter = 'All';

  // Dummy order data
  final List<Map<String, dynamic>> _orders = [
    {
      'orderId': 'SB12345',
      'restaurantName': 'The Baker\'s Cottage',
      'date': '2 Dec 2024',
      'time': '6:30 PM',
      'status': 'Completed',
      'totalPrice': 23.00,
      'itemCount': 3,
      'items': ['Surplus Pastry Box', 'Mixed Bread Bundle', 'Cake Slice Combo'],
      'merchantAddress': '123 Gurney Drive, Penang',
      'isPickup': true,
    },
    {
      'orderId': 'SB12344',
      'restaurantName': 'Nasi Kandar Pelita',
      'date': '1 Dec 2024',
      'time': '7:00 PM',
      'status': 'Completed',
      'totalPrice': 15.50,
      'itemCount': 2,
      'items': ['Nasi Kandar Set', 'Roti Canai'],
      'merchantAddress': '456 Jalan Sultan, Penang',
      'isPickup': true,
    },
    {
      'orderId': 'SB12343',
      'restaurantName': 'Green Leaf Cafe',
      'date': '30 Nov 2024',
      'time': '1:00 PM',
      'status': 'Completed',
      'totalPrice': 18.00,
      'itemCount': 1,
      'items': ['Vegetarian Bowl'],
      'merchantAddress': '789 Lebuh Chulia, Penang',
      'isPickup': false,
    },
    {
      'orderId': 'SB12342',
      'restaurantName': 'KFC Gurney Plaza',
      'date': '28 Nov 2024',
      'time': '8:00 PM',
      'status': 'Cancelled',
      'totalPrice': 25.00,
      'itemCount': 2,
      'items': ['Chicken Bucket', 'Coleslaw'],
      'merchantAddress': 'Gurney Plaza, Penang',
      'isPickup': true,
    },
    {
      'orderId': 'SB12341',
      'restaurantName': 'The Baker\'s Cottage',
      'date': '25 Nov 2024',
      'time': '5:30 PM',
      'status': 'Completed',
      'totalPrice': 12.00,
      'itemCount': 2,
      'items': ['Cookie Assortment', 'Sandwich Pack'],
      'merchantAddress': '123 Gurney Drive, Penang',
      'isPickup': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'All') {
      return _orders;
    }
    return _orders.where((order) => order['status'] == _selectedFilter).toList();
  }

  void _reorderItems(Map<String, dynamic> order) {
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
            ...((order['items'] as List<String>).map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.paddingXS,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              'From: ${order['restaurantName']}',
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${order['itemCount']} items added to cart'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text('Add to Cart', style: AppTypography.buttonMedium),
          ),
        ],
      ),
    );
  }

  void _viewOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusL),
        ),
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
                  // Drag handle
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

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order Details', style: AppTypography.h3),
                      _buildStatusBadge(order['status'] as String),
                    ],
                  ),

                  const SizedBox(height: AppConstants.paddingL),

                  // Order Info
                  _buildDetailRow('Order ID', '#${order['orderId']}'),
                  _buildDetailRow('Restaurant', order['restaurantName'] as String),
                  _buildDetailRow('Date', '${order['date']}, ${order['time']}'),
                  _buildDetailRow(
                    'Type',
                    order['isPickup'] as bool ? 'Self-Pickup' : 'Delivery',
                  ),

                  const SizedBox(height: AppConstants.paddingL),

                  // Items
                  Text('Items Ordered', style: AppTypography.h5),
                  const SizedBox(height: AppConstants.paddingM),
                  ...((order['items'] as List<String>).map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.paddingS,
                      ),
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
                              item,
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()),

                  const SizedBox(height: AppConstants.paddingL),

                  // Total
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
                          '${AppConstants.currencySymbol}${order['totalPrice'].toStringAsFixed(2)}',
                          style: AppTypography.h4.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingL),

                  // Actions
                  if (order['status'] == 'Completed') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _reorderItems(order);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: Text('Reorder', style: AppTypography.buttonMedium),
                      ),
                    ),
                  ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Past Orders', style: AppTypography.h3),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),

          // Orders List
          Expanded(
            child: _filteredOrders.isEmpty
                ? _buildEmptyState()
                : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  /// Filter Chips
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
              onSelected: (selected) {
                setState(() => _selectedFilter = filter);
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Orders List
  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  /// Order Card
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final isCompleted = status == 'Completed';

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: InkWell(
        onTap: () => _viewOrderDetails(order),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Restaurant Name and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order['restaurantName'] as String,
                      style: AppTypography.h5,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  _buildStatusBadge(status),
                ],
              ),

              const SizedBox(height: AppConstants.paddingS),

              // Date and Time
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppConstants.paddingXS),
                  Text(
                    '${order['date']}, ${order['time']}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingXS),

              // Item Count
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppConstants.paddingXS),
                  Text(
                    '${order['itemCount']} ${order['itemCount'] == 1 ? 'item' : 'items'}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingM),

              const Divider(),

              const SizedBox(height: AppConstants.paddingM),

              // Footer: Total Price and Reorder Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Total Price
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
                        '${AppConstants.currencySymbol}${order['totalPrice'].toStringAsFixed(2)}',
                        style: AppTypography.h5.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Reorder Button (only for completed orders)
                  if (isCompleted)
                    ElevatedButton(
                      onPressed: () => _reorderItems(order),
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
                          Text(
                            'Reorder',
                            style: AppTypography.buttonSmall,
                          ),
                        ],
                      ),
                    ),

                  // View Details for cancelled orders
                  if (!isCompleted)
                    OutlinedButton(
                      onPressed: () => _viewOrderDetails(order),
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

  /// Status Badge
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

  /// Empty State
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
            Text(
              'No Orders Found',
              style: AppTypography.h3,
            ),
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

  /// Show Filter Options
  void _showFilterOptions() {
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
              Text('Filter Orders', style: AppTypography.h4),
              const SizedBox(height: AppConstants.paddingM),
              ListTile(
                leading: const Icon(Icons.all_inclusive, color: AppColors.primary),
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
                leading: const Icon(Icons.check_circle, color: AppColors.success),
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
}
