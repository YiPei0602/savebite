import 'package:flutter/foundation.dart';
import '../models/food_item_model.dart';
import '../services/food_service.dart';

/// Food Provider
/// 
/// Manages food items state across the app.
class FoodProvider with ChangeNotifier {
  final FoodService _foodService = FoodService();

  List<FoodItemModel> _allFoodItems = [];
  List<FoodItemModel> _filteredFoodItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  Set<FoodCategory> _selectedCategories = {};
  Set<DietaryTag> _selectedDietaryTags = {};
  String? _selectedLocation;
  String _searchQuery = '';

  // Getters
  List<FoodItemModel> get allFoodItems => _allFoodItems;
  List<FoodItemModel> get filteredFoodItems => _filteredFoodItems;
  List<FoodItemModel> get displayedFoodItems =>
      _filteredFoodItems.isNotEmpty || _hasActiveFilters ? _filteredFoodItems : _allFoodItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<FoodCategory> get selectedCategories => _selectedCategories;
  Set<DietaryTag> get selectedDietaryTags => _selectedDietaryTags;
  String? get selectedLocation => _selectedLocation;
  String get searchQuery => _searchQuery;
  
  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategories.isNotEmpty ||
      _selectedDietaryTags.isNotEmpty ||
      _selectedLocation != null;

  /// Load all food items
  Future<void> loadFoodItems() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allFoodItems = await _foodService.getAllFoodItems();
      _filteredFoodItems = _allFoodItems;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle category filter (multi-select)
  void toggleCategory(FoodCategory category) {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
    } else {
      _selectedCategories.add(category);
    }
    _applyFilters();
  }

  /// Toggle dietary tag filter (multi-select)
  void toggleDietaryTag(DietaryTag tag) {
    if (_selectedDietaryTags.contains(tag)) {
      _selectedDietaryTags.remove(tag);
    } else {
      _selectedDietaryTags.add(tag);
    }
    _applyFilters();
  }

  /// Set location filter
  void setLocation(String? location) {
    _selectedLocation = location;
    _applyFilters();
  }

  /// Search food items (with debounce handled by UI)
  void searchFoodItems(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Apply all active filters
  void _applyFilters() {
    List<FoodItemModel> filtered = List.from(_allFoodItems);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(lowerQuery) ||
            item.merchantName.toLowerCase().contains(lowerQuery) ||
            item.description.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    // Apply category filter (multi-select)
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((item) {
        return _selectedCategories.contains(item.category);
      }).toList();
    }

    // Apply dietary tag filter (multi-select)
    if (_selectedDietaryTags.isNotEmpty) {
      filtered = filtered.where((item) {
        return _selectedDietaryTags.any((tag) => item.dietaryTags.contains(tag));
      }).toList();
    }

    // Apply location filter
    // TODO: When Firebase is integrated, filter by merchant location from MerchantModel
    if (_selectedLocation != null) {
      // For now, mock location filtering based on merchant name patterns
      // In production, this should query merchants by location and filter items
      filtered = filtered.where((item) {
        // Mock: Keep all items for now since we don't have location data in mock
        return true;
      }).toList();
    }

    _filteredFoodItems = filtered;
    notifyListeners();
  }

  /// Get food items by merchant
  Future<List<FoodItemModel>> getFoodItemsByMerchant(String merchantId) async {
    try {
      return await _foodService.getFoodItemsByMerchant(merchantId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get food item by ID
  Future<FoodItemModel?> getFoodItemById(String id) async {
    try {
      return await _foodService.getFoodItemById(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Create food item (Merchant only)
  Future<bool> createFoodItem(FoodItemModel item) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdItem = await _foodService.createFoodItem(item);
      _allFoodItems.insert(0, createdItem);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update food item (Merchant only)
  Future<bool> updateFoodItem(FoodItemModel item) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedItem = await _foodService.updateFoodItem(item);
      final index = _allFoodItems.indexWhere((i) => i.id == updatedItem.id);
      if (index != -1) {
        _allFoodItems[index] = updatedItem;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete food item (Merchant only)
  Future<bool> deleteFoodItem(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _foodService.deleteFoodItem(id);
      _allFoodItems.removeWhere((item) => item.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update stock
  Future<void> updateStock(String id, int newStock) async {
    try {
      await _foodService.updateStock(id, newStock);
      final index = _allFoodItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _allFoodItems[index] = _allFoodItems[index].copyWith(stock: newStock);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCategories.clear();
    _selectedDietaryTags.clear();
    _selectedLocation = null;
    _searchQuery = '';
    _filteredFoodItems = [];
    notifyListeners();
  }

  /// Get available locations (mock data)
  /// TODO: Replace with Firebase query for unique merchant locations
  List<String> getAvailableLocations() {
    return ['Penang', 'Kuala Lumpur', 'Johor Bahru', 'Selangor', 'Melaka'];
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
