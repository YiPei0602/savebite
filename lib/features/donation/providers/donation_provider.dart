import 'package:flutter/foundation.dart';
import '../models/donation_model.dart';
import '../services/donation_service.dart';

/// Donation Provider
/// 
/// Manages donation state across the app.
class DonationProvider with ChangeNotifier {
  final DonationService _donationService = DonationService();

  List<DonationModel> _donations = [];
  List<DonationModel> _pendingDonations = [];
  bool _isLoading = false;
  String? _errorMessage;
  DonationModel? _currentDonation;

  // Getters
  List<DonationModel> get donations => _donations;
  List<DonationModel> get pendingDonations => _pendingDonations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DonationModel? get currentDonation => _currentDonation;
  bool get hasPendingDonations => _pendingDonations.isNotEmpty;

  /// Create new donation
  Future<DonationModel?> createDonation({
    required String merchantId,
    required String merchantName,
    required String ngoId,
    required String ngoName,
    required List<DonationItem> items,
    required DateTime scheduledPickupTime,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final donation = await _donationService.createDonation(
        merchantId: merchantId,
        merchantName: merchantName,
        ngoId: ngoId,
        ngoName: ngoName,
        items: items,
        scheduledPickupTime: scheduledPickupTime,
        notes: notes,
      );

      _currentDonation = donation;
      _donations.insert(0, donation);
      _pendingDonations.insert(0, donation);
      _isLoading = false;
      notifyListeners();
      return donation;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Load merchant donations
  Future<void> loadMerchantDonations(String merchantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _donations = await _donationService.getDonationsByMerchant(merchantId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load NGO donations
  Future<void> loadNGODonations(String ngoId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _donations = await _donationService.getDonationsByNGO(ngoId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load pending donations
  Future<void> loadPendingDonations() async {
    try {
      _pendingDonations = await _donationService.getPendingDonations();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Get donation by ID
  Future<DonationModel?> getDonationById(String donationId) async {
    try {
      final donation = await _donationService.getDonationById(donationId);
      if (donation != null) {
        _currentDonation = donation;
        notifyListeners();
      }
      return donation;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update donation status
  Future<bool> updateDonationStatus(
    String donationId,
    DonationStatus newStatus,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedDonation = await _donationService.updateDonationStatus(
        donationId,
        newStatus,
      );

      // Update in donations list
      final index = _donations.indexWhere((d) => d.id == donationId);
      if (index >= 0) {
        _donations[index] = updatedDonation;
      }

      // Update in pending donations list
      final pendingIndex = _pendingDonations.indexWhere((d) => d.id == donationId);
      if (pendingIndex >= 0) {
        if (newStatus != DonationStatus.pending) {
          _pendingDonations.removeAt(pendingIndex);
        } else {
          _pendingDonations[pendingIndex] = updatedDonation;
        }
      }

      // Update current donation if it matches
      if (_currentDonation?.id == donationId) {
        _currentDonation = updatedDonation;
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

  /// Accept donation (NGO action)
  Future<bool> acceptDonation(String donationId) async {
    return updateDonationStatus(donationId, DonationStatus.accepted);
  }

  /// Schedule pickup
  Future<bool> scheduleDonationPickup(
    String donationId,
    DateTime pickupTime,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedDonation = await _donationService.scheduleDonationPickup(
        donationId,
        pickupTime,
      );

      final index = _donations.indexWhere((d) => d.id == donationId);
      if (index >= 0) {
        _donations[index] = updatedDonation;
      }

      if (_currentDonation?.id == donationId) {
        _currentDonation = updatedDonation;
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

  /// Mark as picked up
  Future<bool> markAsPickedUp(String donationId) async {
    return updateDonationStatus(donationId, DonationStatus.pickedUp);
  }

  /// Complete donation
  Future<bool> completeDonation(String donationId) async {
    return updateDonationStatus(donationId, DonationStatus.completed);
  }

  /// Cancel donation
  Future<bool> cancelDonation(String donationId) async {
    return updateDonationStatus(donationId, DonationStatus.cancelled);
  }

  /// Get available NGOs
  Future<List<Map<String, String>>> getAvailableNGOs() async {
    try {
      return await _donationService.getAvailableNGOs();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Filter donations by status
  List<DonationModel> getDonationsByStatus(DonationStatus status) {
    return _donations.where((d) => d.status == status).toList();
  }

  /// Get completed donations
  List<DonationModel> get completedDonations {
    return _donations.where((d) => d.status == DonationStatus.completed).toList();
  }

  /// Clear current donation
  void clearCurrentDonation() {
    _currentDonation = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
