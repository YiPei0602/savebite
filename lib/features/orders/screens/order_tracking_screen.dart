import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../marketplace_surplus/domain/models/merchant_model.dart';
import '../../marketplace_surplus/state/providers/merchant_provider.dart';
import '../../orders_payments/state/providers/order_provider.dart';
import '../../orders_payments/domain/models/order_model.dart';
import '../../../shared/utils/merchant_display_name_utils.dart';
import '../../../shared/utils/rider_contact_utils.dart';
import '../buyer_order_progress.dart';
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
  Timer? _driverSimTimer;
  String? _driverSimKey;

  bool _statusStreamInitialized = false;
  OrderStatus? _lastKnownStatus;
  bool _isConfirmingPickup = false;

  /// Cached motorbike bitmap for [MarkerId('driver')] only (shared across screens).
  static Future<BitmapDescriptor>? _driverMarkerBitmapFuture;
  BitmapDescriptor? _driverMarkerIcon;
  bool _driverMarkerKickScheduled = false;

  static final bool _demoAutoProgressEnabled =
      kDebugMode &&
      const bool.fromEnvironment(
        'DEMO_AUTO_PROGRESS_ORDERS',
        defaultValue: false,
      );

  static final bool _demoDriverSimEnabled =
      kDebugMode &&
      const bool.fromEnvironment(
        'DEMO_DRIVER_SIMULATION',
        defaultValue: false,
      );

  static const String _driverMarkerAssetPath = 'assets/images/deliveryrider.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDriverMarkerBitmap());
  }

  Future<void> _ensureDriverMarkerBitmap() async {
    if (_driverMarkerIcon != null || !mounted) return;
    _driverMarkerBitmapFuture ??= _decodeDriverMarkerBitmapDescriptor();
    try {
      final icon = await _driverMarkerBitmapFuture!;
      if (!mounted) return;
      setState(() => _driverMarkerIcon = icon);
    } catch (e, st) {
      debugPrint('Driver marker bitmap: $e\n$st');
      _driverMarkerBitmapFuture = null;
    }
  }

  /// Decode PNG from Flutter assets and build a platform bitmap (more reliable
  /// on iOS than [BitmapDescriptor.fromAssetImage] for some PNGs / DPI pairs).
  static Future<BitmapDescriptor> _decodeDriverMarkerBitmapDescriptor() async {
    final data = await rootBundle.load(_driverMarkerAssetPath);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 128);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final pngBytes =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (pngBytes == null) {
        throw StateError('driver marker: could not encode PNG');
      }
      return BitmapDescriptor.fromBytes(pngBytes.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orderStream ??=
        context.read<OrderProvider>().watchOrderById(widget.orderId);
  }

  @override
  void dispose() {
    _demoAutoProgressStopped = true;
    _driverSimTimer?.cancel();
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

  void _syncDriverSimulation(OrderModel order) {
    if (!_demoDriverSimEnabled) {
      _driverSimTimer?.cancel();
      _driverSimTimer = null;
      _driverSimKey = null;
      return;
    }

    final shouldRun = order.fulfillmentType == FulfillmentType.delivery &&
        order.orderStatus == OrderStatus.onTheWay &&
        order.merchantLatitude != null &&
        order.merchantLongitude != null &&
        order.deliveryLatitude != null &&
        order.deliveryLongitude != null;

    if (!shouldRun) {
      _driverSimTimer?.cancel();
      _driverSimTimer = null;
      _driverSimKey = null;
      return;
    }

    final key =
        '${order.id}:${order.orderStatus.name}:${order.merchantLatitude},${order.merchantLongitude}:${order.deliveryLatitude},${order.deliveryLongitude}';
    if (_driverSimTimer != null && _driverSimKey == key) {
      return;
    }
    _driverSimTimer?.cancel();
    _driverSimTimer = null;
    _driverSimKey = key;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startDriverSimulationTick(order);
    });
  }

  void _startDriverSimulationTick(OrderModel initial) {
    _driverSimTimer?.cancel();
    final orderProvider = context.read<OrderProvider>();

    final merchantLat = initial.merchantLatitude!;
    final merchantLng = initial.merchantLongitude!;
    final destLat = initial.deliveryLatitude!;
    final destLng = initial.deliveryLongitude!;

    // Initialize driver location at merchant if missing.
    final initLat = initial.driverLatitude ?? merchantLat;
    final initLng = initial.driverLongitude ?? merchantLng;
    orderProvider.updateDriverLocation(
      orderId: initial.id,
      driverLatitude: initLat,
      driverLongitude: initLng,
    );

    _driverSimTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) async {
      if (!mounted) return;

      final current = await orderProvider.watchOrderById(initial.id).firstWhere((o) => o != null);
      if (!mounted) return;
      final order = current!;

      if (order.fulfillmentType != FulfillmentType.delivery ||
          order.orderStatus != OrderStatus.onTheWay) {
        _driverSimTimer?.cancel();
        _driverSimTimer = null;
        return;
      }

      final clat = order.driverLatitude ?? initLat;
      final clng = order.driverLongitude ?? initLng;
      final distM = Geolocator.distanceBetween(clat, clng, destLat, destLng);

      // Close enough → snap to destination and complete the order.
      if (distM <= 35) {
        await orderProvider.updateDriverLocation(
          orderId: order.id,
          driverLatitude: destLat,
          driverLongitude: destLng,
        );
        await orderProvider.updateOrderStatus(order.id, OrderStatus.completed);
        _driverSimTimer?.cancel();
        _driverSimTimer = null;
        return;
      }

      // Move a small fraction closer each tick (smooth, no big jumps).
     const stepMeters = 400;
     final totalDist = Geolocator.distanceBetween(clat, clng, destLat, destLng);
     final ratio = stepMeters / totalDist;
     final nlat = clat + (destLat - clat) * ratio;
     final nlng = clng + (destLng - clng) * ratio;

      await orderProvider.updateDriverLocation(
        orderId: order.id,
        driverLatitude: nlat,
        driverLongitude: nlng,
      );
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
            OrderStatus.findingDriver,
            OrderStatus.preparing,
            OrderStatus.ready,
            OrderStatus.pickedUpByDriver,
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
    // Pickup: pending → confirmed (2s) → preparing → ready → completed.
    // Delivery: adds findingDriver, handoff + on-the-way gaps.
    if (fulfillmentType == FulfillmentType.delivery &&
        current == OrderStatus.onTheWay &&
        next == OrderStatus.completed) {
      final seconds = 6 + rng.nextInt(3);
      return Duration(seconds: seconds);
    }
    if (current == OrderStatus.pending && next == OrderStatus.confirmed) {
      return const Duration(seconds: 2);
    }
    if (current == OrderStatus.confirmed && next == OrderStatus.findingDriver) {
      return const Duration(seconds: 2);
    }
    if (current == OrderStatus.confirmed && next == OrderStatus.preparing) {
      return const Duration(seconds: 3);
    }
    if (current == OrderStatus.findingDriver && next == OrderStatus.preparing) {
      return const Duration(seconds: 3);
    }
    if (current == OrderStatus.preparing && next == OrderStatus.ready) {
      return const Duration(seconds: 5);
    }
    if (current == OrderStatus.ready &&
        next == OrderStatus.pickedUpByDriver) {
      return const Duration(seconds: 2);
    }
    if (current == OrderStatus.ready && next == OrderStatus.completed) {
      return const Duration(seconds: 2);
    }
    if (current == OrderStatus.pickedUpByDriver &&
        next == OrderStatus.onTheWay) {
      return const Duration(seconds: 2);
    }
    if (current == OrderStatus.ready && next == OrderStatus.onTheWay) {
      return const Duration(seconds: 5);
    }
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

      // Pickup collection is buyer-driven via swipe — do not auto-complete at ready.
      if (order.fulfillmentType == FulfillmentType.pickup &&
          order.orderStatus == OrderStatus.ready &&
          next == OrderStatus.completed) {
        return;
      }

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
    if (_driverMarkerIcon == null && !_driverMarkerKickScheduled) {
      _driverMarkerKickScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _driverMarkerKickScheduled = false;
        if (mounted) _ensureDriverMarkerBitmap();
      });
    }

    final merchant = LatLng(order.merchantLatitude!, order.merchantLongitude!);
    final delivery = LatLng(order.deliveryLatitude!, order.deliveryLongitude!);

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('merchant'),
        position: merchant,
        infoWindow: const InfoWindow(title: 'Merchant'),
      ),
      if (order.driverLatitude != null &&
          order.driverLongitude != null &&
          _driverMarkerIcon != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(order.driverLatitude!, order.driverLongitude!),
          icon: _driverMarkerIcon!,
          anchor: const Offset(0.5, 0.5),
          infoWindow: const InfoWindow(title: 'Driver'),
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

  String _riderWhatsAppPrefill(OrderModel order) {
    final merchantName = _resolveMerchantName(order).trim();
    final safeMerchant = merchantName.isEmpty ? 'your store' : merchantName;
    return 'Hello, I am waiting for my SaveBite order #${order.id} from '
        '$safeMerchant. Please share your current ETA. Thank you!';
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
              final orderProvider = context.read<OrderProvider>();
              Navigator.pop(context);
              final ok = await orderProvider.cancelOrder(widget.orderId);
              if (!mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
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

  /// In-app status toasts (no FCM). Updates [_lastKnownStatus] synchronously so
  /// identical stream data does not re-trigger. SnackBars only in [addPostFrameCallback].
  void _handleOrderStatusNotifications(OrderModel order) {
    if (!_statusStreamInitialized) {
      _lastKnownStatus = order.orderStatus;
      _statusStreamInitialized = true;
      return;
    }
    if (order.orderStatus == _lastKnownStatus) return;

    final prev = _lastKnownStatus!;
    final next = order.orderStatus;
    _lastKnownStatus = next;

    String? message;
    if (next == OrderStatus.confirmed && prev == OrderStatus.pending) {
      message = 'Order confirmed';
    } else if (next == OrderStatus.cancelled && prev != OrderStatus.cancelled) {
      message = BuyerOrderProgress.cancellationSnackBarMessage(order);
    }
    final msg = message;
    if (msg == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
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

        _handleOrderStatusNotifications(order);
        _maybeStartDemoAutoProgression(order);
        _syncDriverSimulation(order);

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
                if (order.fulfillmentType == FulfillmentType.delivery &&
                    order.orderStatus != OrderStatus.completed) ...[
                  _buildRiderCard(order),
                  const SizedBox(height: AppConstants.paddingL),
                ],
                if (order.orderStatus != OrderStatus.cancelled ||
                    BuyerOrderProgress.isMerchantRejectedTimeline(order)) ...[
                  _buildProgressCard(order),
                  const SizedBox(height: AppConstants.paddingL),
                ],
                _buildLocationCard(order),
                if (!_showsPickupSwipeAction(order)) ...[
                  const SizedBox(height: AppConstants.paddingL),
                  _buildActionButtons(order),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          bottomNavigationBar: _showsPickupSwipeAction(order)
              ? SafeArea(
                  minimum: const EdgeInsets.fromLTRB(
                    AppConstants.paddingL,
                    0,
                    AppConstants.paddingL,
                    AppConstants.paddingL,
                  ),
                  child: _buildPickupCollectedSwipe(order),
                )
              : null,
        );
      },
    );
  }

  bool _showsPickupSwipeAction(OrderModel order) {
    return order.fulfillmentType == FulfillmentType.pickup &&
        order.orderStatus == OrderStatus.ready;
  }

  Widget _buildPickupCollectedSwipe(OrderModel order) {
    return _SwipeToConfirmButton(
      label: 'Order collected',
      enabled: !_isConfirmingPickup,
      onConfirmed: () => _confirmPickupCollected(order),
    );
  }

  Widget _buildOrderIdLine(String id) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.paddingM),
      child: Text(
        '#$id',
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusHeroCard(OrderModel order) {
    final s = order.orderStatus;
    final description = _statusDescription(order);
    final style = _statusStyle(s, order.fulfillmentType);
    final isDeliveryOnTheWay = order.fulfillmentType == FulfillmentType.delivery &&
        order.orderStatus == OrderStatus.onTheWay;
    final deliveryMetrics =
        isDeliveryOnTheWay ? _computeDeliveryDistanceEta(order) : null;
    final etaLine = isDeliveryOnTheWay ? null : _deliveryEtaLine(order);
    final title = _statusTitle(order);
    final refundHint = BuyerOrderProgress.merchantRejectRefundSubtitle(order).trim();

    final id = order.id.isNotEmpty ? order.id : widget.orderId;

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
                if (isDeliveryOnTheWay && deliveryMetrics != null) ...[
                  Text(
                    '${deliveryMetrics.mins} mins',
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
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    '${deliveryMetrics.kmDisplay} km away',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _buildOrderIdLine(id),
                ] else ...[
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
                  if (refundHint.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.paddingS),
                    Text(
                      refundHint,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  _buildOrderIdLine(id),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPickupCollected(OrderModel order) async {
    if (_isConfirmingPickup) return;
    setState(() => _isConfirmingPickup = true);

    final orderProvider = context.read<OrderProvider>();
    final ok = await orderProvider.updateOrderStatus(
      order.id,
      OrderStatus.completed,
    );

    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      context.go('/home');
      return;
    }

    setState(() => _isConfirmingPickup = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not confirm pickup. Please try again.')),
    );
  }

  /// Delivery-only ETA/distance line.
  ///
  /// - If `onTheWay`: compute driver → delivery (fallback to merchant if driver missing).
  /// - Else: compute merchant → delivery.
  /// - Pickup orders: no ETA/distance.
  /// - Not used for delivery + [onTheWay] hero card (split mins / km there).
  String? _deliveryEtaLine(OrderModel order) {
    final r = _computeDeliveryDistanceEta(order);
    if (r == null) return null;
    return 'Arriving in ${r.mins} mins • ${r.kmDisplay} km';
  }

  Widget _buildProgressCard(OrderModel order) {
    final bool merchantReject =
        BuyerOrderProgress.isMerchantRejectedTimeline(order);

    late final List<String> titles;
    late final List<String> meanings;
    late final int len;
    late final int currentIndex;
    late final Color currentColor;
    late final bool isTerminalDone;

    if (merchantReject) {
      titles = BuyerOrderProgress.merchantRejectTitles;
      meanings = BuyerOrderProgress.merchantRejectMeanings;
      len = titles.length;
      currentIndex = BuyerOrderProgress.stepIndex(order);
      currentColor = AppColors.error;
      isTerminalDone = false;
    } else {
      titles = BuyerOrderProgress.labelsForFulfillment(order.fulfillmentType);
      meanings = BuyerOrderProgress.meaningsForFulfillment(order.fulfillmentType);
      len = titles.length;
      currentIndex = BuyerOrderProgress.stepIndex(order);
      currentColor =
          _statusStyle(order.orderStatus, order.fulfillmentType).color;
      isTerminalDone = order.orderStatus == OrderStatus.completed;
    }

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
          for (int i = 0; i < len; i++)
            _buildTimelineRow(
              title: titles[i],
              meaning: meanings[i],
              isDone: merchantReject ? i == 0 : (isTerminalDone ? true : i < currentIndex),
              isCurrent: merchantReject ? i == 1 : (isTerminalDone ? i == len - 1 : i == currentIndex),
              isLast: i == len - 1,
              currentColor: currentColor,
              dotWidgetOverride: merchantReject && i == 1
                  ? Icon(Icons.highlight_off_rounded,
                      color: AppColors.error, size: 24)
                  : null,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow({
    required String title,
    required String meaning,
    required bool isDone,
    required bool isCurrent,
    required bool isLast,
    required Color currentColor,
    Widget? dotWidgetOverride,
  }) {
    final Color dotColor = isDone
        ? AppColors.success
        : isCurrent
            ? currentColor
            : AppColors.divider;
    final Widget dot = dotWidgetOverride ??
        (isDone
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
              ));

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                    color: isDone || isCurrent
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meaning,
                  style: AppTypography.bodySmall.copyWith(
                    height: 1.25,
                    color: isDone
                        ? AppColors.textSecondary.withOpacity(0.85)
                        : isCurrent
                            ? AppColors.textSecondary
                            : AppColors.textTertiary.withOpacity(0.9),
                  ),
                ),
              ],
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

    if (_showsPickupSwipeAction(order)) {
      return const SizedBox.shrink();
    }

    if (status == OrderStatus.completed) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => context.go('/home'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF212121),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.paddingM,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.primaryCtaPillRadius,
              ),
            ),
          ),
          child: Text(
            'Home',
            style: AppTypography.buttonMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (status == OrderStatus.cancelled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF212121),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.paddingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.primaryCtaPillRadius,
                  ),
                ),
              ),
              child: Text(
                'Back to home',
                style: AppTypography.buttonMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingS),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/home?tab=1'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.paddingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.primaryCtaPillRadius,
                  ),
                ),
              ),
              child: Text(
                'View orders',
                style: AppTypography.buttonMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

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

  Widget _buildRiderCard(OrderModel order) {
    final phone = order.riderPhone?.trim();
    final name = order.riderName?.trim();
    final vehicle = order.riderVehicleInfo?.trim();
    final note = order.riderNote?.trim();
    final hasAny = (name != null && name.isNotEmpty) ||
        (phone != null && phone.isNotEmpty) ||
        (vehicle != null && vehicle.isNotEmpty) ||
        (note != null && note.isNotEmpty);
    final terminal = order.orderStatus == OrderStatus.completed ||
        order.orderStatus == OrderStatus.cancelled;

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
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text('Your rider', style: AppTypography.h5),
            ],
          ),
          if (!hasAny && !terminal) ...[
            const SizedBox(height: 10),
            Text(
              'Rider details will appear when the store assigns someone for delivery.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (name != null && name.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              name,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (vehicle != null && vehicle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              vehicle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(note, style: AppTypography.bodySmall),
          ],
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await openRiderWhatsApp(
                    phone,
                    message: _riderWhatsAppPrefill(order),
                  );
                  if (!mounted) return;
                  final message = riderWhatsAppLaunchSnackMessage(result);
                  if (message != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
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

/// Shared delivery distance + ETA (30 km/h heuristic). Same rules as legacy
/// `"Arriving in … • … km"` line.
({int mins, String kmDisplay})? _computeDeliveryDistanceEta(OrderModel order) {
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
  } else if (order.orderStatus == OrderStatus.pickedUpByDriver) {
    fromLat = order.driverLatitude ?? order.merchantLatitude;
    fromLng = order.driverLongitude ?? order.merchantLongitude;
  } else {
    fromLat = order.merchantLatitude;
    fromLng = order.merchantLongitude;
  }
  if (fromLat == null || fromLng == null) return null;

  final meters = Geolocator.distanceBetween(fromLat, fromLng, dl, dlg);
  final km = meters / 1000.0;
  const speedKmh = 30.0;
  final mins = (km / speedKmh * 60.0).ceil().clamp(1, 9999);
  final kmDisplay = km < 0.05 ? '0.1' : km.toStringAsFixed(1);
  return (mins: mins, kmDisplay: kmDisplay);
}

String _statusTitle(OrderModel order) {
  final s = order.orderStatus;
  final type = order.fulfillmentType;
  if (s == OrderStatus.cancelled) {
    return BuyerOrderProgress.cancellationHeroTitle(order);
  }
  switch (s) {
    case OrderStatus.pending:
      return 'Order placed';
    case OrderStatus.confirmed:
      return 'Order accepted';
    case OrderStatus.findingDriver:
      return 'Finding driver';
    case OrderStatus.preparing:
      return 'Preparing order';
    case OrderStatus.ready:
      return type == FulfillmentType.pickup
          ? 'Ready for pickup'
          : 'Order ready — driver handoff soon';
    case OrderStatus.pickedUpByDriver:
      return 'Picked up by driver';
    case OrderStatus.onTheWay:
      return 'On the way';
    case OrderStatus.completed:
      return type == FulfillmentType.pickup ? 'Collected' : 'Delivered';
    case OrderStatus.cancelled:
      return 'Cancelled';
  }
}

String _statusDescription(OrderModel order) {
  final s = order.orderStatus;
  final type = order.fulfillmentType;
  if (s == OrderStatus.cancelled) {
    return BuyerOrderProgress.cancellationHeroDescription(order);
  }
  switch (s) {
    case OrderStatus.pending:
      return 'Your order has been submitted. Waiting for the store to accept.';
    case OrderStatus.confirmed:
      return 'Merchant accepted your order.';
    case OrderStatus.findingDriver:
      return 'Searching for a delivery driver.';
    case OrderStatus.preparing:
      return 'Your food is being prepared.';
    case OrderStatus.ready:
      return type == FulfillmentType.pickup
          ? 'Ready to collect during pickup time.'
          : 'Packed and waiting for driver collection.';
    case OrderStatus.pickedUpByDriver:
      return 'The driver collected your order from the store.';
    case OrderStatus.onTheWay:
      return 'Driver is heading to your location.';
    case OrderStatus.completed:
      return type == FulfillmentType.pickup
          ? 'Pickup complete. Thank you!'
          : 'Delivered successfully. Enjoy!';
    case OrderStatus.cancelled:
      return '';
  }
}

({Color color, IconData icon}) _statusStyle(OrderStatus s, FulfillmentType type) {
  switch (s) {
    case OrderStatus.completed:
      return (color: AppColors.success, icon: Icons.done_all);
    case OrderStatus.cancelled:
      return (color: AppColors.error, icon: Icons.cancel);
    case OrderStatus.findingDriver:
      return (color: AppColors.primary, icon: Icons.search);
    case OrderStatus.ready:
      return type == FulfillmentType.pickup
          ? (color: AppColors.primary, icon: Icons.storefront_outlined)
          : (color: AppColors.primary, icon: Icons.inventory_2_outlined);
    case OrderStatus.pickedUpByDriver:
      return (color: AppColors.primary, icon: Icons.hail_outlined);
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

/// Swipe-right to confirm (e.g. pickup collected).
class _SwipeToConfirmButton extends StatefulWidget {
  const _SwipeToConfirmButton({
    required this.label,
    required this.onConfirmed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onConfirmed;
  final bool enabled;

  @override
  State<_SwipeToConfirmButton> createState() => _SwipeToConfirmButtonState();
}

class _SwipeToConfirmButtonState extends State<_SwipeToConfirmButton> {
  static const _trackColor = Color(0xFF212121);
  static const _height = 56.0;
  static const _thumbSize = 48.0;
  static const _horizontalPadding = 4.0;

  double _dragOffset = 0;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final maxDrag = max(
          0.0,
          trackWidth - _thumbSize - (_horizontalPadding * 2),
        );
        final threshold = maxDrag * 0.75;
        final offset = _confirmed ? maxDrag : _dragOffset.clamp(0.0, maxDrag);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: widget.enabled && !_confirmed
              ? (details) {
                  setState(() {
                    _dragOffset = max(
                      0.0,
                      min(maxDrag, _dragOffset + details.delta.dx),
                    );
                  });
                }
              : null,
          onHorizontalDragEnd: widget.enabled && !_confirmed
              ? (_) {
                  if (_dragOffset >= threshold) {
                    setState(() {
                      _confirmed = true;
                      _dragOffset = maxDrag;
                    });
                    widget.onConfirmed();
                  } else {
                    setState(() => _dragOffset = 0);
                  }
                }
              : null,
          child: SizedBox(
            height: _height,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: _height,
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? _trackColor
                        : _trackColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(
                      AppConstants.primaryCtaPillRadius,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    widget.label,
                    style: AppTypography.buttonMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned(
                  left: _horizontalPadding + offset,
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.keyboard_double_arrow_right,
                      color: _trackColor,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
