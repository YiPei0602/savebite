import 'package:flutter/foundation.dart';
import 'package:savebite/features/orders_payments/data/services/order_service.dart';
import 'package:savebite/features/orders_payments/domain/models/cart_item_model.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';

/// Order Provider
///
/// Manages order state across the app.
class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<OrderModel> _orders = [];
  List<OrderModel> _activeOrders = [];
  bool _isLoading = false;
  String? _errorMessage;
  OrderModel? _currentOrder;

  // Getters
  List<OrderModel> get orders => _orders;
  List<OrderModel> get activeOrders => _activeOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  OrderModel? get currentOrder => _currentOrder;
  bool get hasActiveOrders => _activeOrders.isNotEmpty;

  /// Create new order
  Future<OrderModel?> createOrder({
    required String userId,
    required String merchantId,
    required String merchantName,
    String? customerName,
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
    String? stripePaymentIntentId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _orderService.createOrder(
        userId: userId,
        merchantId: merchantId,
        merchantName: merchantName,
        customerName: customerName,
        items: items,
        subtotal: subtotal,
        serviceFee: serviceFee,
        deliveryFee: deliveryFee,
        totalPrice: totalPrice,
        totalSavings: totalSavings,
        fulfillmentType: fulfillmentType,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        deliveryAddress: deliveryAddress,
        pickupAddress: pickupAddress,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        deliveryPlaceId: deliveryPlaceId,
        stripePaymentIntentId: stripePaymentIntentId,
      );

      _currentOrder = order;
      if (paymentStatus == PaymentStatus.paid) {
        // [loadMerchantOrders]/[loadActiveOrders] may assign fixed-length lists
        // from `.toList(growable: false)` — never call [insert] on those.
        _orders = [order, ...List<OrderModel>.from(_orders)];
        _activeOrders = [order, ...List<OrderModel>.from(_activeOrders)];
      }
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Load user orders
  Future<void> loadUserOrders(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _orderService.getOrdersByUser(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load active orders
  Future<void> loadActiveOrders(String userId) async {
    try {
      _activeOrders = await _orderService.getActiveOrders(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Load merchant orders
  Future<void> loadMerchantOrders(String merchantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _orderService.getOrdersByMerchant(merchantId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<OrderModel>> watchMerchantOrders(
    String merchantId, {
    int limit = 100,
  }) {
    return _orderService.watchOrdersByMerchant(merchantId, limit: limit);
  }

  /// Live stream for one order (e.g. consumer tracking).
  Stream<OrderModel?> watchOrderById(String orderId) {
    return _orderService.watchOrderById(orderId);
  }

  /// Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final order = await _orderService.getOrderById(orderId);
      if (order != null) {
        _currentOrder = order;
        notifyListeners();
      }
      return order;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedOrder =
          await _orderService.updateOrderStatus(orderId, newStatus);
      _patchOrderCaches(updatedOrder);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cancel order (buyer), sets [CancellationReason.buyerRequested] server-side merge.
  Future<bool> cancelOrder(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedOrder = await _orderService.cancelOrderAsBuyer(orderId);
      _patchOrderCaches(updatedOrder);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Merchant rejects a still-pending paid order ([CancellationReason.merchantRejected]).
  Future<bool> rejectPendingOrderAsMerchant(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedOrder =
          await _orderService.rejectPendingOrderAsMerchant(orderId);
      _patchOrderCaches(updatedOrder);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _patchOrderCaches(OrderModel updatedOrder) {
    final orderId = updatedOrder.id;
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx] = updatedOrder;
    }

    final activeIndex = _activeOrders.indexWhere((o) => o.id == orderId);
    if (activeIndex >= 0) {
      if (updatedOrder.orderStatus == OrderStatus.completed ||
          updatedOrder.orderStatus == OrderStatus.cancelled) {
        _activeOrders.removeAt(activeIndex);
      } else {
        _activeOrders[activeIndex] = updatedOrder;
      }
    }

    if (_currentOrder?.id == orderId) {
      _currentOrder = updatedOrder;
    }
  }

  Future<OrderModel?> updateOrderRiderDetails({
    required String orderId,
    String? riderName,
    String? riderPhone,
    String? riderVehicleInfo,
    String? riderNote,
  }) async {
    _errorMessage = null;
    try {
      final updated = await _orderService.updateOrderRiderDetails(
        orderId: orderId,
        riderName: riderName,
        riderPhone: riderPhone,
        riderVehicleInfo: riderVehicleInfo,
        riderNote: riderNote,
      );
      _replaceOrderInLists(updated);
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void _replaceOrderInLists(OrderModel updated) {
    final id = updated.id;
    final i = _orders.indexWhere((o) => o.id == id);
    if (i >= 0) _orders[i] = updated;
    final ai = _activeOrders.indexWhere((o) => o.id == id);
    if (ai >= 0) _activeOrders[ai] = updated;
    if (_currentOrder?.id == id) _currentOrder = updated;
  }

  Future<void> updateDriverLocation({
    required String orderId,
    required double driverLatitude,
    required double driverLongitude,
  }) async {
    try {
      await _orderService.updateDriverLocation(
        orderId: orderId,
        driverLatitude: driverLatitude,
        driverLongitude: driverLongitude,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Filter orders by status
  List<OrderModel> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.orderStatus == status).toList();
  }

  /// Get completed orders
  List<OrderModel> get completedOrders =>
      _orders.where((order) => order.orderStatus == OrderStatus.completed).toList();

  /// Get cancelled orders
  List<OrderModel> get cancelledOrders =>
      _orders.where((order) => order.orderStatus == OrderStatus.cancelled).toList();

  /// Clear current order
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

