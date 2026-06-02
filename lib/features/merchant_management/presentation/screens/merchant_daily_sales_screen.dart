import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';
import 'package:savebite/features/orders_payments/state/providers/order_provider.dart';
import 'package:timezone/timezone.dart' as tz;

class MerchantDailySalesScreen extends StatefulWidget {
  const MerchantDailySalesScreen({super.key});

  @override
  State<MerchantDailySalesScreen> createState() =>
      _MerchantDailySalesScreenState();
}

class _MerchantDailySalesScreenState extends State<MerchantDailySalesScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final loc = tz.getLocation('Asia/Kuala_Lumpur');
    final now = tz.TZDateTime.now(loc);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  void _moveDay(int offset) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offset));
    });
  }

  bool _isToday(DateTime date) {
    final loc = tz.getLocation('Asia/Kuala_Lumpur');
    final now = tz.TZDateTime.now(loc);
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  ({List<OrderModel> orders, double revenue}) _dailySalesFromOrders(
    List<OrderModel> orders,
    DateTime selectedDate,
  ) {
    final loc = tz.getLocation('Asia/Kuala_Lumpur');
    final dayStart = tz.TZDateTime(
      loc,
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));

    final completedPaidForDay = orders.where((o) {
      if (o.orderStatus != OrderStatus.completed) return false;
      if (o.paymentStatus != PaymentStatus.paid) return false;
      final completedAt = o.completedAt;
      if (completedAt == null) return false;
      final c = tz.TZDateTime.from(completedAt, loc);
      return !c.isBefore(dayStart) && c.isBefore(dayEnd);
    }).toList(growable: false)
      ..sort((a, b) {
        final aTime = a.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    final revenue = completedPaidForDay.fold<double>(
      0.0,
      (sum, order) => sum + order.subtotal,
    );

    return (orders: completedPaidForDay, revenue: revenue);
  }

  String _formatYmd(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  String _formatTime(DateTime dateTime) {
    final loc = tz.getLocation('Asia/Kuala_Lumpur');
    final local = tz.TZDateTime.from(dateTime, loc);
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final merchantId = user?.merchantId ?? user?.id;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Daily Sales Summary',
          style: AppTypography.h3,
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: merchantId == null || merchantId.isEmpty
          ? Center(
              child: Text(
                'Merchant profile is not ready yet.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : StreamBuilder<List<OrderModel>>(
              stream:
                  context.read<OrderProvider>().watchMerchantOrders(merchantId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !(snapshot.hasData && snapshot.data!.isNotEmpty)) {
                  return const Center(child: CircularProgressIndicator());
                }

                final daily = _dailySalesFromOrders(
                  snapshot.data ?? const <OrderModel>[],
                  _selectedDate,
                );
                final sales = daily.orders;
                final revenue = daily.revenue;
                final completedCount = sales.length;
                final avgOrder =
                    completedCount == 0 ? 0.0 : revenue / completedCount;

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {},
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppConstants.paddingL),
                    children: [
                      _buildDateSelector(),
                      const SizedBox(height: AppConstants.paddingM),
                      _buildKpiRow(
                        completedCount: completedCount,
                        revenue: revenue,
                        avgOrder: avgOrder,
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                      Text(
                        'Completed orders ($completedCount)',
                        style: AppTypography.h5,
                      ),
                      const SizedBox(height: AppConstants.paddingS),
                      if (sales.isEmpty)
                        _buildEmptyState()
                      else
                        ...sales.map(_buildOrderCard),
                      const SizedBox(height: AppConstants.paddingM),
                      Text(
                        'Last updated: live',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _moveDay(-1),
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous day',
          ),
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingS,
                  vertical: AppConstants.paddingXS,
                ),
                child: Column(
                  children: [
                    Text(_formatYmd(_selectedDate), style: AppTypography.h5),
                    const SizedBox(height: 2),
                    Text(
                      _isToday(_selectedDate) ? 'Today' : 'Tap to change date',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _moveDay(1),
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next day',
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow({
    required int completedCount,
    required double revenue,
    required double avgOrder,
  }) {
    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            icon: Icons.check_circle_outline,
            title: 'Completed',
            value: '$completedCount',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpiCard(
            icon: Icons.payments_outlined,
            title: 'Revenue',
            value:
                '${AppConstants.currencySymbol} ${revenue.toStringAsFixed(2)}',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpiCard(
            icon: Icons.bar_chart_outlined,
            title: 'Avg order',
            value:
                '${AppConstants.currencySymbol} ${avgOrder.toStringAsFixed(2)}',
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style:
                AppTypography.caption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final completedAt = order.completedAt;
    final completedAtLabel =
        completedAt == null ? '-' : _formatTime(completedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.fulfillmentType.name.toUpperCase()} • $completedAtLabel',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${AppConstants.currencySymbol} ${order.subtotal.toStringAsFixed(2)}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 36,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            'No completed sales for this day',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Completed + paid orders will appear here automatically.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
