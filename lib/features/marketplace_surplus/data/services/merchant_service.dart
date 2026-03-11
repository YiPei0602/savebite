import 'package:savebite/features/marketplace_surplus/domain/models/merchant_model.dart';

/// Merchant Service
///
/// Handles merchant operations.
/// Placeholder implementation (in-memory only).
/// Will be replaced with Firebase Firestore.
class MerchantService {
  // Singleton pattern
  static final MerchantService _instance = MerchantService._internal();
  factory MerchantService() => _instance;
  MerchantService._internal();

  // In-memory storage (starts empty; no hardcoded mock data)
  final List<MerchantModel> _merchants = [];

  /// Get all merchants
  ///
  /// TODO: Replace with Firebase Firestore query
  Future<List<MerchantModel>> getAllMerchants() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_merchants);
  }

  /// Get merchant by ID
  ///
  /// TODO: Replace with Firebase Firestore
  Future<MerchantModel?> getMerchantById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _merchants.indexWhere((m) => m.id == id);
    if (index == -1) return null;
    return _merchants[index];
  }

  /// Get merchants by location (within radius)
  ///
  /// TODO: Replace with Firebase Firestore GeoQuery or Google Maps API
  Future<List<MerchantModel>> getMerchantsByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_merchants);
  }

  /// Search merchants
  ///
  /// TODO: Replace with Firebase Firestore query or Algolia
  Future<List<MerchantModel>> searchMerchants(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final lowerQuery = query.toLowerCase();

    return _merchants.where((merchant) {
      return merchant.name.toLowerCase().contains(lowerQuery) ||
          merchant.description.toLowerCase().contains(lowerQuery);
    }).toList(growable: false);
  }

  /// Create merchant profile
  ///
  /// TODO: Replace with Firebase Firestore
  Future<MerchantModel> createMerchant(MerchantModel merchant) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _merchants.insert(0, merchant);
    return merchant;
  }

  /// Update merchant profile
  ///
  /// TODO: Replace with Firebase Firestore
  Future<MerchantModel> updateMerchant(MerchantModel merchant) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _merchants.indexWhere((m) => m.id == merchant.id);
    if (index == -1) {
      _merchants.insert(0, merchant);
      return merchant;
    }
    _merchants[index] = merchant;
    return merchant;
  }

  /// Delete merchant
  ///
  /// TODO: Replace with Firebase Firestore
  Future<void> deleteMerchant(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _merchants.removeWhere((m) => m.id == id);
  }
}

