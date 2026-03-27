import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/merchant_model.dart';
import 'package:savebite/shared/utils/merchant_schedule_utils.dart';

/// Merchant Service
///
/// Handles merchant operations.
/// Firebase-backed implementation (Firestore).
class MerchantService {
  // Singleton pattern
  static final MerchantService _instance = MerchantService._internal();
  factory MerchantService() => _instance;
  MerchantService._internal();

  static const String _collection = 'merchants';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all merchants
  Future<List<MerchantModel>> getAllMerchants() async {
    final snap = await _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(80)
        .get();
    return snap.docs
        .map((d) => MerchantModel.fromFirestore(d.data(), d.id))
        .toList(growable: false);
  }

  /// Get merchant by ID
  Future<MerchantModel?> getMerchantById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return MerchantModel.fromFirestore(data, doc.id);
  }

  Stream<MerchantModel?> watchMerchant(String id) {
    return _firestore.collection(_collection).doc(id).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return MerchantModel.fromFirestore(data, doc.id);
    });
  }

  /// Get merchants by location (within radius)
  Future<List<MerchantModel>> getMerchantsByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    // TODO: Replace with geo query. For now: return all.
    return getAllMerchants();
  }

  /// Search merchants
  Future<List<MerchantModel>> searchMerchants(String query) async {
    final lower = query.trim().toLowerCase();
    if (lower.isEmpty) return getAllMerchants();
    final all = await getAllMerchants();
    return all
        .where((m) =>
            m.name.toLowerCase().contains(lower) ||
            m.description.toLowerCase().contains(lower))
        .toList(growable: false);
  }

  /// Create merchant profile
  Future<MerchantModel> createMerchant(MerchantModel merchant) async {
    final docRef = _firestore.collection(_collection).doc(merchant.id);
    await docRef.set({
      ...merchant.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return merchant;
  }

  /// Update merchant profile
  Future<MerchantModel> updateMerchant(MerchantModel merchant) async {
    final docRef = _firestore.collection(_collection).doc(merchant.id);
    await docRef.set({
      ...merchant.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return merchant;
  }

  Future<void> setOpen(String merchantId, bool isOpen) async {
    await _firestore.collection(_collection).doc(merchantId).set({
      'isOpen': isOpen,
      'isActive': isOpen,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Writes [MerchantModel.isOpen] / [isActive] from Malaysia operating schedule
  /// (opening + closing + days, overnight supported). No-op if schedule incomplete.
  Future<void> syncOpenStateFromClosingTime(String merchantId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(merchantId).get();
      final data = doc.data();
      if (!doc.exists || data == null) return;

      final merchant = MerchantModel.fromFirestore(data, doc.id);
      final computed = hasValidOperatingSchedule(merchant)
          ? isMerchantOpenNowMalaysia(merchant)
          : null;
      if (computed == null) return;

      final legacyActive = data['isActive'] as bool?;
      if (merchant.isOpen == computed && legacyActive == computed) return;

      await doc.reference.update({
        'isOpen': computed,
        'isActive': computed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      debugPrint('[MerchantService] syncOpenStateFromClosingTime($merchantId) failed: $e\n$st');
    }
  }

  /// Best-effort sync for many merchants (e.g. after catalog / merchant list load).
  Future<void> syncOpenStateForMerchantIds(Set<String> ids) async {
    for (final id in ids) {
      if (id.isEmpty) continue;
      try {
        await syncOpenStateFromClosingTime(id);
      } catch (e) {
        debugPrint('[MerchantService] syncOpenStateForMerchantIds skip $id: $e');
      }
    }
  }

  /// Delete merchant
  Future<void> deleteMerchant(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}

