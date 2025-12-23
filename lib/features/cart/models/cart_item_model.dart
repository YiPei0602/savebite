import '../../marketplace/models/food_item_model.dart';

/// Cart Item Model
/// 
/// Represents an item in the shopping cart.
class CartItemModel {
  final String id;
  final FoodItemModel foodItem;
  final int quantity;
  final DateTime addedAt;

  CartItemModel({
    required this.id,
    required this.foodItem,
    required this.quantity,
    required this.addedAt,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      foodItem: FoodItemModel.fromJson(json['foodItem'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodItem': foodItem.toJson(),
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  CartItemModel copyWith({
    String? id,
    FoodItemModel? foodItem,
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      foodItem: foodItem ?? this.foodItem,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  double get subtotal {
    return foodItem.discountedPrice * quantity;
  }

  double get savings {
    return (foodItem.originalPrice - foodItem.discountedPrice) * quantity;
  }
}
