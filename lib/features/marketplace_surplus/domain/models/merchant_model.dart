import 'package:savebite/shared/utils/firestore_timestamp_utils.dart';
import 'package:savebite/shared/utils/merchant_operating_hours_firestore.dart';

/// Merchant Model
///
/// Represents a merchant/restaurant in the SaveBite platform.
class MerchantModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String address;
  final double? latitude;
  final double? longitude;
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final String email;
  final List<String> categories;
  /// Store open for customers (synced from Malaysia schedule when complete).
  final bool isOpen;
  /// Opening time `HH:mm` (Malaysia wall clock). Firestore: [Timestamp] on anchor date.
  final String? openingTime;
  /// Closing time `HH:mm` (Malaysia). May be after midnight vs [openingTime] (overnight).
  final String? closingTime;
  /// Days of week the store operates. Values: 1=Mon ... 7=Sun.
  final List<int> operatingDays;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MerchantModel({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.phoneNumber,
    required this.email,
    this.categories = const <String>[],
    this.isOpen = true,
    this.openingTime,
    this.closingTime,
    this.operatingDays = const <int>[],
    required this.createdAt,
    this.updatedAt,
  });

  factory MerchantModel.fromFirestore(Map<String, dynamic> json, String id) {
    final createdAt = dateTimeFromFirestoreWithDefault(json['createdAt']);
    final updatedAt = dateTimeFromFirestore(json['updatedAt']);

    return MerchantModel(
      id: id,
      name: ((json['name'] as String?)?.trim().isNotEmpty == true)
          ? (json['name'] as String).trim()
          : ((json['shopName'] as String?)?.trim().isNotEmpty == true)
              ? (json['shopName'] as String).trim()
              : 'Your Store',
      description: (json['description'] as String?) ?? '',
      imageUrl: (json['imageUrl'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as int?) ?? 0,
      phoneNumber: (json['phoneNumber'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      categories: (json['categories'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
      // Back-compat: prefer `isOpen`; legacy `isActive` still read.
      isOpen: (json['isOpen'] as bool?) ?? (json['isActive'] as bool?) ?? true,
      openingTime: MerchantOperatingHoursFirestore.readHhMm(json['openingTime']),
      closingTime: MerchantOperatingHoursFirestore.readHhMm(json['closingTime']),
      operatingDays: (json['operatingDays'] as List<dynamic>?)
              ?.map((d) => (d as num).toInt())
              .where((d) => d >= 1 && d <= 7)
              .toSet()
              .toList(growable: false) ??
          const <int>[],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      // Alias for schema compatibility / readability.
      'shopName': name,
      'description': description,
      'imageUrl': imageUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'reviewCount': reviewCount,
      'phoneNumber': phoneNumber,
      'email': email,
      'categories': categories,
      'isOpen': isOpen,
      'openingTime': MerchantOperatingHoursFirestore.writeHhMm(openingTime),
      'closingTime': MerchantOperatingHoursFirestore.writeHhMm(closingTime),
      'operatingDays': operatingDays,
    };
  }

  MerchantModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? address,
    double? latitude,
    double? longitude,
    double? rating,
    int? reviewCount,
    String? phoneNumber,
    String? email,
    List<String>? categories,
    bool? isOpen,
    String? openingTime,
    String? closingTime,
    List<int>? operatingDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MerchantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      categories: categories ?? this.categories,
      isOpen: isOpen ?? this.isOpen,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      operatingDays: operatingDays ?? this.operatingDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

