import 'package:savebite/features/orders_payments/domain/models/cart_item_model.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';

/// Order Service
///
/// Handles order operations.
/// Placeholder implementation (in-memory only).
/// Will be replaced with Firebase Firestore.
class OrderService {
  // Singleton pattern
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  // In-memory orders storage (starts empty; no hardcoded mock orders)
  final List<OrderModel> _orders = [];

  /// Create new order
  ///
  /// TODO: Replace with Firebase Firestore
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
    String? deliveryAddress,
    String? pickupAddress,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final order = OrderModel(
      id: 'SB${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      userId: userId,
      merchantId: merchantId,
      merchantName: merchantName,
      items: items,
      subtotal: subtotal,
      serviceFee: serviceFee,
      deliveryFee: deliveryFee,
      totalPrice: totalPrice,
      totalSavings: totalSavings,
      status: OrderStatus.pending,
      fulfillmentType: fulfillmentType,
      paymentMethod: paymentMethod,
      deliveryAddress: deliveryAddress,
      pickupAddress: pickupAddress,
      createdAt: DateTime.now(),
    );

    _orders.insert(0, order);
    return order;
  }

  /// Get order by ID
  ///
  /// TODO: Replace with Firebase Firestore
  Future<OrderModel?> getOrderById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (_) {
      return null;
    }
  }

  /// Get orders by user
  ///
  /// TODO: Replace with Firebase Firestore query
  Future<List<OrderModel>> getOrdersByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _orders.where((order) => order.userId == userId).toList();
  }

  /// Get orders by merchant
  ///
  /// TODO: Replace with Firebase Firestore query
  Future<List<OrderModel>> getOrdersByMerchant(String merchantId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _orders.where((order) => order.merchantId == merchantId).toList();
  }

  /// Get active orders (not completed or cancelled)
  ///
  /// TODO: Replace with Firebase Firestore query
  Future<List<OrderModel>> getActiveOrders(String userId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _orders.where((order) {
      return order.userId == userId &&
          order.status != OrderStatus.completed &&
          order.status != OrderStatus.cancelled;
    }).toList();
  }

  /// Update order status
  ///
  /// TODO: Replace with Firebase Firestore
  Future<OrderModel> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    if (orderIndex == -1) {
      throw Exception('Order not found');
    }

    final updatedOrder = _orders[orderIndex].copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
      completedAt: newStatus == OrderStatus.completed ? DateTime.now() : null,
    );

    _orders[orderIndex] = updatedOrder;
    return updatedOrder;
  }

  /// Cancel order
  ///
  /// TODO: Replace with Firebase Firestore
  Future<OrderModel> cancelOrder(String orderId) async {
    return updateOrderStatus(orderId, OrderStatus.cancelled);
  }
}

