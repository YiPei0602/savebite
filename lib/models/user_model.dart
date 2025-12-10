/// User Model
/// 
/// Represents a user in the SaveBite platform.
/// Supports Consumer, Merchant, NGO, and Admin roles.
class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? profileImage;
  final String? phoneNumber;
  final String? address;
  final ImpactData impactData;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImage,
    this.phoneNumber,
    this.address,
    required this.impactData,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.consumer,
      ),
      profileImage: json['profileImage'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      impactData: ImpactData.fromJson(json['impactData'] as Map<String, dynamic>),
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
      'email': email,
      'role': role.toString().split('.').last,
      'profileImage': profileImage,
      'phoneNumber': phoneNumber,
      'address': address,
      'impactData': impactData.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? profileImage,
    String? phoneNumber,
    String? address,
    ImpactData? impactData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
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
  ngo,
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
    return ImpactData(
      mealsSaved: json['mealsSaved'] as int,
      co2Reduced: (json['co2Reduced'] as num).toDouble(),
      moneySaved: (json['moneySaved'] as num).toDouble(),
      ordersCompleted: json['ordersCompleted'] as int,
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
