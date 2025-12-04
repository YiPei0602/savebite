import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../constants/app_constants.dart';

/// Food Card Widget
/// 
/// A reusable card component for displaying food items in the marketplace.
class FoodCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String merchantName;
  final double originalPrice;
  final double discountedPrice;
  final int discountPercentage;
  final String? category;
  final int? quantity;
  final VoidCallback? onTap;
  final bool showBadge;

  const FoodCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.merchantName,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercentage,
    this.category,
    this.quantity,
    this.onTap,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Image with Discount Badge
            _buildImageSection(),
            
            // Food Details
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: AppTypography.h5,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppConstants.paddingXS),
                  
                  // Merchant Name
                  Row(
                    children: [
                      const Icon(
                        Icons.store,
                        size: AppConstants.iconXS,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppConstants.paddingXS),
                      Expanded(
                        child: Text(
                          merchantName,
                          style: AppTypography.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  if (category != null) ...[
                    const SizedBox(height: AppConstants.paddingXS),
                    _buildCategoryChip(),
                  ],
                  
                  const SizedBox(height: AppConstants.paddingS),
                  
                  // Price Section
                  Row(
                    children: [
                      // Discounted Price
                      Text(
                        '${AppConstants.currencySymbol}${discountedPrice.toStringAsFixed(2)}',
                        style: AppTypography.priceMedium,
                      ),
                      const SizedBox(width: AppConstants.paddingS),
                      
                      // Original Price (crossed out)
                      Text(
                        '${AppConstants.currencySymbol}${originalPrice.toStringAsFixed(2)}',
                        style: AppTypography.priceSmall,
                      ),
                    ],
                  ),
                  
                  if (quantity != null) ...[
                    const SizedBox(height: AppConstants.paddingXS),
                    Text(
                      '$quantity left',
                      style: AppTypography.caption.copyWith(
                        color: quantity! < 5 ? AppColors.warning : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Food Image
        CachedNetworkImage(
          imageUrl: imageUrl,
          height: AppConstants.imageCardHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: AppConstants.imageCardHeight,
            color: AppColors.surfaceVariant,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: AppConstants.imageCardHeight,
            color: AppColors.surfaceVariant,
            child: const Icon(
              Icons.fastfood,
              size: AppConstants.iconXL,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        
        // Discount Badge
        if (showBadge)
          Positioned(
            top: AppConstants.paddingS,
            right: AppConstants.paddingS,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingS,
                vertical: AppConstants.paddingXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Text(
                '-$discountPercentage%',
                style: AppTypography.discountBadge,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingS,
        vertical: AppConstants.paddingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Text(
        category!,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
