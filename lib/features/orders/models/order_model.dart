import '../../cart/models/cart_item_model.dart';

/// Order Model
/// 
/// Represents a customer order.
class OrderModel {
  final String id;
  final String userId;
  final String merchantId;
  final String merchantName;
  final List<CartItemModel> items;
  final double subtotal;
  final double serviceFee;
  final double deliveryFee;
  final double totalPrice;
  final double totalSavings;
  final OrderStatus status;
  final FulfillmentType fulfillmentType;
  final PaymentMethod paymentMethod;
  final String? deliveryAddress;
  final String? pickupAddress;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.merchantId,
    required this.merchantName,
    required this.items,
    required this.subtotal,
    required this.serviceFee,
    required this.deliveryFee,
    required this.totalPrice,
    required this.totalSavings,
    required this.status,
    required this.fulfillmentType,
    required this.paymentMethod,
    this.deliveryAddress,
    this.pickupAddress,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      merchantId: json['merchantId'] as String,
      merchantName: json['merchantName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      serviceFee: (json['serviceFee'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      totalSavings: (json['totalSavings'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${json['status']}',
        orElse: () => OrderStatus.pending,
      ),
      fulfillmentType: FulfillmentType.values.firstWhere(
        (e) => e.toString() == 'FulfillmentType.${json['fulfillmentType']}',
        orElse: () => FulfillmentType.pickup,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${json['paymentMethod']}',
        orElse: () => PaymentMethod.cash,
      ),
      deliveryAddress: json['deliveryAddress'] as String?,
      pickupAddress: json['pickupAddress'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'serviceFee': serviceFee,
      'deliveryFee': deliveryFee,
      'totalPrice': totalPrice,
      'totalSavings': totalSavings,
      'status': status.toString().split('.').last,
      'fulfillmentType': fulfillmentType.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'deliveryAddress': deliveryAddress,
      'pickupAddress': pickupAddress,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? merchantId,
    String? merchantName,
    List<CartItemModel>? items,
    double? subtotal,
    double? serviceFee,
    double? deliveryFee,
    double? totalPrice,
    double? totalSavings,
    OrderStatus? status,
    FulfillmentType? fulfillmentType,
    PaymentMethod? paymentMethod,
    String? deliveryAddress,
    String? pickupAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      serviceFee: serviceFee ?? this.serviceFee,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      totalPrice: totalPrice ?? this.totalPrice,
      totalSavings: totalSavings ?? this.totalSavings,
      status: status ?? this.status,
      fulfillmentType: fulfillmentType ?? this.fulfillmentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
}

/// Order Status Enum
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  onTheWay,
  completed,
  cancelled,
}

/// Fulfillment Type Enum
enum FulfillmentType {
  pickup,
  delivery,
}

/// Payment Method Enum
enum PaymentMethod {
  cash,
  card,
  ewallet,
  onlineBanking,
}
