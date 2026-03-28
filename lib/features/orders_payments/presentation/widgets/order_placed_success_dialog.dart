import 'package:flutter/material.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_typography.dart';

Future<void> showOrderPlacedSuccessDialog({
  required BuildContext context,
  required String orderId,
  required VoidCallback onTrackOrder,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF212121),
              size: 60,
            ),
          ),
          const SizedBox(height: AppConstants.paddingL),
          Text(
            'Order Placed!',
            style: AppTypography.h3.copyWith(
              color: const Color(0xFF212121),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            'Your order has been successfully placed.',
            style: AppTypography.bodyMedium.copyWith(
              color: const Color(0xFF616161),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingXS),
          Text(
            'Order #$orderId',
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: AppConstants.paddingL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTrackOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF212121),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.primaryCtaVerticalPadding,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.primaryCtaPillRadius,
                  ),
                ),
              ),
              child: Text(
                'Order Status',
                style: AppTypography.buttonMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
