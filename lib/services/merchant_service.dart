import '../models/merchant_model.dart';

/// Merchant Service
/// 
/// Handles merchant operations.
/// Currently uses mock data. Will be replaced with Firebase Firestore.
class MerchantService {
  // Singleton pattern
  static final MerchantService _instance = MerchantService._internal();
  factory MerchantService() => _instance;
  MerchantService._internal();

  /// Get all merchants
  /// 
  /// TODO: Replace with Firebase Firestore query
  Future<List<MerchantModel>> getAllMerchants() async {
    await Future.delayed(const Duration(seconds: 1));
    return _getMockMerchants();
  }

  /// Get merchant by ID
  /// 
  /// TODO: Replace with Firebase Firestore
  Future<MerchantModel?> getMerchantById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final merchants = _getMockMerchants();
    try {
      return merchants.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get merchants by location (within radius)
  /// 
  /// TODO: Replace with Firebase Firestore GeoQuery or Google Maps API
  Future<List<MerchantModel>> getMerchantsByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Mock: return all merchants for now
    return _getMockMerchants();
  }

  /// Search merchants
  /// 
  /// TODO: Replace with Firebase Firestore query or Algolia
  Future<List<MerchantModel>> searchMerchants(String query) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final merchants = _getMockMerchants();
    final lowerQuery = query.toLowerCase();
    
    return merchants.where((merchant) {
      return merchant.name.toLowerCase().contains(lowerQuery) ||
          merchant.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Create merchant profile
  /// 
  /// TODO: Replace with Firebase Firestore
  Future<MerchantModel> createMerchant(MerchantModel merchant) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return merchant;
  }

  /// Update merchant profile
  /// 
  /// TODO: Replace with Firebase Firestore
  Future<MerchantModel> updateMerchant(MerchantModel merchant) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return merchant;
  }

  /// Delete merchant
  /// 
  /// TODO: Replace with Firebase Firestore
  Future<void> deleteMerchant(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ============================================================================
  // MOCK DATA
  // ============================================================================

  List<MerchantModel> _getMockMerchants() {
    final now = DateTime.now();

    return [
      MerchantModel(
        id: 'merchant_001',
        name: 'The Baker\'s Cottage',
        description: 'Fresh baked goods daily',
        imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800',
        address: '123 Gurney Drive, Penang, 10250',
        latitude: 5.4370,
        longitude: 100.3089,
        rating: 4.7,
        reviewCount: 120,
        phoneNumber: '+60123456789',
        email: 'contact@bakerscottage.com',
        categories: ['Bakery', 'Desserts'],
        isActive: true,
        createdAt: now.subtract(const Duration(days: 365)),
      ),
      MerchantModel(
        id: 'merchant_002',
        name: 'Nasi Kandar Pelita',
        description: 'Authentic Malaysian cuisine',
        imageUrl: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800',
        address: '456 Jalan Sultan, Penang, 10300',
        latitude: 5.4164,
        longitude: 100.3327,
        rating: 4.5,
        reviewCount: 250,
        phoneNumber: '+60123456790',
        email: 'info@pelita.com',
        categories: ['Halal', 'Malaysian'],
        isActive: true,
        createdAt: now.subtract(const Duration(days: 500)),
      ),
      MerchantModel(
        id: 'merchant_003',
        name: 'Green Leaf Cafe',
        description: 'Healthy vegetarian options',
        imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
        address: '789 Lebuh Chulia, Penang, 10200',
        latitude: 5.4141,
        longitude: 100.3350,
        rating: 4.3,
        reviewCount: 85,
        phoneNumber: '+60123456791',
        email: 'hello@greenleaf.com',
        categories: ['Vegetarian', 'Healthy'],
        isActive: true,
        createdAt: now.subtract(const Duration(days: 200)),
      ),
      MerchantModel(
        id: 'merchant_004',
        name: 'KFC Gurney Plaza',
        description: 'Fast food chain',
        imageUrl: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=800',
        address: 'Gurney Plaza, Penang, 10250',
        latitude: 5.4380,
        longitude: 100.3100,
        rating: 4.6,
        reviewCount: 450,
        phoneNumber: '+60123456792',
        email: 'gurney@kfc.com.my',
        categories: ['Fast Food', 'Halal'],
        isActive: true,
        createdAt: now.subtract(const Duration(days: 800)),
      ),
    ];
  }
}
