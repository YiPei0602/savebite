import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savebite/app/theme/app_colors.dart';
import 'package:savebite/app/theme/app_typography.dart';
import 'package:savebite/features/auth_profile_impact/domain/models/user_model.dart';
import 'package:savebite/features/auth_profile_impact/presentation/utils/impact_display.dart';
import 'package:savebite/features/auth_profile_impact/presentation/widgets/impact_profile_cards.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/shared/constants/app_constants.dart';
import 'package:savebite/shared/widgets/app_back_button.dart';

/// Impact Dashboard Screen
///
/// Shows live [ImpactData] from Firestore (updated when paid orders complete).
/// Consumer: CO₂e, meals saved, money saved. Merchant: CO₂e + meals rescued only.
class ImpactDashboardScreen extends StatelessWidget {
  const ImpactDashboardScreen({super.key});

  /// Next display target for progress bars (always ahead of [current] once past 4).
  static int _nextMilestone(int current) {
    if (current <= 0) return 5;
    if (current < 5) return 5;
    var m = ((current + 9) ~/ 10) * 10;
    if (current >= m) {
      m += 10;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Your Impact', style: AppTypography.h3),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const AppBackButton(),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.currentUser;
          if (user == null) {
            return Center(
              child: Text(
                'Sign in to see your impact.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          final isMerchant = user.role == UserRole.merchant;
          final d = user.impactData;
          final meals = d.mealsSaved;
          final co2 = d.co2Reduced;
          final money = d.moneySaved;
          final ordersDone = d.ordersCompleted;

          final ordersTarget = _nextMilestone(ordersDone);
          final mealsTarget = _nextMilestone(meals);
          final mealsTitle = ImpactDisplay.mealsTitle(isMerchant: isMerchant);
          final co2Title = ImpactDisplay.co2Title(isMerchant: isMerchant);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<AuthProvider>().refreshUserProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Making a Difference',
                    style: AppTypography.h2,
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    ImpactDisplay.impactSubtitle(isMerchant: isMerchant),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingXL),
                  ImpactDetailMetricCard(
                    icon: Icons.eco,
                    title: co2Title,
                    value: ImpactDisplay.formatCo2Kg(co2),
                    subtitle: ImpactDisplay.co2PerMealHint(),
                    accentColor: AppColors.co2Reduced,
                    backgroundColor: AppColors.impactCo2Fill,
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  ImpactDetailMetricCard(
                    icon: Icons.restaurant,
                    title: mealsTitle,
                    value: '$meals',
                    subtitle: isMerchant
                        ? 'Portions rescued at your store'
                        : 'Rescued portions',
                    accentColor: AppColors.impactMealsAccent,
                    backgroundColor: AppColors.impactMealsFill,
                  ),
                  if (!isMerchant) ...[
                    const SizedBox(height: AppConstants.paddingM),
                    ImpactDetailMetricCard(
                      icon: Icons.savings,
                      title: ImpactDisplay.consumerMoneyTitle,
                      value: ImpactDisplay.formatMoneyDetail(money),
                      subtitle: 'Sum of listing discounts',
                      accentColor: AppColors.moneySaved,
                      backgroundColor: AppColors.impactMoneyFill,
                    ),
                  ],
                  const SizedBox(height: AppConstants.paddingXL),
                  Text(
                    'Milestones',
                    style: AppTypography.h4,
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  _buildProgressCard(
                    title: 'Orders completed',
                    current: ordersDone,
                    target: ordersTarget,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  _buildProgressCard(
                    title: mealsTitle,
                    current: meals,
                    target: mealsTarget,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required int current,
    required int target,
    required Color color,
  }) {
    final cappedTarget = target < 1 ? 1 : target;
    final progress = current / cappedTarget;
    final displayProgress = progress > 1.0 ? 1.0 : progress;

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
                '$current / $cappedTarget',
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
              value: displayProgress,
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
