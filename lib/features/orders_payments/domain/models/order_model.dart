import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savebite/features/orders_payments/domain/models/cart_item_model.dart';
import 'package:savebite/shared/utils/firestore_timestamp_utils.dart';

/// Order Model
///
/// Represents a customer order.
/// - **Payment lifecycle:** [paymentStatus] (`pending` | `paid` | `failed`).
/// - **Fulfillment lifecycle:** [orderStatus] (`pending` → … → `completed` | `cancelled`).
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
  /// Fulfillment / kitchen workflow (pending → completed, etc.).
  final OrderStatus orderStatus;
  final FulfillmentType fulfillmentType;
  /// How the user chose to pay (stored as enum; wire value matches [PaymentMethod] name).
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String currency;
  final DateTime? paidAt;
  final String? deliveryAddress;
  final String? pickupAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? deliveryPlaceId;
  final double? merchantLatitude;
  final double? merchantLongitude;
  /// Delivery tracking (optional). Expected to be updated while order is `onTheWay`.
  final double? driverLatitude;
  final double? driverLongitude;
  /// Merchant-entered rider/delivery partner contact (manual dispatch; no third-party API).
  final String? riderName;
  final String? riderPhone;
  final String? riderVehicleInfo;
  final String? riderNote;
  final DateTime? riderUpdatedAt;
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
    required this.orderStatus,
    required this.fulfillmentType,
    required this.paymentMethod,
    required this.paymentStatus,
    this.currency = 'myr',
    this.paidAt,
    this.deliveryAddress,
    this.pickupAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryPlaceId,
    this.merchantLatitude,
    this.merchantLongitude,
    this.driverLatitude,
    this.driverLongitude,
    this.riderName,
    this.riderPhone,
    this.riderVehicleInfo,
    this.riderNote,
    this.riderUpdatedAt,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final orderStatusRaw = json['orderStatus'] as String? ??
        json['status'] as String? ??
        'pending';
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
      orderStatus: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.$orderStatusRaw',
        orElse: () => OrderStatus.pending,
      ),
      fulfillmentType: FulfillmentType.values.firstWhere(
        (e) => e.toString() == 'FulfillmentType.${json['fulfillmentType']}',
        orElse: () => FulfillmentType.pickup,
      ),
      paymentMethod: PaymentMethod.fromWire(
        json['paymentMethod']?.toString(),
      ),
      paymentStatus:
          PaymentStatus.fromWire(json['paymentStatus'] as String?),
      currency: (json['currency'] as String?) ?? 'myr',
      paidAt: dateTimeFromFirestore(json['paidAt']),
      deliveryAddress: json['deliveryAddress'] as String?,
      pickupAddress: json['pickupAddress'] as String?,
      deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble(),
      deliveryPlaceId: (json['deliveryPlaceId'] as String?)?.trim().isNotEmpty == true
          ? (json['deliveryPlaceId'] as String).trim()
          : null,
      merchantLatitude: (json['merchantLatitude'] as num?)?.toDouble(),
      merchantLongitude: (json['merchantLongitude'] as num?)?.toDouble(),
      driverLatitude: (json['driverLatitude'] as num?)?.toDouble(),
      driverLongitude: (json['driverLongitude'] as num?)?.toDouble(),
      riderName: (json['riderName'] as String?)?.trim().isNotEmpty == true
          ? (json['riderName'] as String).trim()
          : null,
      riderPhone: (json['riderPhone'] as String?)?.trim().isNotEmpty == true
          ? (json['riderPhone'] as String).trim()
          : null,
      riderVehicleInfo:
          (json['riderVehicleInfo'] as String?)?.trim().isNotEmpty == true
              ? (json['riderVehicleInfo'] as String).trim()
              : null,
      riderNote: (json['riderNote'] as String?)?.trim().isNotEmpty == true
          ? (json['riderNote'] as String).trim()
          : null,
      riderUpdatedAt: dateTimeFromFirestore(json['riderUpdatedAt']),
      createdAt: dateTimeFromFirestoreWithDefault(json['createdAt']),
      updatedAt: dateTimeFromFirestore(json['updatedAt']),
      completedAt: dateTimeFromFirestore(json['completedAt']),
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
      'orderStatus': orderStatus.toString().split('.').last,
      'fulfillmentType': fulfillmentType.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'currency': currency,
      'paidAt': timestampFromDateTime(paidAt),
      'deliveryAddress': deliveryAddress,
      'pickupAddress': pickupAddress,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'deliveryPlaceId': deliveryPlaceId,
      'merchantLatitude': merchantLatitude,
      'merchantLongitude': merchantLongitude,
      'driverLatitude': driverLatitude,
      'driverLongitude': driverLongitude,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'riderVehicleInfo': riderVehicleInfo,
      'riderNote': riderNote,
      'riderUpdatedAt': timestampFromDateTime(riderUpdatedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': timestampFromDateTime(updatedAt),
      'completedAt': timestampFromDateTime(completedAt),
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
    OrderStatus? orderStatus,
    FulfillmentType? fulfillmentType,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    String? currency,
    DateTime? paidAt,
    String? deliveryAddress,
    String? pickupAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryPlaceId,
    double? merchantLatitude,
    double? merchantLongitude,
    double? driverLatitude,
    double? driverLongitude,
    String? riderName,
    String? riderPhone,
    String? riderVehicleInfo,
    String? riderNote,
    DateTime? riderUpdatedAt,
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
      orderStatus: orderStatus ?? this.orderStatus,
      fulfillmentType: fulfillmentType ?? this.fulfillmentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      currency: currency ?? this.currency,
      paidAt: paidAt ?? this.paidAt,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      deliveryPlaceId: deliveryPlaceId ?? this.deliveryPlaceId,
      merchantLatitude: merchantLatitude ?? this.merchantLatitude,
      merchantLongitude: merchantLongitude ?? this.merchantLongitude,
      driverLatitude: driverLatitude ?? this.driverLatitude,
      driverLongitude: driverLongitude ?? this.driverLongitude,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      riderVehicleInfo: riderVehicleInfo ?? this.riderVehicleInfo,
      riderNote: riderNote ?? this.riderNote,
      riderUpdatedAt: riderUpdatedAt ?? this.riderUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}

/// Fulfillment / order lifecycle (merchant workflow).
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  onTheWay,
  completed,
  cancelled,
}

enum FulfillmentType {
  pickup,
  delivery,
}

/// Stored in Firestore as camelCase segment: `card`, `ewallet`, `onlineBanking`, `cash`.
/// [fromWire] also accepts legacy snake_case (`online_banking`).
enum PaymentMethod {
  cash,
  card,
  ewallet,
  onlineBanking;

  static PaymentMethod fromWire(String? raw) {
    if (raw == null || raw.isEmpty) return PaymentMethod.cash;
    switch (raw) {
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      case 'ewallet':
        return PaymentMethod.ewallet;
      case 'onlineBanking':
      case 'online_banking':
        return PaymentMethod.onlineBanking;
      default:
        return PaymentMethod.values.firstWhere(
          (e) => e.toString() == 'PaymentMethod.$raw',
          orElse: () => PaymentMethod.cash,
        );
    }
  }
}

/// Payment state (Stripe / checkout). Separate from [OrderStatus].
enum PaymentStatus {
  pending,
  paid,
  failed;

  static PaymentStatus fromWire(String? raw) {
    switch (raw) {
      case 'pending':
      case 'awaitingPayment':
        return PaymentStatus.pending;
      case 'paid':
      case 'mockPaid':
        return PaymentStatus.paid;
      case 'failed':
      case 'canceled':
      case 'cancelled':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.paid;
    }
  }
}
