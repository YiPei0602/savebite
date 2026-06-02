import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savebite/shared/utils/firestore_timestamp_utils.dart';

/// User Model
///
/// Represents a user in the SaveBite platform.
/// Supports Consumer and Merchant roles only.
/// Note: Admin access is managed through a separate web portal.
class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final UserRole role;
  final String? merchantId; // For merchant users: links to their business
  final String? profileImage;
  final String? phoneNumber;
  final String? address;
  final ImpactData impactData;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.merchantId,
    this.profileImage,
    this.phoneNumber,
    this.address,
    required this.impactData,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get full name (firstName + lastName)
  String get name {
    final parts = <String>[
      if (firstName.trim().isNotEmpty) firstName.trim(),
      if (lastName.trim().isNotEmpty) lastName.trim(),
    ];
    return parts.join(' ');
  }

  /// Create UserModel from Firestore document
  ///
  /// Converts Firestore Timestamp to DateTime
  factory UserModel.fromFirestore(Map<String, dynamic> json, String id) {
    final createdAt = dateTimeFromFirestoreWithDefault(json['createdAt']);
    final updatedAt = dateTimeFromFirestore(json['updatedAt']);

    // Parse role string to UserRole enum
    UserRole role;
    final roleString = json['role'] as String? ?? 'consumer';
    if (roleString == 'consumer') {
      role = UserRole.consumer;
    } else if (roleString == 'merchant') {
      role = UserRole.merchant;
    } else {
      role = UserRole.consumer; // Default fallback
    }

    // Handle impactData - create default if missing
    ImpactData impactData;
    if (json['impactData'] != null) {
      impactData = ImpactData.fromJson(json['impactData'] as Map<String, dynamic>);
    } else {
      impactData = ImpactData(
        mealsSaved: 0,
        co2Reduced: 0.0,
        moneySaved: 0.0,
        ordersCompleted: 0,
      );
    }

    // Handle name field - support both old (name) and new (firstName/lastName) formats
    String firstName;
    String lastName;
    if (json['firstName'] != null || json['lastName'] != null) {
      firstName = (json['firstName'] as String?)?.trim() ?? '';
      lastName = (json['lastName'] as String?)?.trim() ?? '';
    } else if (json['name'] != null) {
      // Legacy support: split name into first and last
      final nameParts = (json['name'] as String).trim().split(' ');
      firstName = nameParts.isNotEmpty ? nameParts.first : '';
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    } else {
      firstName = '';
      lastName = '';
    }

    return UserModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: json['email'] as String,
      role: role,
      merchantId: json['merchantId'] as String?,
      profileImage: json['profileImage'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      impactData: impactData,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle name field - support both old (name) and new (firstName/lastName) formats
    String firstName;
    String lastName;
    if (json['firstName'] != null || json['lastName'] != null) {
      firstName = (json['firstName'] as String?)?.trim() ?? '';
      lastName = (json['lastName'] as String?)?.trim() ?? '';
    } else if (json['name'] != null) {
      final nameParts = (json['name'] as String).trim().split(' ');
      firstName = nameParts.isNotEmpty ? nameParts.first : '';
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    } else {
      firstName = '';
      lastName = '';
    }

    return UserModel(
      id: json['id'] as String,
      firstName: firstName,
      lastName: lastName,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.consumer,
      ),
      merchantId: json['merchantId'] as String?,
      profileImage: json['profileImage'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      impactData: ImpactData.fromJson(json['impactData'] as Map<String, dynamic>),
      createdAt: dateTimeFromFirestoreWithDefault(json['createdAt']),
      updatedAt: dateTimeFromFirestore(json['updatedAt']),
    );
  }

  /// Convert UserModel to Firestore document format
  ///
  /// Converts DateTime to Timestamp for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role.toString().split('.').last, // 'consumer' or 'merchant'
      'merchantId': merchantId,
      'profileImage': profileImage,
      'phoneNumber': phoneNumber,
      'address': address,
      'impactData': impactData.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role.toString().split('.').last,
      'merchantId': merchantId,
      'profileImage': profileImage,
      'phoneNumber': phoneNumber,
      'address': address,
      'impactData': impactData.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    UserRole? role,
    String? merchantId,
    String? profileImage,
    String? phoneNumber,
    String? address,
    ImpactData? impactData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      merchantId: merchantId ?? this.merchantId,
      profileImage: profileImage ?? this.profileImage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      impactData: impactData ?? this.impactData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// User Role Enum
///
/// Note: Admin role is excluded from mobile app.
/// Admin access is managed through a separate web portal.
enum UserRole {
  consumer,
  merchant,
}

/// Impact Data
///
/// Tracks user's environmental and social impact.
class ImpactData {
  final int mealsSaved;
  final double co2Reduced; // in kg
  final double moneySaved; // in RM
  final int ordersCompleted;

  ImpactData({
    required this.mealsSaved,
    required this.co2Reduced,
    required this.moneySaved,
    required this.ordersCompleted,
  });

  factory ImpactData.fromJson(Map<String, dynamic> json) {
    final mealsSaved = json['mealsSaved'];
    final ordersCompleted = json['ordersCompleted'];

    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.round();
      return int.tryParse('$v') ?? 0;
    }

    double asDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0.0;
    }

    return ImpactData(
      mealsSaved: asInt(mealsSaved),
      co2Reduced: asDouble(json['co2Reduced']),
      moneySaved: asDouble(json['moneySaved']),
      ordersCompleted: asInt(ordersCompleted),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mealsSaved': mealsSaved,
      'co2Reduced': co2Reduced,
      'moneySaved': moneySaved,
      'ordersCompleted': ordersCompleted,
    };
  }

  ImpactData copyWith({
    int? mealsSaved,
    double? co2Reduced,
    double? moneySaved,
    int? ordersCompleted,
  }) {
    return ImpactData(
      mealsSaved: mealsSaved ?? this.mealsSaved,
      co2Reduced: co2Reduced ?? this.co2Reduced,
      moneySaved: moneySaved ?? this.moneySaved,
      ordersCompleted: ordersCompleted ?? this.ordersCompleted,
    );
  }
}

