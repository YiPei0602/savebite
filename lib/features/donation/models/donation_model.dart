import '../../marketplace/models/food_item_model.dart';

/// Donation Model
/// 
/// Represents a food donation from merchant to NGO.
class DonationModel {
  final String id;
  final String merchantId;
  final String merchantName;
  final String ngoId;
  final String ngoName;
  final List<DonationItem> items;
  final DonationStatus status;
  final DateTime scheduledPickupTime;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;

  DonationModel({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    required this.ngoId,
    required this.ngoName,
    required this.items,
    required this.status,
    required this.scheduledPickupTime,
    required this.createdAt,
    this.completedAt,
    this.notes,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    return DonationModel(
      id: json['id'] as String,
      merchantId: json['merchantId'] as String,
      merchantName: json['merchantName'] as String,
      ngoId: json['ngoId'] as String,
      ngoName: json['ngoName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => DonationItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      status: DonationStatus.values.firstWhere(
        (e) => e.toString() == 'DonationStatus.${json['status']}',
        orElse: () => DonationStatus.pending,
      ),
      scheduledPickupTime: DateTime.parse(json['scheduledPickupTime'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'ngoId': ngoId,
      'ngoName': ngoName,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status.toString().split('.').last,
      'scheduledPickupTime': scheduledPickupTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  DonationModel copyWith({
    String? id,
    String? merchantId,
    String? merchantName,
    String? ngoId,
    String? ngoName,
    List<DonationItem>? items,
    DonationStatus? status,
    DateTime? scheduledPickupTime,
    DateTime? createdAt,
    DateTime? completedAt,
    String? notes,
  }) {
    return DonationModel(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      ngoId: ngoId ?? this.ngoId,
      ngoName: ngoName ?? this.ngoName,
      items: items ?? this.items,
      status: status ?? this.status,
      scheduledPickupTime: scheduledPickupTime ?? this.scheduledPickupTime,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get estimatedValue {
    return items.fold(0.0, (sum, item) => sum + (item.estimatedValue * item.quantity));
  }
}

/// Donation Item
/// 
/// Represents an individual item in a donation.
class DonationItem {
  final String foodItemId;
  final String name;
  final int quantity;
  final double estimatedValue;
  final FoodCategory category;

  DonationItem({
    required this.foodItemId,
    required this.name,
    required this.quantity,
    required this.estimatedValue,
    required this.category,
  });

  factory DonationItem.fromJson(Map<String, dynamic> json) {
    return DonationItem(
      foodItemId: json['foodItemId'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      estimatedValue: (json['estimatedValue'] as num).toDouble(),
      category: FoodCategory.values.firstWhere(
        (e) => e.toString() == 'FoodCategory.${json['category']}',
        orElse: () => FoodCategory.other,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodItemId': foodItemId,
      'name': name,
      'quantity': quantity,
      'estimatedValue': estimatedValue,
      'category': category.toString().split('.').last,
    };
  }
}

/// Donation Status Enum
enum DonationStatus {
  pending,
  accepted,
  scheduled,
  pickedUp,
  completed,
  cancelled,
}
