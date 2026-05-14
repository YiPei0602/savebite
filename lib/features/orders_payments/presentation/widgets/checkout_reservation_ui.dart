import 'package:flutter/material.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';

/// `MM:SS` from now until [expiresAtUtc] (clips at `00:00`).
String checkoutReservationCountdownMmSs(DateTime expiresAtUtc) {
  final now = DateTime.now().toUtc();
  var d = expiresAtUtc.difference(now);
  if (d.isNegative) d = Duration.zero;
  final t = d.inSeconds.clamp(0, 5999);
  final m = (t ~/ 60).toString().padLeft(2, '0');
  final s = (t % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

bool checkoutReservationExpired(DateTime expiresAtUtc) {
  return !DateTime.now().toUtc().isBefore(expiresAtUtc);
}

/// Compact countdown chip for app bar actions.
class ReservationCountdownBadge extends StatelessWidget {
  const ReservationCountdownBadge({
    super.key,
    required this.expiresAtUtc,
  });

  final DateTime expiresAtUtc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 16,
            color: checkoutReservationExpired(expiresAtUtc)
                ? AppColors.error
                : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            checkoutReservationCountdownMmSs(expiresAtUtc),
            style: AppTypography.bodySmall.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w600,
              color: checkoutReservationExpired(expiresAtUtc)
                  ? AppColors.error
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> showLeaveCheckoutDialog(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Leave checkout?'),
      content: const Text(
        'Are you sure you want to leave checkout?\n'
        'Your reserved items will remain locked temporarily until the reservation expires.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Continue checkout'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.error,
          ),
          child: const Text('Leave checkout'),
        ),
      ],
    ),
  );
  return leave ?? false;
}

Future<void> showReservationExpiredDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Reservation expired'),
      content: const Text(
        'Reservation expired. Please place your order again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
