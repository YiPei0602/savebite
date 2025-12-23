/// Discount Range
/// 
/// Represents the min and max discount percentages for dynamic pricing.
class DiscountRange {
  final int minPercent;
  final int maxPercent;

  const DiscountRange({
    required this.minPercent,
    required this.maxPercent,
  });

  factory DiscountRange.fromJson(Map<String, dynamic> json) {
    return DiscountRange(
      minPercent: json['minPercent'] as int,
      maxPercent: json['maxPercent'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minPercent': minPercent,
      'maxPercent': maxPercent,
    };
  }
}

/// Food Item Model
/// 
/// Represents a surplus food item available for purchase.
class FoodItemModel {
  final String id;
  final String name;
  final String merchantId;
  final String merchantName;
  final String description;
  final double originalPrice;
  final double discountedPrice;
  final int discountPercentage;
  final DiscountRange? discountRange; // For dynamic pricing
  final int stock;
  final FoodCategory category;
  final List<DietaryTag> dietaryTags;
  final DateTime closingTime;
  final String imageUrl;
  final double? rating;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FoodItemModel({
    required this.id,
    required this.name,
    required this.merchantId,
    required this.merchantName,
    required this.description,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercentage,
    this.discountRange,
    required this.stock,
    required this.category,
    required this.dietaryTags,
    required this.closingTime,
    required this.imageUrl,
    this.rating,
    this.isAvailable = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    return FoodItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      merchantId: json['merchantId'] as String,
      merchantName: json['merchantName'] as String,
      description: json['description'] as String,
      originalPrice: (json['originalPrice'] as num).toDouble(),
      discountedPrice: (json['discountedPrice'] as num).toDouble(),
      discountPercentage: json['discountPercentage'] as int,
      discountRange: json['discountRange'] != null
          ? DiscountRange.fromJson(json['discountRange'] as Map<String, dynamic>)
          : null,
      stock: json['stock'] as int,
      category: FoodCategory.values.firstWhere(
        (e) => e.toString() == 'FoodCategory.${json['category']}',
        orElse: () => FoodCategory.other,
      ),
      dietaryTags: (json['dietaryTags'] as List<dynamic>)
          .map((tag) => DietaryTag.values.firstWhere(
                (e) => e.toString() == 'DietaryTag.$tag',
                orElse: () => DietaryTag.none,
              ))
          .toList(),
      closingTime: DateTime.parse(json['closingTime'] as String),
      imageUrl: json['imageUrl'] as String,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'description': description,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'discountPercentage': discountPercentage,
      'discountRange': discountRange?.toJson(),
      'stock': stock,
      'category': category.toString().split('.').last,
      'dietaryTags': dietaryTags.map((tag) => tag.toString().split('.').last).toList(),
      'closingTime': closingTime.toIso8601String(),
      'imageUrl': imageUrl,
      'rating': rating,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  FoodItemModel copyWith({
    String? id,
    String? name,
    String? merchantId,
    String? merchantName,
    String? description,
    double? originalPrice,
    double? discountedPrice,
    int? discountPercentage,
    DiscountRange? discountRange,
    int? stock,
    FoodCategory? category,
    List<DietaryTag>? dietaryTags,
    DateTime? closingTime,
    String? imageUrl,
    double? rating,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      description: description ?? this.description,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountRange: discountRange ?? this.discountRange,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      closingTime: closingTime ?? this.closingTime,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isClosingSoon {
    final now = DateTime.now();
    final difference = closingTime.difference(now);
    return difference.inHours <= 2 && difference.inMinutes > 0;
  }

  double get savings {
    return originalPrice - discountedPrice;
  }
}

/// Food Category Enum
enum FoodCategory {
  bakery,
  meats,
  vegetables,
  dairy,
  preparedMeals,
  beverages,
  snacks,
  desserts,
  mysteryBag,
  other,
}

/// Dietary Tag Enum
enum DietaryTag {
  none,
  halal,
  vegetarian,
  vegan,
  glutenFree,
  dairyFree,
  nutFree,
  organic,
}
