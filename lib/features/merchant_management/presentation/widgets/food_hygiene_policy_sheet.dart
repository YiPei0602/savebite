import 'package:flutter/material.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';

/// Opens a scrollable bottom sheet with the full SaveBite Food Hygiene & Safety Policy.
Future<void> showFoodHygienePolicySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final bottomInset = MediaQuery.paddingOf(ctx).bottom;
      return FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'SaveBite Food Hygiene & Safety Policy',
                textAlign: TextAlign.center,
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottomInset),
                child: const _FoodHygienePolicyBody(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _FoodHygienePolicyBody extends StatelessWidget {
  const _FoodHygienePolicyBody();

  @override
  Widget build(BuildContext context) {
    final headingStyle = AppTypography.bodyMedium.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      height: 1.35,
    );
    final bodyStyle = AppTypography.bodySmall.copyWith(
      color: AppColors.textSecondary,
      height: 1.5,
    );

    Widget section(String heading, List<String> paragraphs) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading, style: headingStyle),
            const SizedBox(height: 6),
            ...paragraphs.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(p, style: bodyStyle),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section(
          '1. Merchant Responsibility',
          const [
            'Merchants are fully responsible for ensuring that all food '
                'items listed on SaveBite are safe, properly stored, and '
                'suitable for consumption at the time of pickup or delivery.',
          ],
        ),
        section(
          '2. Food Hygiene Requirements',
          const [
            'Merchants must prepare, handle, and store food in a clean and '
                'hygienic environment that complies with applicable food '
                'safety practices and local regulations.',
          ],
        ),
        section(
          '3. Food Quality & Freshness',
          const [
            'Food items must not be expired, spoiled, contaminated, or unsafe '
                'for consumption. Merchants are responsible for monitoring '
                'freshness and safe consumption periods before publishing listings.',
          ],
        ),
        section(
          '4. Accurate Listing Information',
          const [
            'Merchants must provide accurate information regarding:',
            '• Food name,\n'
                '• ingredients or allergens where applicable,\n'
                '• quantity,\n'
                '• pickup or delivery details,\n'
                '• pricing and discount information.',
            'Misleading or false listings are prohibited.',
          ],
        ),
        section(
          '5. Prohibited Food Items',
          const [
            'Merchants must not list:',
            '• expired food,\n'
                '• unsafe or contaminated food,\n'
                '• prohibited or illegal food products,\n'
                '• food that may pose health risks to consumers.',
          ],
        ),
        section(
          '6. Platform Limitation',
          const [
            'SaveBite acts solely as a digital platform connecting merchants '
                'and consumers. SaveBite does not prepare, inspect, or directly '
                'handle food items listed by merchants.',
          ],
        ),
        section(
          '7. Enforcement Actions',
          const [
            'SaveBite reserves the right to remove listings, suspend merchant '
                'accounts, or take appropriate action if merchants violate '
                'this policy or receive repeated food safety complaints.',
          ],
        ),
        section(
          '8. Policy Reference',
          const [
            'This policy is developed with reference to:',
            '• Food Act 1983 (Malaysia)\n'
                '• Food Hygiene Regulations 2009 (Malaysia)',
          ],
        ),
        section(
          '9. Agreement',
          const [
            'By publishing a listing on SaveBite, the merchant acknowledges '
                'and agrees to comply with this Food Hygiene & Safety Policy.',
          ],
        ),
      ],
    );
  }
}
