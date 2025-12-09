import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../services/order_service.dart';

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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _orderService.createOrder(
        userId: userId,
        merchantId: merchantId,
        merchantName: merchantName,
        items: items,
        subtotal: subtotal,
        serviceFee: serviceFee,
        deliveryFee: deliveryFee,
        totalPrice: totalPrice,
        totalSavings: totalSavings,
        fulfillmentType: fulfillmentType,
        paymentMethod: paymentMethod,
        deliveryAddress: deliveryAddress,
        pickupAddress: pickupAddress,
      );

      _currentOrder = order;
      _orders.insert(0, order);
      _activeOrders.insert(0, order);
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
      final updatedOrder = await _orderService.updateOrderStatus(orderId, newStatus);
      
      // Update in orders list
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders[index] = updatedOrder;
      }

      // Update in active orders list
      final activeIndex = _activeOrders.indexWhere((o) => o.id == orderId);
      if (activeIndex >= 0) {
        if (newStatus == OrderStatus.completed || newStatus == OrderStatus.cancelled) {
          _activeOrders.removeAt(activeIndex);
        } else {
          _activeOrders[activeIndex] = updatedOrder;
        }
      }

      // Update current order if it matches
      if (_currentOrder?.id == orderId) {
        _currentOrder = updatedOrder;
      }

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

  /// Cancel order
  Future<bool> cancelOrder(String orderId) async {
    return updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  /// Filter orders by status
  List<OrderModel> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  /// Get completed orders
  List<OrderModel> get completedOrders {
    return _orders.where((order) => order.status == OrderStatus.completed).toList();
  }

  /// Get cancelled orders
  List<OrderModel> get cancelledOrders {
    return _orders.where((order) => order.status == OrderStatus.cancelled).toList();
  }

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
