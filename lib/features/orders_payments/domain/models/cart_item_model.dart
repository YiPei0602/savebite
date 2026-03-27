import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/food_item_model.dart';
import 'package:savebite/shared/utils/firestore_timestamp_utils.dart';

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
      addedAt: dateTimeFromFirestoreWithDefault(json['addedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodItem': foodItem.toJson(),
      'quantity': quantity,
      'addedAt': Timestamp.fromDate(addedAt),
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
    return foodItem.effectiveDiscountedPrice * quantity;
  }

  double get savings {
    return foodItem.effectiveSavings * quantity;
  }
}

