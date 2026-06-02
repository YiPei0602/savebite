import 'package:savebite/shared/constants/app_constants.dart';

/// Copy and formatting for sustainability impact metrics (consumer vs merchant).
abstract final class ImpactDisplay {
  // Consumer labels
  static const consumerMealsTitle = 'Total Meals Saved';
  static const consumerMoneyTitle = 'Total Money Saved';
  static const consumerCo2Title = 'Estimated CO₂e Prevented';

  // Merchant labels
  static const merchantMealsTitle = 'Total Meals Rescued';
  static const merchantMoneyTitle = 'Total Money Earned';
  static const merchantCo2Title = 'Estimated CO₂e Prevented';

  static String mealsTitle({required bool isMerchant}) =>
      isMerchant ? merchantMealsTitle : consumerMealsTitle;

  static String co2Title({required bool isMerchant}) =>
      isMerchant ? merchantCo2Title : consumerCo2Title;

  /// Short labels for Profile summary tiles (avoid wrap in half-width columns).
  static String profileMealsLabel({required bool isMerchant}) =>
      isMerchant ? 'Meals rescued' : 'Meals saved';

  static String profileMoneyLabel({required bool isMerchant}) =>
      isMerchant ? 'Money earned' : 'Money saved';
  static const profileCo2Label = 'CO₂e prevented';

  static const profileSubtitle = 'From completed orders · 1 item = 1 meal';

  /// One decimal place (e.g. 1 meal × 2.7 → `2.7 kg`).
  static String formatCo2Kg(double kg) => '${kg.toStringAsFixed(1)} kg';

  /// Profile summary tile — whole RM for readability.
  static String formatMoneySummary(double rm) =>
      '${AppConstants.currencySymbol} ${rm.toStringAsFixed(0)}';

  /// Detailed dashboard — two decimals for totals.
  static String formatMoneyDetail(double rm) =>
      '${AppConstants.currencySymbol}${rm.toStringAsFixed(2)}';

  static String co2PerMealHint() =>
      '≈ ${AppConstants.co2PerMeal} kg per meal (modelled)';

  static String impactSubtitle({required bool isMerchant}) => isMerchant
      ? 'Totals from completed rescues at your store (1 quantity = 1 meal).'
      : 'Totals from your completed food rescues (1 quantity = 1 meal).';
}
