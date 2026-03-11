# SaveBite Design Constants Reference

This document is the quick reference for shared UI constants used across the app.
Source of truth remains code constants in `lib/app/theme/` and `lib/shared/constants/`.

## 1) Color Tokens

Defined in:
- `lib/app/theme/app_colors.dart`

Core tokens:
- `primary`: `#00615F` (brand teal)
- `accent`: `#FF8C42` (accent orange)
- `background`: `#F9F3F0`
- `surface`: `#FFFFFF`
- `textPrimary`: `#2B2D42`
- `textSecondary`: `#8D99AE`
- `border`: `#CED4DA`
- `borderActive`: `#00615F`
- `error`: `#E63946`
- `success`: `#06D6A0`

Button tokens:
- `buttonPrimary`: `#111111`
- `buttonPrimaryPressed`: `#000000`
- `textOnPrimary`: `#FFFFFF`

## 2) Typography Tokens

Defined in:
- `lib/app/theme/app_typography.dart`

Font family:
- `Inter` (via `google_fonts`)

Common sizes:
- `h1`: 32
- `h2`: 24
- `h3`: 20
- `h4`: 18
- `h5`: 16
- `bodyLarge`: 16
- `bodyMedium`: 14
- `bodySmall`: 12
- `buttonLarge`: 16
- `buttonMedium`: 14
- `buttonSmall`: 12

## 3) Spacing and Shape Tokens

Defined in:
- `lib/shared/constants/app_constants.dart`

Spacing:
- `paddingXS`: 4
- `paddingS`: 8
- `paddingM`: 16
- `paddingL`: 24
- `paddingXL`: 32

Radii:
- `radiusS`: 8
- `radiusM`: 12
- `radiusL`: 16
- `radiusXL`: 24
- `buttonRadius`: 16 (shared button curvature standard)

Button heights:
- `buttonHeightS`: 36
- `buttonHeightM`: 48
- `buttonHeightL`: 56

## 4) Global Button Styling

Primary shared button widget:
- `lib/shared/widgets/custom_button.dart`

Theme-level button defaults:
- `lib/app/theme/app_theme.dart`

Current standards:
- Primary button color: `AppColors.buttonPrimary`
- Primary button text color: `AppColors.textOnPrimary`
- Shared button corner radius: `AppConstants.buttonRadius`
- Primary auth CTAs (`Login`, `Create Account`) use black background with white text

## 5) Related Files

- `lib/shared/widgets/custom_text_field.dart`
- `lib/shared/widgets/status_modal.dart`
- `lib/features/auth_profile_impact/presentation/screens/login_screen.dart`
- `lib/features/auth_profile_impact/presentation/screens/signup_screen.dart`

