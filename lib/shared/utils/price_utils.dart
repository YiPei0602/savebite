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
  }) {
    final max = maxPercent.clamp(0, 100);
    final minPct = minPercent.clamp(0, max);
    final span = max - minPct;
    if (span == 0) return minPct;

    final minutesLeft = closingTime.difference(DateTime.now()).inMinutes;
    if (minutesLeft <= 0) return max;

    final double t;
    if (minutesLeft > 240) {
      t = 0.0;
    } else if (minutesLeft > 120) {
      t = 0.2;
    } else if (minutesLeft > 60) {
      t = 0.4;
    } else if (minutesLeft > 30) {
      t = 0.7;
    } else {
      t = 1.0;
    }

    return (minPct + (span * t)).round().clamp(0, 100);
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
