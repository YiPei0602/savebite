import 'dart:math';

/// Price Utilities
/// 
/// Helper functions for computing dynamic discounts based on time remaining.
class PriceUtils {
  PriceUtils._();

  /// Compute dynamic discount percentage based on time remaining until closing.
  /// 
  /// Formula: currentDiscount = minPercent + (maxPercent - minPercent) * progress
  /// where progress = 1 - clamp(timeRemaining / totalWindow, 0, 1)
  /// 
  /// This means:
  /// - When time remaining is high (far from closing): progress ≈ 0, discount ≈ minPercent
  /// - When time remaining is low (near closing): progress ≈ 1, discount ≈ maxPercent
  /// 
  /// Parameters:
  /// - [minPercent]: Minimum discount percentage (e.g., 30)
  /// - [maxPercent]: Maximum discount percentage (e.g., 70)
  /// - [closingTime]: When the item expires/closes
  /// - [totalWindowHours]: Total time window for discount progression (default: 8 hours)
  /// 
  /// Returns: Current discount percentage as integer (0-100)
  /// 
  /// TODO: When integrating with Firebase, fetch totalWindowHours from merchant settings
  static int computeDynamicDiscount({
    required int minPercent,
    required int maxPercent,
    required DateTime closingTime,
    double totalWindowHours = 8.0,
  }) {
    final now = DateTime.now();
    final timeRemaining = closingTime.difference(now);
    
    // If already closed or invalid time, return max discount
    if (timeRemaining.inSeconds <= 0) {
      return maxPercent;
    }
    
    // Calculate progress (0 = far from closing, 1 = near closing)
    final totalWindowSeconds = totalWindowHours * 3600;
    final timeRemainingSeconds = timeRemaining.inSeconds.toDouble();
    
    // Invert the ratio so discount increases as closing approaches
    final progress = 1.0 - min(timeRemainingSeconds / totalWindowSeconds, 1.0);
    final clampedProgress = max(0.0, min(1.0, progress));
    
    // Compute current discount
    final discountRange = maxPercent - minPercent;
    final currentDiscount = minPercent + (discountRange * clampedProgress);
    
    return currentDiscount.round();
  }

  /// Compute discounted price from original price and discount percentage.
  /// 
  /// Parameters:
  /// - [originalPrice]: Original price before discount
  /// - [discountPercent]: Discount percentage (0-100)
  /// 
  /// Returns: Discounted price rounded to 2 decimal places
  static double computeDiscountedPrice({
    required double originalPrice,
    required int discountPercent,
  }) {
    final discountAmount = originalPrice * (discountPercent / 100.0);
    final discountedPrice = originalPrice - discountAmount;
    return double.parse(discountedPrice.toStringAsFixed(2));
  }

  /// Check if item is closing soon (within threshold minutes).
  /// 
  /// Parameters:
  /// - [closingTime]: When the item expires/closes
  /// - [thresholdMinutes]: Minutes threshold for "closing soon" (default: 30)
  /// 
  /// Returns: true if closing within threshold, false otherwise
  static bool isClosingSoon({
    required DateTime closingTime,
    int thresholdMinutes = 30,
  }) {
    final now = DateTime.now();
    final timeRemaining = closingTime.difference(now);
    return timeRemaining.inMinutes > 0 && timeRemaining.inMinutes <= thresholdMinutes;
  }

  /// Format time remaining as human-readable string.
  /// 
  /// Examples:
  /// - "2h 30m"
  /// - "45m"
  /// - "5m"
  /// - "Closed"
  /// 
  /// Parameters:
  /// - [closingTime]: When the item expires/closes
  /// 
  /// Returns: Formatted time remaining string
  static String formatTimeRemaining(DateTime closingTime) {
    final now = DateTime.now();
    final timeRemaining = closingTime.difference(now);
    
    if (timeRemaining.inSeconds <= 0) {
      return 'Closed';
    }
    
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
