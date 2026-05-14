import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:savebite/features/marketplace_surplus/data/services/food_service.dart';
import 'package:savebite/features/marketplace_surplus/data/services/merchant_service.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/food_item_model.dart';

/// Food Provider
///
/// Manages food items state across the app.
class FoodProvider with ChangeNotifier {
  final FoodService _foodService = FoodService();
  StreamSubscription<List<FoodItemModel>>? _consumerCatalogSub;

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

  /// Items after search/category filters. Stock-only; use [isSurplusSellableToConsumer]
  /// with [MerchantModel] in UI for pickup-window rules (overnight hours).
  List<FoodItemModel> get displayedFoodItems {
    final base = _filteredFoodItems.isNotEmpty || _hasActiveFilters
        ? _filteredFoodItems
        : _allFoodItems;
    return base
        .where((item) => item.isConsumerVisibleNow() && item.stock > 0)
        .toList();
  }

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

  void _upsertCatalog(List<FoodItemModel> fetched) {
    _allFoodItems = List<FoodItemModel>.of(fetched);
    if (_hasActiveFilters) {
      _applyFilters();
    } else {
      _filteredFoodItems = List<FoodItemModel>.of(_allFoodItems);
      notifyListeners();
    }
  }

  /// Load consumer-visible food items ([ListingStatus.active] only from service).
  Future<void> loadFoodItems({bool showLoadingIndicator = true}) async {
    if (showLoadingIndicator) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final fetched = await _foodService.getAllFoodItems();
      _upsertCatalog(fetched);
      _errorMessage = null;
      final merchantIds = fetched.map((e) => e.merchantId).toSet();
      unawaited(MerchantService().syncOpenStateForMerchantIds(merchantIds));
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (showLoadingIndicator) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  /// Keeps consumer catalog in sync without requiring hot restart.
  Future<void> startRealtimeCatalogSync() async {
    await _consumerCatalogSub?.cancel();
    _consumerCatalogSub = _foodService.watchAllFoodItems().listen(
      (items) {
        _errorMessage = null;
        _upsertCatalog(items);
      },
      onError: (Object e) {
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> stopRealtimeCatalogSync() async {
    await _consumerCatalogSub?.cancel();
    _consumerCatalogSub = null;
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
    List<FoodItemModel> filtered = _allFoodItems
        .where((item) => item.isConsumerVisibleNow() && item.stock > 0)
        .toList();

    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(lowerQuery) ||
            item.merchantName.toLowerCase().contains(lowerQuery) ||
            item.description.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.effectiveCategories.any(_selectedCategories.contains);
      }).toList();
    }

    if (_selectedDietaryTags.isNotEmpty) {
      filtered = filtered.where((item) {
        return _selectedDietaryTags
            .any((tag) => item.dietaryTags.contains(tag));
      }).toList();
    }

    if (_selectedLocation != null) {
      filtered = filtered.where((_) => true).toList();
    }

    _filteredFoodItems = filtered;
    notifyListeners();
  }

  /// Sets `expired` for this merchant's listings past [closingTime].
  Future<void> applyListingLifecycleForMerchant(String merchantId) async {
    try {
      await _foodService.applyListingLifecycleForMerchant(merchantId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Expired listings only: set `dismissedFromMerchantDashboard` (merchant UI hide; docs stay expired).
  Future<void> dismissExpiredFromMerchantDashboard(String merchantId) async {
    try {
      await _foodService.dismissExpiredFromMerchantDashboard(merchantId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
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
  Future<bool> createFoodItem(
    FoodItemModel item, {
    Uint8List? imageBytes,
    String? imageFileName,
    String? imageContentType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdItem = await _foodService.createFoodItem(
        item,
        imageBytes: imageBytes,
        imageFileName: imageFileName,
        imageContentType: imageContentType,
      );
      _allFoodItems.insert(0, createdItem);
      if (_hasActiveFilters) {
        _applyFilters();
      } else {
        _filteredFoodItems = List<FoodItemModel>.of(_allFoodItems);
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

  /// Update food item (Merchant only)
  Future<bool> updateFoodItem(
    FoodItemModel item, {
    Uint8List? imageBytes,
    String? imageFileName,
    String? imageContentType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedItem = await _foodService.updateFoodItem(
        item,
        imageBytes: imageBytes,
        imageFileName: imageFileName,
        imageContentType: imageContentType,
      );
      final index = _allFoodItems.indexWhere((i) => i.id == updatedItem.id);
      if (index != -1) {
        if (updatedItem.isConsumerVisibleNow()) {
          _allFoodItems[index] = updatedItem;
        } else {
          _allFoodItems.removeAt(index);
        }
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
        if (_hasActiveFilters) _applyFilters();
        // Defer notifyListeners to next frame to avoid _dependents.isEmpty
        // crash when called right after closing a dialog.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    } catch (e) {
      _errorMessage = e.toString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
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

  /// Get available locations
  ///
  /// TODO: Replace with Firebase query for unique merchant locations
  List<String> getAvailableLocations() {
    return const [];
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _consumerCatalogSub?.cancel();
    super.dispose();
  }
}
