import 'dart:math' show max;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savebite/features/orders_payments/domain/models/cart_item_model.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';
import 'package:savebite/shared/utils/firestore_timestamp_utils.dart';

/// Order Service
///
/// Firestore-backed orders. Persist only after successful payment; stock is
/// decremented in the same transaction as the order document when [paymentStatus]
/// is [PaymentStatus.paid].
class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  static const String _collection = 'orders';
  static const String _foodCollection = 'food_items';
  static const String _merchantCollection = 'merchants';
  static const String _stockReservationsCollection = 'stock_reservations';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String _paymentStatusString(PaymentStatus s) =>
      s.toString().split('.').last;

  DateTime? _closingTimeFromFoodData(Map<String, dynamic> data) {
    return dateTimeFromFirestore(data['closingTime']);
  }

  /// Persists order and decrements stock only when [paymentStatus] is [paid].
  Future<OrderModel> createOrder({
    required String userId,
    required String merchantId,
    required String merchantName,
    required List<CartItemModel> items,
    required double subtotal,
    required double serviceFee,
    required double deliveryFee,
    required double totalPrice,
    required double totalSavings,
    required FulfillmentType fulfillmentType,
    required PaymentMethod paymentMethod,
    required PaymentStatus paymentStatus,
    String? deliveryAddress,
    String? pickupAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryPlaceId,
  }) async {
    if (paymentStatus == PaymentStatus.failed) {
      throw ArgumentError(
        'Cannot create an order with failed payment status.',
      );
    }
    if (paymentStatus != PaymentStatus.paid) {
      throw UnsupportedError(
        'Only paid orders are persisted after checkout; got $paymentStatus',
      );
    }

    final docRef = _firestore.collection(_collection).doc();
    final now = DateTime.now();
    final order = OrderModel(
      id: docRef.id,
      userId: userId,
      merchantId: merchantId,
      merchantName: merchantName,
      items: items,
      subtotal: subtotal,
      serviceFee: serviceFee,
      deliveryFee: deliveryFee,
      totalPrice: totalPrice,
      totalSavings: totalSavings,
      orderStatus: OrderStatus.pending,
      fulfillmentType: fulfillmentType,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      currency: 'myr',
      paidAt: now,
      deliveryAddress: deliveryAddress,
      pickupAddress: pickupAddress,
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
      deliveryPlaceId: deliveryPlaceId,
      createdAt: now,
    );

    final checkoutNow = DateTime.now();

    final reservationRefs = await _reservationRefsForPaidOrder(
      userId: userId,
      items: items,
    );

    await _firestore.runTransaction((tx) async {
      final Map<String, int> releaseReservedByFood = {};
      for (final ref in reservationRefs) {
        final resSnap = await tx.get(ref);
        if (!resSnap.exists || resSnap.data() == null) continue;
        final rd = resSnap.data()!;
        final fid = rd['foodItemId'] as String? ?? '';
        final rq = (rd['reservedQuantity'] as num?)?.toInt() ?? 0;
        if (fid.isEmpty || rq < 1) continue;
        releaseReservedByFood[fid] = (releaseReservedByFood[fid] ?? 0) + rq;
      }

      double? merchantLat;
      double? merchantLng;
      try {
        final merchantRef =
            _firestore.collection(_merchantCollection).doc(merchantId);
        final merchantSnap = await tx.get(merchantRef);
        final m = merchantSnap.data();
        merchantLat = (m?['latitude'] as num?)?.toDouble();
        merchantLng = (m?['longitude'] as num?)?.toDouble();
      } catch (_) {
        // Best-effort: distance/ETA will be unavailable if coords are missing.
      }

      final qtyByFood = <String, int>{};
      final nameByFood = <String, String>{};
      for (final item in items) {
        final id = item.foodItem.id;
        qtyByFood[id] = (qtyByFood[id] ?? 0) + item.quantity;
        nameByFood[id] = item.foodItem.name;
      }

      final foodSnaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final foodId in qtyByFood.keys) {
        foodSnaps[foodId] = await tx.get(
          _firestore.collection(_foodCollection).doc(foodId),
        );
      }

      for (final entry in qtyByFood.entries) {
        final foodId = entry.key;
        final qty = entry.value;
        final name = nameByFood[foodId] ?? 'item';
        final foodSnap = foodSnaps[foodId];
        final foodData = foodSnap?.data();
        if (foodSnap == null || !foodSnap.exists || foodData == null) {
          throw Exception('An item in your cart is no longer available.');
        }
        final statusStr = (foodData['status'] as String?) ?? 'active';
        if (statusStr != 'active') {
          throw Exception('$name is no longer available.');
        }
        final closing = _closingTimeFromFoodData(foodData);
        if (closing == null || !checkoutNow.isBefore(closing)) {
          throw Exception('Pickup window for $name has ended.');
        }
        final currentStock = (foodData['stock'] as num?)?.toInt() ?? 0;
        final reservedAgg = (foodData['reservedStock'] as num?)?.toInt() ?? 0;
        final released = releaseReservedByFood[foodId] ?? 0;
        final reservedByOthers = max(0, reservedAgg - released);
        final availableForThisOrder = currentStock - reservedByOthers;
        if (availableForThisOrder < qty) {
          throw Exception('Not enough stock for $name.');
        }
        final newReserved = max(0, reservedAgg - released);
        tx.update(foodSnap.reference, {
          'stock': currentStock - qty,
          'reservedStock': newReserved,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      for (final ref in reservationRefs) {
        tx.delete(ref);
      }

      final payload = <String, dynamic>{
        ...order
            .copyWith(
              merchantLatitude: merchantLat,
              merchantLongitude: merchantLng,
            )
            .toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
        'completedAt': null,
      };
      payload['paidAt'] = FieldValue.serverTimestamp();
      tx.set(docRef, payload);
    });

    return order;
  }

  Future<List<DocumentReference<Map<String, dynamic>>>>
      _reservationRefsForPaidOrder({
    required String userId,
    required List<CartItemModel> items,
  }) async {
    final foodIds = items.map((e) => e.foodItem.id).toSet();
    if (foodIds.isEmpty) return [];

    final ts = Timestamp.now();
    final snap = await _firestore
        .collection(_stockReservationsCollection)
        .where('userId', isEqualTo: userId)
        .where('expirationTimestamp', isGreaterThan: ts)
        .get();

    return snap.docs
        .where((d) => foodIds.contains(d.data()['foodItemId'] as String?))
        .map((d) => d.reference)
        .toList(growable: false);
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _firestore.collection(_collection).doc(orderId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return _fromFirestore(data, doc.id);
  }

  /// Real-time updates for a single order document.
  Stream<OrderModel?> watchOrderById(String orderId) {
    return _firestore
        .collection(_collection)
        .doc(orderId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return _fromFirestore(data, doc.id);
    });
  }

  static String? _optionalTrim(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  /// Merchant-only rider/partner details for manual third-party delivery handoff.
  Future<OrderModel> updateOrderRiderDetails({
    required String orderId,
    String? riderName,
    String? riderPhone,
    String? riderVehicleInfo,
    String? riderNote,
  }) async {
    final docRef = _firestore.collection(_collection).doc(orderId);
    await docRef.set(
      <String, dynamic>{
        'riderName': _optionalTrim(riderName),
        'riderPhone': _optionalTrim(riderPhone),
        'riderVehicleInfo': _optionalTrim(riderVehicleInfo),
        'riderNote': _optionalTrim(riderNote),
        'riderUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    final updated = await getOrderById(orderId);
    if (updated == null) throw Exception('Order not found');
    return updated;
  }

  /// Updates driver location fields (demo / tracking).
  Future<void> updateDriverLocation({
    required String orderId,
    required double driverLatitude,
    required double driverLongitude,
  }) async {
    final docRef = _firestore.collection(_collection).doc(orderId);
    await docRef.set(
      <String, dynamic>{
        'driverLatitude': driverLatitude,
        'driverLongitude': driverLongitude,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<List<OrderModel>> getOrdersByUser(String userId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('paymentStatus',
            isEqualTo: _paymentStatusString(PaymentStatus.paid))
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snap.docs.map((d) => _fromFirestore(d.data(), d.id)).toList();
  }

  Future<List<OrderModel>> getOrdersByMerchant(String merchantId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('merchantId', isEqualTo: merchantId)
        .get();
    final orders = snap.docs
        .map((d) => _fromFirestore(d.data(), d.id))
        .where((o) => o.paymentStatus == PaymentStatus.paid)
        .toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders.take(100).toList(growable: false);
  }

  Stream<List<OrderModel>> watchOrdersByMerchant(
    String merchantId, {
    int limit = 100,
  }) {
    return _firestore
        .collection(_collection)
        .where('merchantId', isEqualTo: merchantId)
        .snapshots()
        .map((snap) {
      final orders = snap.docs
          .map((d) => _fromFirestore(d.data(), d.id))
          .where((o) => o.paymentStatus == PaymentStatus.paid)
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders.take(limit).toList(growable: false);
    });
  }

  Future<List<OrderModel>> getActiveOrders(String userId) async {
    final all = await getOrdersByUser(userId);
    return all
        .where((o) =>
            o.orderStatus != OrderStatus.completed &&
            o.orderStatus != OrderStatus.cancelled)
        .toList(growable: false);
  }

  /// Valid single-step transitions from [current], respecting [fulfillmentType].
  ///
  /// Pickup: `pending → confirmed → preparing → ready → completed` (no `onTheWay`).
  /// Delivery: `… → ready → onTheWay → completed`.
  /// Cancel: only from `pending` or `confirmed`.
  static Set<OrderStatus> allowedNextStatuses({
    required OrderStatus current,
    required FulfillmentType fulfillmentType,
  }) {
    switch (current) {
      case OrderStatus.pending:
        return {OrderStatus.confirmed, OrderStatus.cancelled};
      case OrderStatus.confirmed:
        return {OrderStatus.preparing, OrderStatus.cancelled};
      case OrderStatus.preparing:
        return {OrderStatus.ready};
      case OrderStatus.ready:
        if (fulfillmentType == FulfillmentType.pickup) {
          return {OrderStatus.completed};
        }
        return {OrderStatus.onTheWay};
      case OrderStatus.onTheWay:
        return {OrderStatus.completed};
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return const {};
    }
  }

  static void assertValidStatusTransition(
      OrderModel existing, OrderStatus newStatus) {
    final current = existing.orderStatus;
    if (current == newStatus) {
      return;
    }
    final allowed = allowedNextStatuses(
      current: current,
      fulfillmentType: existing.fulfillmentType,
    );
    if (!allowed.contains(newStatus)) {
      final allowedStr = allowed.isEmpty
          ? 'none (terminal state)'
          : allowed.map((s) => s.name).join(', ');
      throw ArgumentError(
        'Invalid order status transition: ${current.name} → ${newStatus.name} '
        '(${existing.fulfillmentType.name}). Allowed: $allowedStr.',
      );
    }
  }

  Future<OrderModel> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    final existing = await getOrderById(orderId);
    if (existing == null) throw Exception('Order not found');
    if (existing.paymentStatus != PaymentStatus.paid) {
      throw Exception('Order payment is not complete.');
    }

    if (existing.orderStatus == newStatus) {
      return existing;
    }

    assertValidStatusTransition(existing, newStatus);

    final docRef = _firestore.collection(_collection).doc(orderId);
    final update = <String, dynamic>{
      'orderStatus': newStatus.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (newStatus == OrderStatus.completed) {
      update['completedAt'] = FieldValue.serverTimestamp();
    }
    if (newStatus == OrderStatus.cancelled) {
      update['completedAt'] = null;
    }
    await docRef.set(update, SetOptions(merge: true));
    final updated = await getOrderById(orderId);
    if (updated == null) throw Exception('Order not found');
    return updated;
  }

  Future<OrderModel> cancelOrder(String orderId) async {
    return updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  OrderModel _fromFirestore(Map<String, dynamic> data, String id) {
    final normalized = Map<String, dynamic>.from(data);
    normalized['id'] = id;

    // Keep Timestamp (or legacy string); [OrderModel.fromJson] parses via [dateTimeFromFirestore].
    normalized['userId'] = normalized['userId'] ?? '';
    normalized['merchantId'] = normalized['merchantId'] ?? '';
    normalized['merchantName'] = normalized['merchantName'] ?? '';
    normalized['subtotal'] = normalized['subtotal'] ?? 0;
    normalized['serviceFee'] = normalized['serviceFee'] ?? 0;
    normalized['deliveryFee'] = normalized['deliveryFee'] ?? 0;
    normalized['totalPrice'] = normalized['totalPrice'] ?? 0;
    normalized['totalSavings'] = normalized['totalSavings'] ?? 0;
    normalized['orderStatus'] =
        normalized['orderStatus'] ?? normalized['status'] ?? 'pending';
    normalized['fulfillmentType'] = normalized['fulfillmentType'] ?? 'pickup';
    normalized['paymentMethod'] = normalized['paymentMethod'] ?? 'cash';
    normalized['paymentStatus'] = normalized['paymentStatus'] ?? 'paid';
    normalized['currency'] = normalized['currency'] ?? 'myr';
    normalized['items'] = normalized['items'] ?? <dynamic>[];
    normalized['createdAt'] =
        normalized['createdAt'] ?? Timestamp.fromDate(DateTime.now());

    return OrderModel.fromJson(normalized);
  }
}
