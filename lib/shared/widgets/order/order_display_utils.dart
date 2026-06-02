import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';

String formatOrderDateTime(DateTime dateTime) {
  return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
}

String formatOrderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.completed:
      return 'Completed';
    case OrderStatus.cancelled:
      return 'Cancelled';
    case OrderStatus.pending:
      return 'Pending';
    case OrderStatus.confirmed:
      return 'Confirmed';
    case OrderStatus.findingDriver:
      return 'Finding driver';
    case OrderStatus.preparing:
      return 'Preparing';
    case OrderStatus.ready:
      return 'Ready';
    case OrderStatus.pickedUpByDriver:
      return 'Driver picked up';
    case OrderStatus.onTheWay:
      return 'On the way';
  }
}

Color orderStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return const Color(0xFF6B7280);
    case OrderStatus.confirmed:
      return const Color(0xFF2563EB);
    case OrderStatus.findingDriver:
      return const Color(0xFF7C3AED);
    case OrderStatus.preparing:
      return const Color(0xFFF97316);
    case OrderStatus.ready:
      return const Color(0xFF7C3AED);
    case OrderStatus.pickedUpByDriver:
      return const Color(0xFF0891B2);
    case OrderStatus.completed:
      return const Color(0xFF16A34A);
    case OrderStatus.cancelled:
      return const Color(0xFFDC2626);
    case OrderStatus.onTheWay:
      return AppColors.accent;
  }
}

String fulfillmentTypeLabel(FulfillmentType type) {
  return type == FulfillmentType.pickup ? 'Pickup' : 'Delivery';
}

String fulfillmentTypeDetailLabel(FulfillmentType type) {
  return type == FulfillmentType.pickup ? 'Self-Pickup' : 'Delivery';
}

String paymentMethodLabel(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.card:
      return 'Card';
    case PaymentMethod.ewallet:
      return 'E-Wallet';
    case PaymentMethod.onlineBanking:
      return 'Online banking';
    case PaymentMethod.cash:
      return 'Cash';
  }
}
