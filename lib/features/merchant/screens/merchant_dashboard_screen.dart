import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

/// Merchant Dashboard Screen
/// 
/// Main hub for merchants to manage their surplus food listings
/// GrabFood-inspired clean, modern design
class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  // Dummy data for merchant's surplus items
  final List<Map<String, dynamic>> _surplusItems = [
    {
      'id': '1',
      'name': 'Surplus Pastry Box',
      'originalPrice': 25.00,
      'discountedPrice': 12.50,
      'quantity': 3,
      'category': 'Bakery',
      'status': 'active',
      'imageUrl': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400',
    },
    {
      'id': '2',
      'name': 'Mixed Rice Bowl',
      'originalPrice': 18.00,
      'discountedPrice': 9.00,
      'quantity': 5,
      'category': 'Halal',
      'status': 'active',
      'imageUrl': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400',
    },
    {
      'id': '3',
      'name': 'Vegetarian Combo',
      'originalPrice': 22.00,
      'discountedPrice': 11.00,
      'quantity': 0,
      'category': 'Vegetarian',
      'status': 'sold_out',
      'imageUrl': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeItems = _surplusItems.where((item) => item['status'] == 'active').length;
    final soldOutItems = _surplusItems.where((item) => item['status'] == 'sold_out').length;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Stats Cards
            _buildStatsSection(activeItems, soldOutItems),
            
            // Listings Section
            Expanded(
              child: _buildListingsSection(),
            ),
          ],
        ),
      ),
      
      // Floating Action Button - Add New Item
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/add-surplus');
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Item',
          style: AppTypography.buttonMedium,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      color: AppColors.surface,
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back),
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 8),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Restaurant',
                  style: AppTypography.h3,
                ),
                Text(
                  'Manage your surplus food',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Orders Icon
          IconButton(
            onPressed: () => context.push('/merchant-orders'),
            icon: Icon(
              Icons.receipt_long,
              color: AppColors.primary,
            ),
            tooltip: 'Orders',
          ),
          
          // Donation Icon
          IconButton(
            onPressed: () => context.push('/donation-prompt'),
            icon: Icon(
              Icons.volunteer_activism,
              color: Colors.green,
            ),
            tooltip: 'Donate',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(int activeItems, int soldOutItems) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.inventory_2_outlined,
              value: activeItems.toString(),
              label: 'Active Items',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_outline,
              value: soldOutItems.toString(),
              label: 'Sold Out',
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.trending_up,
              value: 'RM ${((12.50 + 9.00) * 2).toStringAsFixed(0)}',
              label: 'Today',
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h4.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
          child: Text(
            'My Listings',
            style: AppTypography.h4,
          ),
        ),
        const SizedBox(height: 12),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
            itemCount: _surplusItems.length,
            itemBuilder: (context, index) {
              final item = _surplusItems[index];
              return _buildListingCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListingCard(Map<String, dynamic> item) {
    final isSoldOut = item['status'] == 'sold_out';
    final discount = ((1 - (item['discountedPrice'] / item['originalPrice'])) * 100).round();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppConstants.radiusM),
              bottomLeft: Radius.circular(AppConstants.radiusM),
            ),
            child: Stack(
              children: [
                Image.network(
                  item['imageUrl'],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: AppColors.background,
                      child: Icon(
                        Icons.fastfood,
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
                if (isSoldOut)
                  Container(
                    width: 100,
                    height: 100,
                    color: Colors.black.withOpacity(0.6),
                    child: Center(
                      child: Text(
                        'SOLD OUT',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name'],
                          style: AppTypography.h5,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$discount% OFF',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['category'],
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'RM ${item['originalPrice'].toStringAsFixed(2)}',
                        style: AppTypography.bodySmall.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RM ${item['discountedPrice'].toStringAsFixed(2)}',
                        style: AppTypography.h5.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: isSoldOut ? AppColors.error : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item['quantity']} left',
                        style: AppTypography.caption.copyWith(
                          color: isSoldOut ? AppColors.error : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Actions
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppColors.textSecondary,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                context.push('/edit-surplus/${item['id']}');
              } else if (value == 'delete') {
                _showDeleteDialog(item['name']);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
