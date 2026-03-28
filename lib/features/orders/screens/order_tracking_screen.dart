import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../marketplace_surplus/domain/models/merchant_model.dart';
import '../../marketplace_surplus/state/providers/merchant_provider.dart';
import '../../orders_payments/state/providers/order_provider.dart';
import '../../orders_payments/domain/models/order_model.dart';
import '../../../shared/utils/merchant_display_name_utils.dart';
import '../../../shared/widgets/app_back_button.dart';

/// Consumer-facing order tracking: live Firestore stream + status-driven UI.
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final String? merchantName;
  final String? merchantAddress;
  final bool? isPickup;
  final double? totalAmount;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.merchantName,
    this.merchantAddress,
    this.isPickup,
    this.totalAmount,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Stream<OrderModel?>? _orderStream;
  bool _demoAutoProgressStarted = false;
  bool _demoAutoProgressStopped = false;
  GoogleMapController? _mapController;
  String? _lastFittedMapKey;

  static final bool _demoAutoProgressEnabled =
      kDebugMode &&
      const bool.fromEnvironment(
        'DEMO_AUTO_PROGRESS_ORDERS',
        defaultValue: true,
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orderStream ??=
        context.read<OrderProvider>().watchOrderById(widget.orderId);
  }

  @override
  void dispose() {
    _demoAutoProgressStopped = true;
    super.dispose();
  }

  void _maybeStartDemoAutoProgression(OrderModel order) {
    if (!_demoAutoProgressEnabled) return;
    if (_demoAutoProgressStarted) return;
    if (order.orderStatus == OrderStatus.completed ||
        order.orderStatus == OrderStatus.cancelled) {
      return;
    }

    _demoAutoProgressStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _demoAutoProgressStopped) return;
      _runDemoAutoProgression();
    });
  }

  static OrderStatus? _nextStatusInDemoFlow({
    required FulfillmentType fulfillmentType,
    required OrderStatus current,
  }) {
    final flow = fulfillmentType == FulfillmentType.delivery
        ? const <OrderStatus>[
            OrderStatus.pending,
            OrderStatus.confirmed,
            OrderStatus.preparing,
            OrderStatus.ready,
            OrderStatus.onTheWay,
            OrderStatus.completed,
          ]
        : const <OrderStatus>[
            OrderStatus.pending,
            OrderStatus.confirmed,
            OrderStatus.preparing,
            OrderStatus.ready,
            OrderStatus.completed,
          ];

    final i = flow.indexOf(current);
    if (i < 0) return null;
    if (i >= flow.length - 1) return null;
    return flow[i + 1];
  }

  static Duration _demoDelay({
    required FulfillmentType fulfillmentType,
    required OrderStatus current,
    required OrderStatus next,
    required Random rng,
  }) {
    // Pickup: pending → confirmed (2s) → preparing (3s) → ready (5s) → completed (2s).
    // Delivery: same, plus ready → onTheWay (2s), onTheWay → completed (6–8s).
    if (fulfillmentType == FulfillmentType.delivery &&
        current == OrderStatus.onTheWay &&
        next == OrderStatus.completed) {
      final seconds = 6 + rng.nextInt(3); // 6, 7, 8
      return Duration(seconds: seconds);
    }
    if (current == OrderStatus.pending && next == OrderStatus.confirmed) {
      return const Duration(seconds: 2);
    }
    if (current == OrderStatus.confirmed && next == OrderStatus.preparing) {
      return const Duration(seconds: 3);
    }
    if (current == OrderStatus.preparing && next == OrderStatus.ready) {
      return const Duration(seconds: 5);
    }
    if (current == OrderStatus.ready && next == OrderStatus.onTheWay) {
      return const Duration(seconds: 2);
    }
    if (current == OrderStatus.ready && next == OrderStatus.completed) {
      return const Duration(seconds: 2);
    }
    // Default small delay to avoid tight loops if flow changes.
    return const Duration(seconds: 1);
  }

  Future<void> _runDemoAutoProgression() async {
    final rng = Random();
    final orderProvider = context.read<OrderProvider>();

    while (mounted && !_demoAutoProgressStopped) {
      final current = await orderProvider
          .watchOrderById(widget.orderId)
          .firstWhere((o) => o != null);
      if (!mounted || _demoAutoProgressStopped) return;
      final order = current!;

      if (order.orderStatus == OrderStatus.completed ||
          order.orderStatus == OrderStatus.cancelled) {
        return;
      }

      final next = _nextStatusInDemoFlow(
        fulfillmentType: order.fulfillmentType,
        current: order.orderStatus,
      );
      if (next == null) return;

      final delay = _demoDelay(
        fulfillmentType: order.fulfillmentType,
        current: order.orderStatus,
        next: next,
        rng: rng,
      );
      await Future.delayed(delay);
      if (!mounted || _demoAutoProgressStopped) return;

      final ok = await orderProvider.updateOrderStatus(widget.orderId, next);
      if (!ok) {
        return;
      }
    }
  }

  bool _shouldShowDeliveryMap(OrderModel order) {
    if (order.fulfillmentType != FulfillmentType.delivery) return false;
    if (order.orderStatus != OrderStatus.onTheWay) return false;
    return order.merchantLatitude != null &&
        order.merchantLongitude != null &&
        order.deliveryLatitude != null &&
        order.deliveryLongitude != null;
  }

  LatLngBounds _boundsFor(LatLng a, LatLng b) {
    final south = min(a.latitude, b.latitude);
    final north = max(a.latitude, b.latitude);
    final west = min(a.longitude, b.longitude);
    final east = max(a.longitude, b.longitude);
    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  Future<void> _fitMapToMarkers({
    required GoogleMapController controller,
    required LatLng merchant,
    required LatLng delivery,
    required String fitKey,
  }) async {
    if (_lastFittedMapKey == fitKey) return;
    _lastFittedMapKey = fitKey;

    final bounds = _boundsFor(merchant, delivery);
    try {
      // Delay slightly to allow the platform view to size itself.
      await Future.delayed(const Duration(milliseconds: 120));
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 56));
    } catch (_) {
      // If bounds animation fails (rare on first frame), fall back to centered zoom.
      final center = LatLng(
        (merchant.latitude + delivery.latitude) / 2.0,
        (merchant.longitude + delivery.longitude) / 2.0,
      );
      await controller.moveCamera(CameraUpdate.newLatLngZoom(center, 13.5));
    }
  }

  Widget _buildDeliveryMap(OrderModel order) {
    final merchant = LatLng(order.merchantLatitude!, order.merchantLongitude!);
    final delivery = LatLng(order.deliveryLatitude!, order.deliveryLongitude!);

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('merchant'),
        position: merchant,
        infoWindow: const InfoWindow(title: 'Merchant'),
      ),
      Marker(
        markerId: const MarkerId('delivery'),
        position: delivery,
        infoWindow: const InfoWindow(title: 'Delivery'),
      ),
    };

    final center = LatLng(
      (merchant.latitude + delivery.latitude) / 2.0,
      (merchant.longitude + delivery.longitude) / 2.0,
    );

    final fitKey =
        '${order.id}:${order.orderStatus.name}:${merchant.latitude},${merchant.longitude}:${delivery.latitude},${delivery.longitude}';

    // If we already have a controller (map rebuilt), refit once per key.
    final controller = _mapController;
    if (controller != null && _lastFittedMapKey != fitKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fitMapToMarkers(
          controller: controller,
          merchant: merchant,
          delivery: delivery,
          fitKey: fitKey,
        );
      });
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: SizedBox(
        height: 250,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: center, zoom: 13.5),
          markers: markers,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: (c) {
            _mapController = c;
            _fitMapToMarkers(
              controller: c,
              merchant: merchant,
              delivery: delivery,
              fitKey: fitKey,
            );
          },
        ),
      ),
    );
  }

  String _resolveMerchantName(OrderModel order) {
    try {
      final mp = context.read<MerchantProvider>();
      MerchantModel? m;
      for (final x in mp.merchants) {
        if (x.id == order.merchantId) {
          m = x;
          break;
        }
      }
      return consumerShopDisplayName(
        merchantId: order.merchantId,
        merchantProfile: m,
        fromFoodItem: order.merchantName,
      );
    } catch (_) {
      return order.merchantName;
    }
  }

  String _resolveAddress(OrderModel order) {
    if (order.fulfillmentType == FulfillmentType.delivery) {
      return order.deliveryAddress?.trim().isNotEmpty == true
          ? order.deliveryAddress!.trim()
          : '';
    }
    return order.pickupAddress?.trim().isNotEmpty == true
        ? order.pickupAddress!.trim()
        : '';
  }

  void _contactMerchant(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Merchant', style: AppTypography.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _resolveMerchantName(order),
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            _buildContactOption(Icons.phone, 'Call', '+60 12-345 6789'),
            const SizedBox(height: AppConstants.paddingS),
            _buildContactOption(Icons.message, 'Message', 'Send a message'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: AppTypography.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(IconData icon, String label, String value) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label: $value')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.bodyMedium),
                  Text(
                    value,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelOrder() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order?', style: AppTypography.h4),
        content: Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Order', style: AppTypography.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final orderProvider = context.read<OrderProvider>();
              Navigator.pop(context);
              final ok = await orderProvider.cancelOrder(widget.orderId);
              if (!mounted) return;
              if (ok) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Order cancelled'),
                    backgroundColor: AppColors.error,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      orderProvider.errorMessage ?? 'Could not cancel order',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Cancel Order', style: AppTypography.buttonMedium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: Text('Order Tracking', style: AppTypography.h3),
      centerTitle: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: const AppBackButton(color: AppColors.textPrimary),
    );

    final stream = _orderStream;
    if (stream == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: appBar,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return StreamBuilder<OrderModel?>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: appBar,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: appBar,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Text(
                  'Unable to load order: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
              ),
            ),
          );
        }

        final order = snapshot.data;
        if (order == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: appBar,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Text(
                  'Order not found',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
              ),
            ),
          );
        }

        _maybeStartDemoAutoProgression(order);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: appBar,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_shouldShowDeliveryMap(order)) ...[
                  _buildDeliveryMap(order),
                  const SizedBox(height: AppConstants.paddingL),
                ],
                _buildStatusHeroCard(order),
                const SizedBox(height: AppConstants.paddingL),
                if (order.orderStatus != OrderStatus.cancelled) ...[
                  _buildProgressCard(order),
                  const SizedBox(height: AppConstants.paddingL),
                ],
                _buildLocationCard(order),
                const SizedBox(height: AppConstants.paddingL),
                _buildActionButtons(order),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusHeroCard(OrderModel order) {
    final s = order.orderStatus;
    final title = _statusTitle(s, order.fulfillmentType);
    final description = _statusDescription(s, order.fulfillmentType);
    final style = _statusStyle(s, order.fulfillmentType);
    final etaLine = _deliveryEtaLine(order);

    final id = order.id.isNotEmpty ? order.id : widget.orderId;
    final shortId = id.length <= 6 ? id : id.substring(id.length - 6);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.border.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: style.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              style.icon,
              color: style.color,
              size: 32,
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (etaLine != null) ...[
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    etaLine,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppConstants.paddingS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingS,
              vertical: AppConstants.paddingXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Text(
              '#$shortId',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Delivery-only ETA/distance line.
  ///
  /// - If `onTheWay`: compute driver → delivery (fallback to merchant if driver missing).
  /// - Else: compute merchant → delivery.
  /// - Pickup orders: no ETA/distance.
  String? _deliveryEtaLine(OrderModel order) {
    if (order.fulfillmentType != FulfillmentType.delivery) return null;
    if (order.orderStatus == OrderStatus.cancelled ||
        order.orderStatus == OrderStatus.completed) {
      return null;
    }
    if (order.orderStatus == OrderStatus.pending) return null;

    final dl = order.deliveryLatitude;
    final dlg = order.deliveryLongitude;
    if (dl == null || dlg == null) return null;

    double? fromLat;
    double? fromLng;
    if (order.orderStatus == OrderStatus.onTheWay) {
      fromLat = order.driverLatitude ?? order.merchantLatitude;
      fromLng = order.driverLongitude ?? order.merchantLongitude;
    } else {
      fromLat = order.merchantLatitude;
      fromLng = order.merchantLongitude;
    }
    if (fromLat == null || fromLng == null) return null;

    final meters = Geolocator.distanceBetween(fromLat, fromLng, dl, dlg);
    final km = meters / 1000.0;
    // Heuristic speed: 30 km/h.
    const speedKmh = 30.0;
    final mins = (km / speedKmh * 60.0).ceil().clamp(1, 9999);
    final kmText = km < 0.05 ? '0.1' : km.toStringAsFixed(1);
    return 'Arriving in $mins mins • $kmText km';
  }

  Widget _buildProgressCard(OrderModel order) {
    final labels = _progressLabels(order.fulfillmentType);
    final currentIndex = _progressIndex(order);
    final currentColor = _statusStyle(order.orderStatus, order.fulfillmentType).color;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.border.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progress', style: AppTypography.h5),
          const SizedBox(height: AppConstants.paddingM),
          for (int i = 0; i < labels.length; i++)
            _buildTimelineRow(
              label: labels[i],
              isDone: order.orderStatus == OrderStatus.completed
                  ? true
                  : i < currentIndex,
              isCurrent: order.orderStatus == OrderStatus.completed
                  ? i == labels.length - 1
                  : i == currentIndex,
              isLast: i == labels.length - 1,
              currentColor: currentColor,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow({
    required String label,
    required bool isDone,
    required bool isCurrent,
    required bool isLast,
    required Color currentColor,
  }) {
    final Color dotColor = isDone
        ? AppColors.success
        : isCurrent
            ? currentColor
            : AppColors.divider;
    final Widget dot = isDone
        ? const Icon(Icons.check_circle, size: 22, color: AppColors.success)
        : Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent ? dotColor : Colors.transparent,
              border: Border.all(
                color: isCurrent ? dotColor : AppColors.divider,
                width: 2.5,
              ),
            ),
          );

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppConstants.paddingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                dot,
                if (!isLast) ...[
                  const SizedBox(height: 4),
                  _timelineConnector(isDone: isDone),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: isDone || isCurrent
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineConnector({required bool isDone}) {
    if (isDone) {
      return Container(
        width: 3,
        height: 24,
        color: AppColors.success,
      );
    }
    return Column(
      children: [
        for (int i = 0; i < 5; i++)
          Container(
            width: 3,
            height: 4,
            margin: const EdgeInsets.only(bottom: 3),
            color: AppColors.divider,
          ),
      ],
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    final status = order.orderStatus;
    final canCancel =
        status == OrderStatus.pending || status == OrderStatus.confirmed;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed:
                status != OrderStatus.cancelled ? () => _contactMerchant(order) : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, size: 20),
                const SizedBox(width: AppConstants.paddingS),
                Text(
                  'Contact Merchant',
                  style: AppTypography.buttonMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingS),
        if (canCancel)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cancelOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.paddingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
              child: Text(
                'Cancel Order',
                style: AppTypography.buttonMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<String> _progressLabels(FulfillmentType type) {
    if (type == FulfillmentType.pickup) {
      return const <String>[
        'Order placed',
        'Preparing',
        'Ready',
        'Completed',
      ];
    }
    return const <String>[
      'Order placed',
      'Preparing',
      'On the way',
      'Completed',
    ];
  }

  int _progressIndex(OrderModel order) {
    final s = order.orderStatus;
    final type = order.fulfillmentType;
    if (s == OrderStatus.completed) return 3;
    if (type == FulfillmentType.pickup) {
      if (s == OrderStatus.ready) return 2;
      if (s == OrderStatus.preparing) return 1;
      // pending / confirmed
      return 0;
    }
    // delivery
    if (s == OrderStatus.onTheWay) return 2;
    if (s == OrderStatus.preparing || s == OrderStatus.ready) return 1;
    // pending / confirmed
    return 0;
  }

  Widget _buildLocationCard(OrderModel order) {
    final isPickup = order.fulfillmentType == FulfillmentType.pickup;
    final title = isPickup ? 'Pickup at ${_resolveMerchantName(order)}' : 'Deliver to';
    final address = _resolveAddress(order);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.border.withOpacity(0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPickup ? Icons.storefront_outlined : Icons.location_on_outlined,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address.isEmpty ? '—' : address,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _statusTitle(OrderStatus s, FulfillmentType type) {
  switch (s) {
    case OrderStatus.pending:
      return 'Waiting for merchant';
    case OrderStatus.confirmed:
      return 'Order accepted';
    case OrderStatus.preparing:
      return 'Preparing your food';
    case OrderStatus.ready:
      return type == FulfillmentType.pickup ? 'Ready for pickup' : 'Ready';
    case OrderStatus.onTheWay:
      return 'Out for delivery';
    case OrderStatus.completed:
      return 'Completed';
    case OrderStatus.cancelled:
      return 'Cancelled';
  }
}

String _statusDescription(OrderStatus s, FulfillmentType type) {
  switch (s) {
    case OrderStatus.pending:
      return 'Waiting for the store to accept your order.';
    case OrderStatus.confirmed:
      return 'The store has accepted your order.';
    case OrderStatus.preparing:
      return 'Your order is being prepared.';
    case OrderStatus.ready:
      return type == FulfillmentType.pickup
          ? 'Your order is ready for pickup.'
          : 'Your order is ready.';
    case OrderStatus.onTheWay:
      return 'Your order is on the way to you.';
    case OrderStatus.completed:
      return 'Thank you for your order.';
    case OrderStatus.cancelled:
      return 'This order has been cancelled.';
  }
}

({Color color, IconData icon}) _statusStyle(OrderStatus s, FulfillmentType type) {
  switch (s) {
    case OrderStatus.completed:
      return (color: AppColors.success, icon: Icons.done_all);
    case OrderStatus.cancelled:
      return (color: AppColors.error, icon: Icons.cancel);
    case OrderStatus.ready:
      return type == FulfillmentType.pickup
          ? (color: AppColors.primary, icon: Icons.storefront_outlined)
          : (color: AppColors.primary, icon: Icons.inventory_2_outlined);
    case OrderStatus.onTheWay:
      return (color: AppColors.primary, icon: Icons.local_shipping_outlined);
    case OrderStatus.preparing:
      return (color: const Color(0xFFF97316), icon: Icons.restaurant);
    case OrderStatus.confirmed:
      return (color: const Color(0xFF2563EB), icon: Icons.check_circle_outline);
    case OrderStatus.pending:
      return (color: AppColors.warning, icon: Icons.schedule);
  }
}
