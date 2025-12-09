import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/food_item_model.dart';

/// Cart Provider
/// 
/// Manages shopping cart state across the app.
class CartProvider with ChangeNotifier {
  final List<CartItemModel> _items = [];

  // Getters
  List<CartItemModel> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  /// Get subtotal (sum of all item prices)
  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// Get total savings
  double get totalSavings {
    return _items.fold(0.0, (sum, item) => sum + item.savings);
  }

  /// Get original total (before discounts)
  double get originalTotal {
    return _items.fold(0.0, (sum, item) {
      return sum + (item.foodItem.originalPrice * item.quantity);
    });
  }

  /// Add item to cart
  void addItem(FoodItemModel foodItem, {int quantity = 1}) {
    final existingIndex = _items.indexWhere(
      (item) => item.foodItem.id == foodItem.id,
    );

    if (existingIndex >= 0) {
      // Item already in cart, update quantity
      final existingItem = _items[existingIndex];
      final newQuantity = existingItem.quantity + quantity;
      
      // Check stock availability
      if (newQuantity <= foodItem.stock) {
        _items[existingIndex] = existingItem.copyWith(quantity: newQuantity);
      } else {
        throw Exception('Not enough stock available');
      }
    } else {
      // Add new item to cart
      if (quantity <= foodItem.stock) {
        _items.add(CartItemModel(
          id: 'cart_${DateTime.now().millisecondsSinceEpoch}',
          foodItem: foodItem,
          quantity: quantity,
          addedAt: DateTime.now(),
        ));
      } else {
        throw Exception('Not enough stock available');
      }
    }

    notifyListeners();
  }

  /// Remove item from cart
  void removeItem(String cartItemId) {
    _items.removeWhere((item) => item.id == cartItemId);
    notifyListeners();
  }

  /// Update item quantity
  void updateQuantity(String cartItemId, int newQuantity) {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    
    if (index >= 0) {
      if (newQuantity <= 0) {
        removeItem(cartItemId);
      } else {
        final item = _items[index];
        
        // Check stock availability
        if (newQuantity <= item.foodItem.stock) {
          _items[index] = item.copyWith(quantity: newQuantity);
          notifyListeners();
        } else {
          throw Exception('Not enough stock available');
        }
      }
    }
  }

  /// Increment item quantity
  void incrementQuantity(String cartItemId) {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    
    if (index >= 0) {
      final item = _items[index];
      final newQuantity = item.quantity + 1;
      
      if (newQuantity <= item.foodItem.stock) {
        _items[index] = item.copyWith(quantity: newQuantity);
        notifyListeners();
      } else {
        throw Exception('Maximum quantity reached');
      }
    }
  }

  /// Decrement item quantity
  void decrementQuantity(String cartItemId) {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    
    if (index >= 0) {
      final item = _items[index];
      final newQuantity = item.quantity - 1;
      
      if (newQuantity <= 0) {
        removeItem(cartItemId);
      } else {
        _items[index] = item.copyWith(quantity: newQuantity);
        notifyListeners();
      }
    }
  }

  /// Clear entire cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  /// Check if item is in cart
  bool isInCart(String foodItemId) {
    return _items.any((item) => item.foodItem.id == foodItemId);
  }

  /// Get quantity of specific item in cart
  int getItemQuantity(String foodItemId) {
    try {
      final item = _items.firstWhere(
        (item) => item.foodItem.id == foodItemId,
      );
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }

  /// Get cart item by food item ID
  CartItemModel? getCartItem(String foodItemId) {
    try {
      return _items.firstWhere(
        (item) => item.foodItem.id == foodItemId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Group items by merchant
  Map<String, List<CartItemModel>> get itemsByMerchant {
    final Map<String, List<CartItemModel>> grouped = {};
    
    for (final item in _items) {
      final merchantId = item.foodItem.merchantId;
      if (!grouped.containsKey(merchantId)) {
        grouped[merchantId] = [];
      }
      grouped[merchantId]!.add(item);
    }
    
    return grouped;
  }

  /// Check if cart has items from multiple merchants
  bool get hasMultipleMerchants {
    return itemsByMerchant.keys.length > 1;
  }
}
