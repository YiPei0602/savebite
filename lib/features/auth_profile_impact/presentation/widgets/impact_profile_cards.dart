import 'package:flutter/material.dart';
import 'package:savebite/app/theme/app_colors.dart';
import 'package:savebite/app/theme/app_typography.dart';
import 'package:savebite/shared/constants/app_constants.dart';

/// Unified impact metric card used on Profile (primary = CO₂, secondary = money/meals).
class ImpactProfileMetricCard extends StatelessWidget {
  const ImpactProfileMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.backgroundColor,
    this.emphasized = false,
    this.largeValue = false,
    this.alignWithPrimary = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final Color backgroundColor;

  /// Primary CO₂ card — taller padding and large value (no left accent bar).
  final bool emphasized;

  /// Same value font size as [emphasized] (e.g. merchant full-width meals card).
  final bool largeValue;

  /// Match CO₂ card padding, icon size, and value typography.
  final bool alignWithPrimary;

  static const double _secondaryMinHeight = 112;
  static const double _primaryMinHeight = 120;
  static const double _primaryValueFontSize = 40;

  bool get _primaryLayout => emphasized || alignWithPrimary;

  TextStyle _valueStyle() {
    final large = emphasized || largeValue || alignWithPrimary;
    return (large ? AppTypography.h1 : AppTypography.h2).copyWith(
      color: emphasized ? AppColors.primary : AppColors.textPrimary,
      fontWeight: FontWeight.w800,
      fontSize: large ? _primaryValueFontSize : null,
      height: 1.1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: _primaryLayout ? _primaryMinHeight : _secondaryMinHeight,
      ),
      padding: EdgeInsets.all(
        _primaryLayout ? AppConstants.paddingL : AppConstants.paddingM,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(emphasized ? 0.18 : 0.12),
            blurRadius: emphasized ? 10 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _IconBadge(icon: icon, color: accentColor, large: _primaryLayout),
          SizedBox(
            width: _primaryLayout ? AppConstants.paddingM : AppConstants.paddingS,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: _valueStyle(),
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: emphasized
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    this.large = false,
  });

  final IconData icon;
  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 52.0 : 44.0;
    final iconSize = large ? 28.0 : 22.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// Equal-height row for two secondary impact cards (consumer money + meals).
class ImpactProfileMetricRow extends StatelessWidget {
  const ImpactProfileMetricRow({
    super.key,
    required this.left,
    required this.right,
  });

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(child: right),
        ],
      ),
    );
  }
}

/// Compact top card used in profile "Your impact" snapshot.
class ImpactSnapshotMiniCard extends StatelessWidget {
  const ImpactSnapshotMiniCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 26),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            value,
            style: AppTypography.h2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Large hero card (Meals saved / rescued) in profile "Your impact" snapshot.
class ImpactSnapshotHeroCard extends StatelessWidget {
  const ImpactSnapshotHeroCard({
    super.key,
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
              size: 52,
            ),
          ),
          const SizedBox(width: AppConstants.paddingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.h1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Text(
                  title,
                  style: AppTypography.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-color detail card for [/impact] — same row layout as before, tinted background only.
class ImpactDetailMetricCard extends StatelessWidget {
  const ImpactDetailMetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.14),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Icon(
              icon,
              size: AppConstants.iconL,
              color: accentColor,
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
                    color: accentColor,
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
}
