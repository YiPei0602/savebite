import '../models/order_model.dart';
import '../../cart/models/cart_item_model.dart';

/// Order Service
/// 
/// Handles order operations.
/// Currently uses mock data. Will be replaced with Firebase Firestore.
class OrderService {
  // Singleton pattern
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  // Mock orders storage
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
      status: OrderStatus.confirmed,
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
    } catch (e) {
      return null;
    }
  }

  /// Get orders by user
  /// 
  /// TODO: Replace with Firebase Firestore query
  Future<List<OrderModel>> getOrdersByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Return mock orders + any created orders
    final mockOrders = _getMockOrders(userId);
    final userOrders = _orders.where((order) => order.userId == userId).toList();
    
    return [...userOrders, ...mockOrders];
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
  Future<OrderModel> updateOrderStatus(String orderId, OrderStatus newStatus) async {
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

  // ============================================================================
  // MOCK DATA
  // ============================================================================

  List<OrderModel> _getMockOrders(String userId) {
    final now = DateTime.now();

    return [
      OrderModel(
        id: 'SB12345',
        userId: userId,
        merchantId: 'merchant_001',
        merchantName: 'The Baker\'s Cottage',
        items: [],
        subtotal: 23.00,
        serviceFee: 2.00,
        deliveryFee: 0.00,
        totalPrice: 25.00,
        totalSavings: 23.00,
        status: OrderStatus.completed,
        fulfillmentType: FulfillmentType.pickup,
        paymentMethod: PaymentMethod.card,
        pickupAddress: '123 Gurney Drive, Penang',
        createdAt: now.subtract(const Duration(days: 2)),
        completedAt: now.subtract(const Duration(days: 2, hours: 2)),
      ),
      OrderModel(
        id: 'SB12344',
        userId: userId,
        merchantId: 'merchant_002',
        merchantName: 'Nasi Kandar Pelita',
        items: [],
        subtotal: 15.50,
        serviceFee: 2.00,
        deliveryFee: 0.00,
        totalPrice: 17.50,
        totalSavings: 15.50,
        status: OrderStatus.completed,
        fulfillmentType: FulfillmentType.pickup,
        paymentMethod: PaymentMethod.ewallet,
        pickupAddress: '456 Jalan Sultan, Penang',
        createdAt: now.subtract(const Duration(days: 3)),
        completedAt: now.subtract(const Duration(days: 3, hours: 1)),
      ),
      OrderModel(
        id: 'SB12343',
        userId: userId,
        merchantId: 'merchant_003',
        merchantName: 'Green Leaf Cafe',
        items: [],
        subtotal: 18.00,
        serviceFee: 2.00,
        deliveryFee: 5.00,
        totalPrice: 25.00,
        totalSavings: 18.00,
        status: OrderStatus.completed,
        fulfillmentType: FulfillmentType.delivery,
        paymentMethod: PaymentMethod.card,
        deliveryAddress: 'Tower 1B, Ideal Residency, Penang',
        createdAt: now.subtract(const Duration(days: 5)),
        completedAt: now.subtract(const Duration(days: 5, hours: 1)),
      ),
    ];
  }
}
