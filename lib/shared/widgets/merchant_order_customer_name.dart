import 'package:flutter/material.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';
import 'package:savebite/shared/utils/order_customer_name_utils.dart';

/// Customer name on merchant order UI (`firstName` + `lastName`).
class MerchantOrderCustomerName extends StatelessWidget {
  const MerchantOrderCustomerName({
    super.key,
    required this.order,
    required this.style,
    this.maxLines = 1,
    this.prefixWithCustomerLabel = true,
  });

  final OrderModel order;
  final TextStyle style;
  final int maxLines;
  /// When false, shows name only (for detail rows that already have a label).
  final bool prefixWithCustomerLabel;

  String _formatDisplay(String name) {
    return prefixWithCustomerLabel
        ? formatMerchantCustomerLine(name)
        : plainMerchantCustomerName(name);
  }

  @override
  Widget build(BuildContext context) {
    final stored = order.customerName?.trim();
    if (stored != null && stored.isNotEmpty) {
      return Text(
        _formatDisplay(stored),
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    return FutureBuilder<String>(
      future: resolveMerchantCustomerLabel(order),
      builder: (context, snapshot) {
        return Text(
          _formatDisplay(snapshot.data ?? 'Customer'),
          style: style,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
