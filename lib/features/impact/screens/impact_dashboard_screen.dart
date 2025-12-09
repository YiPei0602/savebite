import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

/// Impact Dashboard Screen
/// 
/// Displays personalized impact metrics: meals saved, CO2 reduced, money saved.
class ImpactDashboardScreen extends StatelessWidget {
  const ImpactDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Your Impact', style: AppTypography.h3),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Making a Difference',
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              'Track your contribution to reducing food waste',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingXL),
            
            // Impact Metrics
            _buildImpactCard(
              icon: Icons.restaurant,
              title: 'Meals Saved',
              value: '42',
              subtitle: 'Rescued from waste',
              color: AppColors.mealsSaved,
            ),
            
            const SizedBox(height: AppConstants.paddingM),
            
            _buildImpactCard(
              icon: Icons.eco,
              title: 'CO₂ Reduced',
              value: '105 kg',
              subtitle: 'Carbon footprint saved',
              color: AppColors.co2Reduced,
            ),
            
            const SizedBox(height: AppConstants.paddingM),
            
            _buildImpactCard(
              icon: Icons.savings,
              title: 'Money Saved',
              value: '${AppConstants.currencySymbol}525',
              subtitle: 'Through discounted food',
              color: AppColors.moneySaved,
            ),
            
            const SizedBox(height: AppConstants.paddingXL),
            
            // Monthly Progress
            Text(
              'This Month',
              style: AppTypography.h4,
            ),
            const SizedBox(height: AppConstants.paddingM),
            
            _buildProgressCard(
              title: 'Orders Completed',
              current: 12,
              target: 20,
              color: AppColors.primary,
            ),
            
            const SizedBox(height: AppConstants.paddingM),
            
            _buildProgressCard(
              title: 'Impact Goal',
              current: 42,
              target: 50,
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Icon(
              icon,
              size: AppConstants.iconL,
              color: color,
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Text(
                  value,
                  style: AppTypography.impactNumber.copyWith(
                    color: color,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Text(
                  subtitle,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required int current,
    required int target,
    required Color color,
  }) {
    final progress = current / target;
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
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
              Text(title, style: AppTypography.h5),
              Text(
                '$current / $target',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
