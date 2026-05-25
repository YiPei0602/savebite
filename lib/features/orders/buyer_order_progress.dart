import 'package:savebite/features/orders_payments/domain/models/order_model.dart';

/// Consumer-facing fulfilment milestones (timeline copy + mapping from [OrderStatus]).
///
/// After payment, behaviour differs for pickup vs delivery. See MODULES / product spec.
/// Merchant rejects (pending-only) reuse a shared short timeline for pickup & delivery.
class BuyerOrderProgress {
  BuyerOrderProgress._();

  static const pickupTitles = <String>[
    'Order Placed',
    'Order Accepted',
    'Preparing Order',
    'Ready for Pickup',
    'Collected',
  ];

  static const pickupMeanings = <String>[
    'Your order has been submitted.',
    'Merchant accepted your order.',
    'Your food is being prepared.',
    'Ready to collect during pickup time.',
    'Pickup complete. Enjoy your rescued food!',
  ];

  static const deliveryTitles = <String>[
    'Order Placed',
    'Order Accepted',
    'Finding Driver',
    'Preparing Order',
    'Picked Up by Driver',
    'On the Way',
    'Delivered',
  ];

  static const deliveryMeanings = <String>[
    'Your order has been submitted.',
    'Merchant accepted your order.',
    'Searching for a delivery driver.',
    'Your food is being prepared.',
    'Driver has collected your order.',
    'Driver is heading to your location.',
    'Delivered successfully.',
  ];

  /// Short timeline when the store declines before accepting (pickup & delivery).
  static const merchantRejectTitles = <String>[
    'Order placed',
    'Cancelled',
  ];

  static const merchantRejectMeanings = <String>[
    'We sent your order to the store.',
    'The store was unable to accept this order.',
  ];

  /// `true` when the store declined before accepting (distinct buyer-facing timeline).
  static bool isMerchantRejectedTimeline(OrderModel order) =>
      order.orderStatus == OrderStatus.cancelled &&
      order.cancellationReason == CancellationReason.merchantRejected;

  static bool isBuyerCancelled(OrderModel order) =>
      order.orderStatus == OrderStatus.cancelled &&
      order.cancellationReason == CancellationReason.buyerRequested;

  static List<String> labelsForFulfillment(FulfillmentType type) =>
      type == FulfillmentType.pickup ? pickupTitles : deliveryTitles;

  static List<String> meaningsForFulfillment(FulfillmentType type) =>
      type == FulfillmentType.pickup ? pickupMeanings : deliveryMeanings;

  /// Highlighted timeline step index (0-based). When [OrderStatus.completed], UI marks all steps done.
  static int stepIndex(OrderModel order) {
    if (isMerchantRejectedTimeline(order)) {
      return 1;
    }
    if (order.orderStatus == OrderStatus.cancelled) {
      return 0;
    }

    switch (order.fulfillmentType) {
      case FulfillmentType.pickup:
        return _pickupStepIndex(order.orderStatus);
      case FulfillmentType.delivery:
        return _deliveryStepIndex(order.orderStatus);
    }
  }

  static int _pickupStepIndex(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.findingDriver:
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.ready:
        return 3;
      case OrderStatus.pickedUpByDriver:
      case OrderStatus.onTheWay:
        return 3;
      case OrderStatus.completed:
        return 4;
      case OrderStatus.cancelled:
        return 0;
    }
  }

  static int _deliveryStepIndex(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.findingDriver:
        return 2;
      case OrderStatus.preparing:
        return 3;
      case OrderStatus.ready:
        return 3;
      case OrderStatus.pickedUpByDriver:
        return 4;
      case OrderStatus.onTheWay:
        return 5;
      case OrderStatus.completed:
        return 6;
      case OrderStatus.cancelled:
        return 0;
    }
  }

  /// Tracking / history hero title (badge in lists stays "Cancelled").
  static String cancellationHeroTitle(OrderModel order) {
    return 'Order cancelled';
  }

  /// One-line summary under the hero on order tracking.
  static String cancellationHeroDescription(OrderModel order) {
    if (isMerchantRejectedTimeline(order)) {
      return 'Sorry — the store couldn\'t take your order.';
    }
    if (isBuyerCancelled(order)) {
      return 'You cancelled this order.';
    }
    return 'This order is no longer active.';
  }

  /// Optional second line (refund reassurance) on tracking hero.
  static String merchantRejectRefundSubtitle(OrderModel order) {
    if (!isMerchantRejectedTimeline(order)) {
      return buyerCancelRefundSubtitle(order);
    }
    switch (order.paymentRefundStatus) {
      case PaymentRefundStatus.succeeded:
        return 'Your refund has been issued to your card.';
      case PaymentRefundStatus.pending:
      case PaymentRefundStatus.none:
        return 'Your refund is being processed and should appear on your card within a few business days.';
      case PaymentRefundStatus.failed:
        return 'We couldn\'t process your refund automatically. Please contact support with your order number.';
      case PaymentRefundStatus.notApplicable:
        return '';
    }
  }

  static String buyerCancelRefundSubtitle(OrderModel order) {
    if (!isBuyerCancelled(order)) return '';
    if (order.paymentMethod != PaymentMethod.card) return '';
    switch (order.paymentRefundStatus) {
      case PaymentRefundStatus.succeeded:
        return 'Your refund has been issued to your card.';
      case PaymentRefundStatus.pending:
      case PaymentRefundStatus.none:
        return 'Any refund will appear on your card within a few business days.';
      case PaymentRefundStatus.failed:
        return 'Refund issue — contact support with your order number.';
      case PaymentRefundStatus.notApplicable:
        return '';
    }
  }

  /// Subtitle on order history cards (badge still "Cancelled").
  static String? cancellationHistorySubtitle(OrderModel order) {
    if (order.orderStatus != OrderStatus.cancelled) return null;
    if (isMerchantRejectedTimeline(order)) {
      return 'Cancelled by the store';
    }
    if (isBuyerCancelled(order)) {
      return 'Cancelled by you';
    }
    return null;
  }

  /// Extra line in order history detail sheet for cancelled orders.
  static String? cancellationHistoryDetailNote(OrderModel order) {
    if (order.orderStatus != OrderStatus.cancelled) return null;
    final refund = merchantRejectRefundSubtitle(order);
    if (refund.isNotEmpty) return refund;
    final buyerRefund = buyerCancelRefundSubtitle(order);
    if (buyerRefund.isNotEmpty) return buyerRefund;
    if (isMerchantRejectedTimeline(order)) {
      return 'You were not charged for this order, or a refund will be issued if payment already went through.';
    }
    return null;
  }

  /// In-app toast when status becomes cancelled while user is on tracking.
  static String cancellationSnackBarMessage(OrderModel order) {
    if (isMerchantRejectedTimeline(order)) {
      return 'The store cancelled your order';
    }
    if (isBuyerCancelled(order)) {
      return 'Order cancelled';
    }
    return 'Order cancelled';
  }
}
