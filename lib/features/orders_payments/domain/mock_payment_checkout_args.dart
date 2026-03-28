import 'package:savebite/features/orders_payments/domain/models/cart_item_model.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';

/// Carries checkout state from [CheckoutScreen] → [MockPaymentScreen] → order creation.
class MockPaymentCheckoutArgs {
  const MockPaymentCheckoutArgs({
    required this.userId,
    required this.merchantId,
    required this.merchantName,
    required this.items,
    required this.subtotal,
    required this.serviceFee,
    required this.deliveryFee,
    required this.totalPrice,
    required this.totalSavings,
    required this.fulfillmentType,
    required this.paymentMethod,
    required this.paymentMethodLabelKey,
    required this.isSelfPickup,
    required this.cartItemsForTracking,
    this.deliveryAddress,
    this.pickupAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryPlaceId,
  });

  final String userId;
  final String merchantId;
  final String merchantName;
  final List<CartItemModel> items;
  final double subtotal;
  final double serviceFee;
  final double deliveryFee;
  final double totalPrice;
  final double totalSavings;
  final FulfillmentType fulfillmentType;
  final PaymentMethod paymentMethod;
  /// [CheckoutPaymentMethodKey] value for display / legacy tracking fields.
  final String paymentMethodLabelKey;
  final bool isSelfPickup;
  final Map<String, Map<String, dynamic>> cartItemsForTracking;
  final String? deliveryAddress;
  final String? pickupAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? deliveryPlaceId;
}
