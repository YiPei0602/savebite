import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/food_card.dart';

/// Marketplace Screen
/// 
/// Displays available surplus food items from merchants.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Marketplace', style: AppTypography.h3),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filters
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          _buildCategoryFilter(),
          
          // Food Items Grid
          Expanded(
            child: _buildFoodGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', ...AppConstants.foodCategories];
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: AppConstants.paddingS),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primaryLight,
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

  Widget _buildFoodGrid() {
    // TODO: Replace with real data from Firebase
    final mockItems = List.generate(
      10,
      (index) => {
        'imageUrl': 'https://via.placeholder.com/400x300',
        'title': 'Delicious Food Item ${index + 1}',
        'merchantName': 'Restaurant ${index + 1}',
        'originalPrice': 25.00,
        'discountedPrice': 12.50,
        'discountPercentage': 50,
        'category': AppConstants.foodCategories[index % AppConstants.foodCategories.length],
        'quantity': 5 - (index % 6),
      },
    );

    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: AppConstants.paddingM,
        mainAxisSpacing: AppConstants.paddingM,
      ),
      itemCount: mockItems.length,
      itemBuilder: (context, index) {
        final item = mockItems[index];
        return FoodCard(
          imageUrl: item['imageUrl'] as String,
          title: item['title'] as String,
          merchantName: item['merchantName'] as String,
          originalPrice: item['originalPrice'] as double,
          discountedPrice: item['discountedPrice'] as double,
          discountPercentage: item['discountPercentage'] as int,
          category: item['category'] as String,
          quantity: item['quantity'] as int,
          onTap: () {
            // TODO: Navigate to food detail screen
          },
        );
      },
    );
  }
}
