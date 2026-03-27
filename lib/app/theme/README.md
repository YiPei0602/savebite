# SaveBite design tokens

Use these files as the single source of truth for visual consistency across the app.

| Concern | File |
|--------|------|
| **Colors** (brand, background, text, borders, semantic) | `app_colors.dart` |
| **Typography** (text styles, font family via `google_fonts`) | `app_typography.dart` |
| **Spacing / radius / icon sizes** (shared layout numbers) | `../shared/constants/app_constants.dart` |

There is also `lib/core/theme/` which **re-exports** the same palette for features that import `package:savebite/core/theme/...` — keep `app_colors.dart` / `app_typography.dart` as the canonical definitions and avoid duplicating hex values elsewhere.

When adding a new screen, prefer:

- `AppColors.*` for colors  
- `AppTypography.*` for text styles  
- `AppConstants.padding*` / `radius*` for spacing and corners  
