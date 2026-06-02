import 'package:flutter/material.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/orders_payments/domain/models/cart_item_model.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';
import 'package:savebite/shared/widgets/merchant_order_customer_name.dart';
import 'package:savebite/shared/widgets/order/order_display_utils.dart';

enum OrderSummaryAudience { consumer, merchant }

/// Compact order row used on consumer and merchant order lists.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.order,
    required this.audience,
    required this.onTap,
    this.storeName,
    this.highlightPending = false,
    this.cancelSubtitle,
  });

  final OrderModel order;
  final OrderSummaryAudience audience;
  final VoidCallback onTap;
  final String? storeName;
  final bool highlightPending;
  final String? cancelSubtitle;

  @override
  Widget build(BuildContext context) {
    final statusLabel = formatOrderStatusLabel(order.orderStatus);
    final statusColor = orderStatusColor(order.orderStatus);
    final borderColor = highlightPending
        ? AppColors.warning.withOpacity(0.45)
        : AppColors.border.withOpacity(0.6);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (highlightPending) ...[
                    Icon(Icons.notifications_active_outlined,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _OrderCardTitle(orderId: order.id),
                        if (highlightPending) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Awaiting acceptance',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _FulfillmentPill(type: order.fulfillmentType),
                      const SizedBox(height: 6),
                      _StatusBadge(label: statusLabel, color: statusColor),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatOrderDateTime(order.createdAt),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              if (audience == OrderSummaryAudience.merchant)
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: MerchantOrderCustomerName(
                        order: order,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                )
              else if ((storeName ?? '').isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.store_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Store: $storeName',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (cancelSubtitle != null && cancelSubtitle!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  cancelSubtitle!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Items',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              _ItemsPreview(items: order.items),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: AppTypography.h5.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${AppConstants.currencySymbol}${order.totalPrice.toStringAsFixed(2)}',
                    style: AppTypography.h5.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCardTitle extends StatelessWidget {
  const _OrderCardTitle({required this.orderId});

  final String orderId;

  static TextStyle get _titleSize => AppTypography.h5.copyWith(
        color: AppColors.textPrimary,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order',
          style: _titleSize.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          '#$orderId',
          style: _titleSize.copyWith(fontWeight: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _FulfillmentPill extends StatelessWidget {
  const _FulfillmentPill({required this.type});

  final FulfillmentType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        fulfillmentTypeLabel(type),
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ItemsPreview extends StatelessWidget {
  const _ItemsPreview({required this.items});

  final List<CartItemModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'No items',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    final first = items.first;
    final firstName = first.foodItem.name;
    final firstQty = first.quantity;
    final remaining = items.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                firstName,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'x$firstQty',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+$remaining more item${remaining == 1 ? '' : 's'}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
