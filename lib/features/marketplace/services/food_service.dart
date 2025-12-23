import '../models/food_item_model.dart';

/// Food Service
/// 
/// Handles food item operations.
/// Currently uses mock data. Will be replaced with Firebase Firestore.
class FoodService {
  // Singleton pattern
  static final FoodService _instance = FoodService._internal();
  factory FoodService() => _instance;
  FoodService._internal();

  /// Get all available food items
  /// 
  /// TODO: Replace with Firebase Firestore query
  Future<List<FoodItemModel>> getAllFoodItems() async {
    await Future.delayed(const Duration(seconds: 1));
    return _getMockFoodItems();
  }

  /// Get food items by category
  /// 
  /// TODO: Replace with Firebase Firestore query
  Future<List<FoodItemModel>> getFoodItemsByCategory(FoodCategory category) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final allItems = _getMockFoodItems();
    return allItems.where((item) => item.category == category).toList();
  }

  /// Get food items by merchant
  /// 
  /// TODO: Replace with Firebase Firestore query
  Future<List<FoodItemModel>> getFoodItemsByMerchant(String merchantId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final allItems = _getMockFoodItems();
    return allItems.where((item) => item.merchantId == merchantId).toList();
  }

  /// Search food items
  /// 
  /// TODO: Replace with Firebase Firestore query or Algolia
  Future<List<FoodItemModel>> searchFoodItems(String query) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final allItems = _getMockFoodItems();
    final lowerQuery = query.toLowerCase();
    
    return allItems.where((item) {
      return item.name.toLowerCase().contains(lowerQuery) ||
          item.merchantName.toLowerCase().contains(lowerQuery) ||
          item.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get food item by ID
  /// 
  /// TODO: Replace with Firebase Firestore
  Future<FoodItemModel?> getFoodItemById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final allItems = _getMockFoodItems();
    try {
      return allItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Create new food item (Merchant only)
  /// 
  /// TODO: Replace with Firebase Firestore
  Future<FoodItemModel> createFoodItem(FoodItemModel item) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return item;
  }

  /// Update food item (Merchant only)
  /// 
  /// TODO: Replace with Firebase Firestore
  Future<FoodItemModel> updateFoodItem(FoodItemModel item) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return item;
  }

  /// Delete food item (Merchant only)
  /// 
  /// TODO: Replace with Firebase Firestore
  Future<void> deleteFoodItem(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Update stock quantity
  /// 
  /// TODO: Replace with Firebase Firestore transaction
  Future<void> updateStock(String id, int newStock) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ============================================================================
  // MOCK DATA
  // ============================================================================

  List<FoodItemModel> _getMockFoodItems() {
    final now = DateTime.now();
    final closingTime = DateTime(now.year, now.month, now.day, 20, 0); // 8 PM

    return [
      FoodItemModel(
        id: 'food_001',
        name: 'Surplus Pastry Box',
        merchantId: 'merchant_001',
        merchantName: 'The Baker\'s Cottage',
        description: 'Assorted fresh pastries from today\'s batch',
        originalPrice: 16.00,
        discountedPrice: 8.00,
        discountPercentage: 50,
        discountRange: const DiscountRange(minPercent: 30, maxPercent: 70),
        stock: 3,
        category: FoodCategory.bakery,
        dietaryTags: [DietaryTag.vegetarian],
        closingTime: closingTime,
        imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400',
        rating: 4.7,
        isAvailable: true,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      FoodItemModel(
        id: 'food_002',
        name: 'Mixed Bread Bundle',
        merchantId: 'merchant_001',
        merchantName: 'The Baker\'s Cottage',
        description: 'Various bread types - white, whole wheat, multigrain',
        originalPrice: 12.00,
        discountedPrice: 5.00,
        discountPercentage: 58,
        discountRange: const DiscountRange(minPercent: 40, maxPercent: 75),
        stock: 5,
        category: FoodCategory.bakery,
        dietaryTags: [DietaryTag.vegetarian],
        closingTime: closingTime,
        imageUrl: 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=400',
        rating: 4.5,
        isAvailable: true,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      FoodItemModel(
        id: 'food_003',
        name: 'Nasi Kandar Set',
        merchantId: 'merchant_002',
        merchantName: 'Nasi Kandar Pelita',
        description: 'Rice with curry chicken and vegetables',
        originalPrice: 25.00,
        discountedPrice: 12.50,
        discountPercentage: 50,
        discountRange: const DiscountRange(minPercent: 35, maxPercent: 65),
        stock: 8,
        category: FoodCategory.preparedMeals,
        dietaryTags: [DietaryTag.halal],
        closingTime: closingTime,
        imageUrl: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400',
        rating: 4.5,
        isAvailable: true,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      FoodItemModel(
        id: 'food_004',
        name: 'Vegetarian Bowl',
        merchantId: 'merchant_003',
        merchantName: 'Green Leaf Cafe',
        description: 'Fresh salad bowl with quinoa and roasted vegetables',
        originalPrice: 22.00,
        discountedPrice: 11.00,
        discountPercentage: 50,
        discountRange: const DiscountRange(minPercent: 30, maxPercent: 60),
        stock: 4,
        category: FoodCategory.preparedMeals,
        dietaryTags: [DietaryTag.vegetarian, DietaryTag.vegan, DietaryTag.glutenFree],
        closingTime: closingTime,
        imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
        rating: 4.3,
        isAvailable: true,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      FoodItemModel(
        id: 'food_005',
        name: 'Chicken Bucket',
        merchantId: 'merchant_004',
        merchantName: 'KFC Gurney Plaza',
        description: 'Fried chicken pieces with coleslaw',
        originalPrice: 30.00,
        discountedPrice: 15.00,
        discountPercentage: 50,
        discountRange: const DiscountRange(minPercent: 40, maxPercent: 70),
        stock: 6,
        category: FoodCategory.preparedMeals,
        dietaryTags: [DietaryTag.halal],
        closingTime: closingTime,
        imageUrl: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=400',
        rating: 4.6,
        isAvailable: true,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      FoodItemModel(
        id: 'food_006',
        name: 'Mystery Bag - Baker\'s Surprise',
        merchantId: 'merchant_001',
        merchantName: 'The Baker\'s Cottage',
        description: 'Surprise selection of baked goods',
        originalPrice: 28.00,
        discountedPrice: 10.00,
        discountPercentage: 64,
        discountRange: const DiscountRange(minPercent: 50, maxPercent: 80),
        stock: 2,
        category: FoodCategory.mysteryBag,
        dietaryTags: [DietaryTag.vegetarian],
        closingTime: closingTime,
        imageUrl: 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=400',
        rating: 4.2,
        isAvailable: true,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ];
  }
}
