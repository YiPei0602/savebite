import 'package:flutter/foundation.dart';
import '../models/merchant_model.dart';
import '../services/merchant_service.dart';

/// Merchant Provider
/// 
/// Manages merchant state across the app.
class MerchantProvider with ChangeNotifier {
  final MerchantService _merchantService = MerchantService();

  List<MerchantModel> _merchants = [];
  MerchantModel? _currentMerchant;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<MerchantModel> get merchants => _merchants;
  MerchantModel? get currentMerchant => _currentMerchant;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load all merchants
  Future<void> loadMerchants() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _merchants = await _merchantService.getAllMerchants();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get merchant by ID
  Future<MerchantModel?> getMerchantById(String id) async {
    try {
      final merchant = await _merchantService.getMerchantById(id);
      if (merchant != null) {
        _currentMerchant = merchant;
        notifyListeners();
      }
      return merchant;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get merchants by location
  Future<void> loadMerchantsByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _merchants = await _merchantService.getMerchantsByLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search merchants
  Future<void> searchMerchants(String query) async {
    if (query.isEmpty) {
      await loadMerchants();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _merchants = await _merchantService.searchMerchants(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create merchant
  Future<bool> createMerchant(MerchantModel merchant) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdMerchant = await _merchantService.createMerchant(merchant);
      _merchants.insert(0, createdMerchant);
      _currentMerchant = createdMerchant;
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

  /// Update merchant
  Future<bool> updateMerchant(MerchantModel merchant) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedMerchant = await _merchantService.updateMerchant(merchant);
      
      final index = _merchants.indexWhere((m) => m.id == updatedMerchant.id);
      if (index >= 0) {
        _merchants[index] = updatedMerchant;
      }

      if (_currentMerchant?.id == updatedMerchant.id) {
        _currentMerchant = updatedMerchant;
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

  /// Delete merchant
  Future<bool> deleteMerchant(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _merchantService.deleteMerchant(id);
      _merchants.removeWhere((m) => m.id == id);
      
      if (_currentMerchant?.id == id) {
        _currentMerchant = null;
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

  /// Set current merchant
  void setCurrentMerchant(MerchantModel merchant) {
    _currentMerchant = merchant;
    notifyListeners();
  }

  /// Clear current merchant
  void clearCurrentMerchant() {
    _currentMerchant = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
