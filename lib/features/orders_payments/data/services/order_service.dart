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

    await _firestore.runTransaction((tx) async {
      // Snapshot merchant coordinates at order creation time.
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

      for (final item in items) {
        final foodId = item.foodItem.id;
        final qty = item.quantity;
        final foodRef = _firestore.collection(_foodCollection).doc(foodId);
        final foodSnap = await tx.get(foodRef);
        final foodData = foodSnap.data();
        if (!foodSnap.exists || foodData == null) {
          throw Exception('An item in your cart is no longer available.');
        }
        final statusStr = (foodData['status'] as String?) ?? 'active';
        if (statusStr != 'active') {
          throw Exception('${item.foodItem.name} is no longer available.');
        }
        final closing = _closingTimeFromFoodData(foodData);
        if (closing == null || !checkoutNow.isBefore(closing)) {
          throw Exception('Pickup window for ${item.foodItem.name} has ended.');
        }
        final currentStock = (foodData['stock'] as num?)?.toInt() ?? 0;
        if (currentStock < qty) {
          throw Exception('Not enough stock for ${item.foodItem.name}.');
        }
        tx.update(foodRef, {
          'stock': currentStock - qty,
          'updatedAt': FieldValue.serverTimestamp(),
        });
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

  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _firestore.collection(_collection).doc(orderId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return _fromFirestore(data, doc.id);
  }

  /// Real-time updates for a single order document.
  Stream<OrderModel?> watchOrderById(String orderId) {
    return _firestore.collection(_collection).doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return _fromFirestore(data, doc.id);
    });
  }

  Future<List<OrderModel>> getOrdersByUser(String userId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('paymentStatus', isEqualTo: _paymentStatusString(PaymentStatus.paid))
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snap.docs.map((d) => _fromFirestore(d.data(), d.id)).toList();
  }

  Future<List<OrderModel>> getOrdersByMerchant(String merchantId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('merchantId', isEqualTo: merchantId)
        .where('paymentStatus', isEqualTo: _paymentStatusString(PaymentStatus.paid))
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snap.docs.map((d) => _fromFirestore(d.data(), d.id)).toList();
  }

  Stream<List<OrderModel>> watchOrdersByMerchant(
    String merchantId, {
    int limit = 100,
  }) {
    return _firestore
        .collection(_collection)
        .where('merchantId', isEqualTo: merchantId)
        .where('paymentStatus', isEqualTo: _paymentStatusString(PaymentStatus.paid))
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => _fromFirestore(d.data(), d.id)).toList());
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

  static void assertValidStatusTransition(OrderModel existing, OrderStatus newStatus) {
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
    normalized['orderStatus'] = normalized['orderStatus'] ??
        normalized['status'] ??
        'pending';
    normalized['fulfillmentType'] = normalized['fulfillmentType'] ?? 'pickup';
    normalized['paymentMethod'] = normalized['paymentMethod'] ?? 'cash';
    normalized['paymentStatus'] = normalized['paymentStatus'] ?? 'paid';
    normalized['currency'] = normalized['currency'] ?? 'myr';
    normalized['items'] = normalized['items'] ?? <dynamic>[];
    normalized['createdAt'] = normalized['createdAt'] ??
        Timestamp.fromDate(DateTime.now());

    return OrderModel.fromJson(normalized);
  }
}
