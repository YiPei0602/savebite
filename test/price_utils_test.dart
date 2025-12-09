import 'package:flutter_test/flutter_test.dart';
import 'package:savebite/utils/price_utils.dart';

void main() {
  group('PriceUtils', () {
    test('computeDynamicDiscount returns minPercent when far from closing', () {
      final closingTime = DateTime.now().add(const Duration(hours: 8));
      final discount = PriceUtils.computeDynamicDiscount(
        minPercent: 30,
        maxPercent: 70,
        closingTime: closingTime,
        totalWindowHours: 8.0,
      );
      
      // Should be close to minPercent (30) when 8 hours remain
      expect(discount, greaterThanOrEqualTo(30));
      expect(discount, lessThanOrEqualTo(35));
    });

    test('computeDynamicDiscount returns maxPercent when near closing', () {
      final closingTime = DateTime.now().add(const Duration(minutes: 15));
      final discount = PriceUtils.computeDynamicDiscount(
        minPercent: 30,
        maxPercent: 70,
        closingTime: closingTime,
        totalWindowHours: 8.0,
      );
      
      // Should be close to maxPercent (70) when only 15 minutes remain
      expect(discount, greaterThanOrEqualTo(65));
      expect(discount, lessThanOrEqualTo(70));
    });

    test('computeDynamicDiscount returns maxPercent when already closed', () {
      final closingTime = DateTime.now().subtract(const Duration(hours: 1));
      final discount = PriceUtils.computeDynamicDiscount(
        minPercent: 30,
        maxPercent: 70,
        closingTime: closingTime,
      );
      
      expect(discount, equals(70));
    });

    test('computeDynamicDiscount returns mid-range when halfway to closing', () {
      final closingTime = DateTime.now().add(const Duration(hours: 4));
      final discount = PriceUtils.computeDynamicDiscount(
        minPercent: 30,
        maxPercent: 70,
        closingTime: closingTime,
        totalWindowHours: 8.0,
      );
      
      // Should be around 50% when halfway through window
      expect(discount, greaterThanOrEqualTo(45));
      expect(discount, lessThanOrEqualTo(55));
    });

    test('computeDiscountedPrice calculates correctly', () {
      final discountedPrice = PriceUtils.computeDiscountedPrice(
        originalPrice: 100.0,
        discountPercent: 50,
      );
      
      expect(discountedPrice, equals(50.0));
    });

    test('computeDiscountedPrice rounds to 2 decimal places', () {
      final discountedPrice = PriceUtils.computeDiscountedPrice(
        originalPrice: 33.33,
        discountPercent: 33,
      );
      
      expect(discountedPrice, equals(22.33));
    });

    test('isClosingSoon returns true when within threshold', () {
      final closingTime = DateTime.now().add(const Duration(minutes: 20));
      final result = PriceUtils.isClosingSoon(
        closingTime: closingTime,
        thresholdMinutes: 30,
      );
      
      expect(result, isTrue);
    });

    test('isClosingSoon returns false when beyond threshold', () {
      final closingTime = DateTime.now().add(const Duration(hours: 2));
      final result = PriceUtils.isClosingSoon(
        closingTime: closingTime,
        thresholdMinutes: 30,
      );
      
      expect(result, isFalse);
    });

    test('isClosingSoon returns false when already closed', () {
      final closingTime = DateTime.now().subtract(const Duration(minutes: 10));
      final result = PriceUtils.isClosingSoon(
        closingTime: closingTime,
        thresholdMinutes: 30,
      );
      
      expect(result, isFalse);
    });

    test('formatTimeRemaining formats hours and minutes correctly', () {
      final closingTime = DateTime.now().add(const Duration(hours: 2, minutes: 30));
      final formatted = PriceUtils.formatTimeRemaining(closingTime);
      
      // Allow for 1 minute tolerance due to test execution time
      expect(formatted, anyOf(equals('2h 30m'), equals('2h 29m')));
    });

    test('formatTimeRemaining formats minutes only when less than 1 hour', () {
      final closingTime = DateTime.now().add(const Duration(minutes: 45));
      final formatted = PriceUtils.formatTimeRemaining(closingTime);
      
      // Allow for 1 minute tolerance due to test execution time
      expect(formatted, anyOf(equals('45m'), equals('44m')));
    });

    test('formatTimeRemaining returns "Closed" when time has passed', () {
      final closingTime = DateTime.now().subtract(const Duration(hours: 1));
      final formatted = PriceUtils.formatTimeRemaining(closingTime);
      
      expect(formatted, equals('Closed'));
    });
  });
}
