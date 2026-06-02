import 'package:flutter/material.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';
import 'package:savebite/shared/widgets/order/order_details_sheet.dart';

/// Opens shared order details for merchant (accept/reject + status actions inside).
Future<void> openMerchantOrderDetail(
  BuildContext context, {
  required OrderModel order,
}) {
  return showOrderDetailsSheet(
    context,
    order: order,
    audience: OrderDetailsAudience.merchant,
  );
}
