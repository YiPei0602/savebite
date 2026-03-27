import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savebite/shared/utils/firestore_timestamp_utils.dart';

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

/// Listing lifecycle in Firestore (`status`): `active` → `expired` after [closingTime].
/// Legacy value `unsold` is read as [expired].
enum ListingStatus {
  active,
  expired;

  static ListingStatus fromFirestore(String? value) {
    switch (value) {
      case 'expired':
      case 'unsold':
        return ListingStatus.expired;
      case 'active':
        return ListingStatus.active;
      default:
        return ListingStatus.active;
    }
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
  /// Multi-category support (so one listing can appear in multiple sections).
  /// If empty, UI should fall back to [category].
  final List<FoodCategory> categories;
  final List<DietaryTag> dietaryTags;
  final DateTime closingTime;
  final String imageUrl;
  final double? rating;
  final bool isAvailable;
  /// Firestore field name: `status`. Missing/unknown values parse as [ListingStatus.active].
  final ListingStatus listingStatus;
  /// Merchant dashboard: when true, expired row is hidden from merchant UI only (doc stays `expired`).
  final bool dismissedFromMerchantDashboard;
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
    List<FoodCategory>? categories,
    required this.dietaryTags,
    required this.closingTime,
    required this.imageUrl,
    this.rating,
    this.isAvailable = true,
    this.listingStatus = ListingStatus.active,
    this.dismissedFromMerchantDashboard = false,
    required this.createdAt,
    this.updatedAt,
  }) : categories = categories ?? <FoodCategory>[];

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    final parsedCategory = FoodCategory.values.firstWhere(
      (e) => e.toString() == 'FoodCategory.${json['category']}',
      orElse: () => FoodCategory.other,
    );

    final parsedCategories = (json['categories'] as List<dynamic>?)
            ?.whereType<String>()
            .map(
              (name) => FoodCategory.values.firstWhere(
                (e) => e.name == name,
                orElse: () => FoodCategory.other,
              ),
            )
            .toList(growable: false) ??
        <FoodCategory>[];

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
          ? DiscountRange.fromJson(
              json['discountRange'] as Map<String, dynamic>,
            )
          : null,
      stock: json['stock'] as int,
      category: parsedCategory,
      categories: parsedCategories.isEmpty ? <FoodCategory>[parsedCategory] : parsedCategories,
      dietaryTags: (json['dietaryTags'] as List<dynamic>)
          .map((tag) => DietaryTag.values.firstWhere(
                (e) => e.toString() == 'DietaryTag.$tag',
                orElse: () => DietaryTag.none,
              ))
          .toList(),
      closingTime: dateTimeFromFirestoreWithDefault(json['closingTime']),
      imageUrl: json['imageUrl'] as String,
      rating:
          json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      isAvailable: json['isAvailable'] as bool? ?? true,
      listingStatus:
          ListingStatus.fromFirestore(json['status'] as String? ?? json['listingStatus'] as String?),
      dismissedFromMerchantDashboard:
          json['dismissedFromMerchantDashboard'] as bool? ?? false,
      createdAt: dateTimeFromFirestoreWithDefault(json['createdAt']),
      updatedAt: dateTimeFromFirestore(json['updatedAt']),
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
      'categories': effectiveCategories.map((c) => c.name).toList(),
      'dietaryTags':
          dietaryTags.map((tag) => tag.toString().split('.').last).toList(),
      'closingTime': Timestamp.fromDate(closingTime),
      'imageUrl': imageUrl,
      'rating': rating,
      'isAvailable': isAvailable,
      'status': listingStatus.name,
      'dismissedFromMerchantDashboard': dismissedFromMerchantDashboard,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': timestampFromDateTime(updatedAt),
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
    List<FoodCategory>? categories,
    List<DietaryTag>? dietaryTags,
    DateTime? closingTime,
    String? imageUrl,
    double? rating,
    bool? isAvailable,
    ListingStatus? listingStatus,
    bool? dismissedFromMerchantDashboard,
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
      categories: categories ?? this.categories,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      closingTime: closingTime ?? this.closingTime,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      isAvailable: isAvailable ?? this.isAvailable,
      listingStatus: listingStatus ?? this.listingStatus,
      dismissedFromMerchantDashboard:
          dismissedFromMerchantDashboard ?? this.dismissedFromMerchantDashboard,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Firestore `status` is [ListingStatus.active] (not expired).
  bool get isVisibleToConsumers => listingStatus == ListingStatus.active;

  /// Consumer catalog: active and before [closingTime] (hides stale `active` until lifecycle writes `expired`).
  bool isConsumerVisibleNow([DateTime? now]) {
    final t = now ?? DateTime.now();
    if (listingStatus != ListingStatus.active) return false;
    return t.isBefore(closingTime);
  }

  /// Merchant list: hide rows that are expired and already dismissed from dashboard.
  bool get isVisibleOnMerchantDashboard =>
      !(listingStatus == ListingStatus.expired && dismissedFromMerchantDashboard);

  /// Returns the discount % the customer should see *right now*.
  ///
  /// If [discountRange] is set, we progressively increase the discount as we
  /// approach [closingTime] (surplus urgency). Otherwise, we fall back to the
  /// stored [discountPercentage].
  ///
  /// Schedule (relative to closing time):
  /// - > 4h  : min
  /// - 4–2h  : 20% of the way to max
  /// - 2–1h  : 40% of the way to max
  /// - 1h–30m: 70% of the way to max
  /// - ≤ 30m : max
  int get effectiveDiscountPercentage {
    final range = discountRange;
    if (range == null) return discountPercentage;

    final max = range.maxPercent.clamp(0, 100);
    final min = range.minPercent.clamp(0, max);
    final span = max - min;
    if (span == 0) return min;

    final minutesLeft = closingTime.difference(DateTime.now()).inMinutes;
    if (minutesLeft <= 0) return max;

    final double t;
    if (minutesLeft > 240) {
      t = 0.0;
    } else if (minutesLeft > 120) {
      t = 0.2;
    } else if (minutesLeft > 60) {
      t = 0.4;
    } else if (minutesLeft > 30) {
      t = 0.7;
    } else {
      t = 1.0;
    }

    return (min + (span * t)).round().clamp(0, 100);
  }

  double get effectiveDiscountedPrice {
    final pct = effectiveDiscountPercentage;
    return originalPrice * (1 - pct / 100);
  }

  double get effectiveSavings {
    return originalPrice - effectiveDiscountedPrice;
  }

  /// Expiring soon used by merchant KPIs (your rule): < 30 minutes remaining.
  bool get isExpiringSoon30Min {
    final diff = closingTime.difference(DateTime.now());
    return diff.inMinutes <= 30 && diff.inMinutes > 0;
  }

  bool get isClosingSoon {
    final now = DateTime.now();
    final difference = closingTime.difference(now);
    return difference.inHours <= 2 && difference.inMinutes > 0;
  }

  double get savings {
    return effectiveSavings;
  }

  List<FoodCategory> get effectiveCategories =>
      categories.isNotEmpty ? categories : <FoodCategory>[category];
}

/// Product category for surplus listings (Firestore, filters, merchant forms).
///
/// This is the **data model** for what a food item *is* (bakery, snacks, etc.).
/// The home screen “Categories” row is a **curated subset** of routes (including
/// dietary shortcuts like Halal / Veggie) that map into [FoodCategory] and/or
/// [DietaryTag] in [CategoryListingScreen] — they are not a 1:1 duplicate list,
/// but every chip that represents a product type should resolve to a value here
/// for queries and persistence.
enum FoodCategory {
  bakery,
  meats,
  vegetables,
  dairy,
  preparedMeals,
  beverages,
  groceries,
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

