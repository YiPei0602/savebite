import 'package:savebite/features/donations/domain/models/donation_model.dart';

/// Donation Service
///
/// Handles donation operations between merchants and NGOs.
/// Placeholder implementation (in-memory only).
/// Will be replaced with Firebase Firestore.
class DonationService {
  // Singleton pattern
  static final DonationService _instance = DonationService._internal();
  factory DonationService() => _instance;
  DonationService._internal();

  // In-memory storage (starts empty; no hardcoded mock data)
  final List<DonationModel> _donations = [];

  /// Create new donation
  ///
  /// TODO: Replace with Firebase Firestore
  Future<DonationModel> createDonation({
    required String merchantId,
    required String merchantName,
    required String ngoId,
    required String ngoName,
    required List<DonationItem> items,
    required DateTime scheduledPickupTime,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final donation = DonationModel(
      id: 'donation_${DateTime.now().millisecondsSinceEpoch}',
      merchantId: merchantId,
      merchantName: merchantName,
      ngoId: ngoId,
      ngoName: ngoName,
      items: items,
      status: DonationStatus.pending,
      scheduledPickupTime: scheduledPickupTime,
      createdAt: DateTime.now(),
      notes: notes,
    );

    _donations.insert(0, donation);
    return donation;
  }

  /// Get donation by ID
  ///
  /// TODO: Replace with Firebase Firestore
  Future<DonationModel?> getDonationById(String donationId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _donations.indexWhere((d) => d.id == donationId);
    if (index == -1) return null;
    return _donations[index];
  }

  /// Get donations by merchant
  ///
  /// TODO: Replace with Firebase Firestore query
  Future<List<DonationModel>> getDonationsByMerchant(String merchantId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _donations
        .where((d) => d.merchantId == merchantId)
        .toList(growable: false);
  }

  /// Get donations by NGO
  ///
  /// TODO: Replace with Firebase Firestore query
  Future<List<DonationModel>> getDonationsByNGO(String ngoId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _donations
        .where((d) => d.ngoId == ngoId)
        .toList(growable: false);
  }

  /// Get pending donations
  ///
  /// TODO: Replace with Firebase Firestore query
  Future<List<DonationModel>> getPendingDonations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _donations
        .where((d) => d.status == DonationStatus.pending)
        .toList(growable: false);
  }

  /// Update donation status
  ///
  /// TODO: Replace with Firebase Firestore
  Future<DonationModel> updateDonationStatus(
    String donationId,
    DonationStatus newStatus,
  ) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final donationIndex = _donations.indexWhere((d) => d.id == donationId);
    if (donationIndex == -1) {
      throw Exception('Donation not found');
    }

    final updatedDonation = _donations[donationIndex].copyWith(
      status: newStatus,
      completedAt: newStatus == DonationStatus.completed ? DateTime.now() : null,
    );

    _donations[donationIndex] = updatedDonation;
    return updatedDonation;
  }

  /// Accept donation (NGO action)
  ///
  /// TODO: Replace with Firebase Firestore
  Future<DonationModel> acceptDonation(String donationId) async {
    return updateDonationStatus(donationId, DonationStatus.accepted);
  }

  /// Schedule pickup
  ///
  /// TODO: Replace with Firebase Firestore
  Future<DonationModel> scheduleDonationPickup(
    String donationId,
    DateTime pickupTime,
  ) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final donationIndex = _donations.indexWhere((d) => d.id == donationId);
    if (donationIndex == -1) {
      throw Exception('Donation not found');
    }

    final updatedDonation = _donations[donationIndex].copyWith(
      scheduledPickupTime: pickupTime,
      status: DonationStatus.scheduled,
    );

    _donations[donationIndex] = updatedDonation;
    return updatedDonation;
  }

  /// Mark donation as picked up
  ///
  /// TODO: Replace with Firebase Firestore
  Future<DonationModel> markAsPickedUp(String donationId) async {
    return updateDonationStatus(donationId, DonationStatus.pickedUp);
  }

  /// Complete donation
  ///
  /// TODO: Replace with Firebase Firestore
  Future<DonationModel> completeDonation(String donationId) async {
    return updateDonationStatus(donationId, DonationStatus.completed);
  }

  /// Cancel donation
  ///
  /// TODO: Replace with Firebase Firestore
  Future<DonationModel> cancelDonation(String donationId) async {
    return updateDonationStatus(donationId, DonationStatus.cancelled);
  }

  /// Get available NGOs
  ///
  /// TODO: Replace with Firebase Firestore query
  Future<List<Map<String, String>>> getAvailableNGOs() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return const [];
  }
}

