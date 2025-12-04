import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../constants/app_constants.dart';

/// Custom Button Widget
/// 
/// A reusable button component that follows SaveBite design system.
/// Supports primary, secondary, and text button variants.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Color? customColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = _getButtonHeight();
    final buttonPadding = _getButtonPadding();
    final textStyle = _getTextStyle();

    Widget buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == ButtonVariant.primary
                    ? AppColors.textOnPrimary
                    : AppColors.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppConstants.iconS),
                const SizedBox(width: AppConstants.paddingS),
              ],
              Text(text, style: textStyle),
            ],
          );

    Widget button;

    switch (variant) {
      case ButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: customColor ?? AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            minimumSize: Size(0, buttonHeight),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
          ),
          child: buttonChild,
        );
        break;

      case ButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: customColor ?? AppColors.primary,
            side: BorderSide(
              color: customColor ?? AppColors.primary,
              width: 1.5,
            ),
            minimumSize: Size(0, buttonHeight),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
          ),
          child: buttonChild,
        );
        break;

      case ButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: customColor ?? AppColors.primary,
            minimumSize: Size(0, buttonHeight),
            padding: buttonPadding,
          ),
          child: buttonChild,
        );
        break;

      case ButtonVariant.accent:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: customColor ?? AppColors.accent,
            foregroundColor: AppColors.textOnAccent,
            minimumSize: Size(0, buttonHeight),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
          ),
          child: buttonChild,
        );
        break;
    }

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  double _getButtonHeight() {
    switch (size) {
      case ButtonSize.small:
        return AppConstants.buttonHeightS;
      case ButtonSize.medium:
        return AppConstants.buttonHeightM;
      case ButtonSize.large:
        return AppConstants.buttonHeightL;
    }
  }

  EdgeInsets _getButtonPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingS,
        );
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: AppConstants.paddingM,
        );
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingXL,
          vertical: AppConstants.paddingM,
        );
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return AppTypography.buttonSmall.copyWith(
          color: variant == ButtonVariant.primary || variant == ButtonVariant.accent
              ? AppColors.textOnPrimary
              : customColor ?? AppColors.primary,
        );
      case ButtonSize.medium:
        return AppTypography.buttonMedium.copyWith(
          color: variant == ButtonVariant.primary || variant == ButtonVariant.accent
              ? AppColors.textOnPrimary
              : customColor ?? AppColors.primary,
        );
      case ButtonSize.large:
        return AppTypography.buttonLarge.copyWith(
          color: variant == ButtonVariant.primary || variant == ButtonVariant.accent
              ? AppColors.textOnPrimary
              : customColor ?? AppColors.primary,
        );
    }
  }
}

enum ButtonVariant { primary, secondary, text, accent }

enum ButtonSize { small, medium, large }
