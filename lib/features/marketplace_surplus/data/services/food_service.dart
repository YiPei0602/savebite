import 'dart:async';
import 'dart:math' show max;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/food_item_model.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/merchant_model.dart';
import 'package:savebite/shared/utils/firestore_timestamp_utils.dart';
import 'package:savebite/shared/utils/merchant_schedule_utils.dart';

/// Food Service
///
/// Handles food item operations.
/// Firebase-backed implementation (Firestore + optional Storage image upload).
class FoodService {
  // Singleton pattern
  static final FoodService _instance = FoodService._internal();
  factory FoodService() => _instance;
  FoodService._internal();

  static const String _collection = 'food_items';
  static const String _merchantCollection = 'merchants';
  static const String _storageBucket =
      'gs://savebite-1fd01.firebasestorage.app';
  static const String _storageBucketFallback =
      'gs://savebite-1fd01.appspot.com';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage =
      FirebaseStorage.instanceFor(bucket: _storageBucket);
  // Image upload requires Firebase Storage (may require Blaze billing).
  bool get _isStorageUploadEnabled => true;

  static const int _consumerFetchCap = 120;

  /// Consumer catalog: newest first; only [ListingStatus.active] (includes legacy docs
  /// without `status`, parsed as active). Fetches extra rows then filters so inactive
  /// listings do not crowd out active ones within the limit.
  Future<List<FoodItemModel>> getAllFoodItems() async {
    final now = DateTime.now();
    final snap = await _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(_consumerFetchCap)
        .get();
    final merchantIds = snap.docs
        .map((d) => d.data()['merchantId'] as String?)
        .whereType<String>()
        .toSet();
    final merchants = await _fetchMerchantsByIds(merchantIds);
    await _expireActivePastClosingInDocs(snap.docs, now, merchants);
    final active = snap.docs
        .map((d) => _fromDocForConsumerCatalog(d, now, merchants: merchants))
        .where((item) => item.isConsumerVisibleNow(now))
        .toList(growable: true)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return active.take(80).toList(growable: false);
  }

  /// Realtime consumer catalog stream (effective availability includes reserved stock).
  Stream<List<FoodItemModel>> watchAllFoodItems() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(_consumerFetchCap)
        .snapshots()
        .asyncMap((snap) async {
      final now = DateTime.now();
      final merchantIds = snap.docs
          .map((d) => d.data()['merchantId'] as String?)
          .whereType<String>()
          .toSet();
      final merchants = await _fetchMerchantsByIds(merchantIds);
      await _expireActivePastClosingInDocs(snap.docs, now, merchants);
      final active = snap.docs
          .map((d) => _fromDocForConsumerCatalog(d, now, merchants: merchants))
          .where((item) => item.isConsumerVisibleNow(now))
          .toList(growable: true)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return active.take(80).toList(growable: false);
    });
  }

  /// Get food items by category
  ///
  /// TODO: Replace with Firebase Firestore query
  Future<List<FoodItemModel>> getFoodItemsByCategory(
    FoodCategory category,
  ) async {
    final now = DateTime.now();
    final snap = await _firestore
        .collection(_collection)
        .where('category', isEqualTo: category.name)
        .limit(_consumerFetchCap)
        .get();
    final merchantIds = snap.docs
        .map((d) => d.data()['merchantId'] as String?)
        .whereType<String>()
        .toSet();
    final merchants = await _fetchMerchantsByIds(merchantIds);
    await _expireActivePastClosingInDocs(snap.docs, now, merchants);
    final items = snap.docs
        .map((d) => _fromDocForConsumerCatalog(d, now, merchants: merchants))
        .where((item) => item.isConsumerVisibleNow(now))
        .toList(growable: true)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(80).toList(growable: false);
  }

  /// Get food items by merchant
  ///
  /// TODO: Replace with Firebase Firestore query
  Future<List<FoodItemModel>> getFoodItemsByMerchant(String merchantId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('merchantId', isEqualTo: merchantId)
        .limit(80)
        .get();
    final items = snap.docs.map(_fromDoc).toList(growable: false);
    final sorted = items.toList(growable: true)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Search food items
  ///
  /// TODO: Replace with Firebase Firestore query or Algolia
  Future<List<FoodItemModel>> searchFoodItems(String query) async {
    final lowerQuery = query.toLowerCase();
    final all = await getAllFoodItems();
    return all.where((item) {
      return item.name.toLowerCase().contains(lowerQuery) ||
          item.merchantName.toLowerCase().contains(lowerQuery) ||
          item.description.toLowerCase().contains(lowerQuery);
    }).toList(growable: false);
  }

  /// Get food item by ID
  ///
  /// TODO: Replace with Firebase Firestore
  Future<FoodItemModel?> getFoodItemById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return _fromDocForConsumerCatalog(doc, DateTime.now());
  }

  /// Create new food item (Merchant only)
  ///
  /// TODO: Replace with Firebase Firestore
  Future<FoodItemModel> createFoodItem(
    FoodItemModel item, {
    Uint8List? imageBytes,
    String? imageFileName,
    String? imageContentType,
  }) async {
    final docRef = _firestore.collection(_collection).doc();

    String imageUrl = item.imageUrl;
    if (imageBytes != null && _isStorageUploadEnabled) {
      final ext = _safeImageExtension(imageFileName);
      try {
        imageUrl = await _uploadImageToStorage(
          storage: _storage,
          merchantId: item.merchantId,
          docId: docRef.id,
          ext: ext,
          imageBytes: imageBytes,
          imageContentType: imageContentType,
        );
      } catch (primaryError) {
        debugPrint(
          '[FoodService] Primary bucket upload failed for ${docRef.id}: $primaryError',
        );
        final fallbackStorage =
            FirebaseStorage.instanceFor(bucket: _storageBucketFallback);
        try {
          imageUrl = await _uploadImageToStorage(
            storage: fallbackStorage,
            merchantId: item.merchantId,
            docId: docRef.id,
            ext: ext,
            imageBytes: imageBytes,
            imageContentType: imageContentType,
          );
        } catch (fallbackError) {
          debugPrint(
            '[FoodService] Fallback bucket upload failed for ${docRef.id}: $fallbackError',
          );
          rethrow;
        }
      }
    } else if (imageBytes != null) {
      debugPrint(
        '[FoodService] Storage upload disabled; using fallback image for ${docRef.id}',
      );
    }

    final data = _toFirestore(item,
        id: docRef.id, imageUrl: imageUrl, includeCreatedAt: true);
    debugPrint('[FoodService] Creating Firestore doc ${docRef.id}...');
    try {
      await docRef.set(data).timeout(const Duration(seconds: 12));
      debugPrint('[FoodService] Firestore doc created ${docRef.id}');
    } on TimeoutException {
      debugPrint('[FoodService] Firestore write timeout for ${docRef.id}');
      throw Exception(
        'Firestore write timed out. Check internet connection and Firestore rules.',
      );
    } on FirebaseException catch (e) {
      debugPrint(
        '[FoodService] Firestore write failed for ${docRef.id}: ${e.code} ${e.message}',
      );
      if (e.code == 'permission-denied') {
        throw Exception(
          'Firestore permission denied. Please publish firestore.rules in Firebase Console.',
        );
      }
      throw Exception('Firestore error: ${e.message ?? e.code}');
    }

    return item.copyWith(
      id: docRef.id,
      imageUrl: imageUrl,
      listingStatus: ListingStatus.active,
      createdAt: DateTime.now(),
      updatedAt: null,
    );
  }

  /// Update food item (Merchant only)
  ///
  /// TODO: Replace with Firebase Firestore
  Future<FoodItemModel> updateFoodItem(
    FoodItemModel item, {
    Uint8List? imageBytes,
    String? imageFileName,
    String? imageContentType,
  }) async {
    final docRef = _firestore.collection(_collection).doc(item.id);
    var imageUrl = item.imageUrl;

    if (imageBytes != null) {
      final storage = FirebaseStorage.instance;
      final ext = _safeImageExtension(imageFileName);
      imageUrl = await _uploadImageToStorage(
        storage: storage,
        merchantId: item.merchantId,
        docId: item.id,
        ext: ext,
        imageBytes: imageBytes,
        imageContentType: imageContentType,
      );
    }

    await docRef.update({
      ..._toFirestore(item,
          id: item.id, imageUrl: imageUrl, includeCreatedAt: false),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return item.copyWith(imageUrl: imageUrl, updatedAt: DateTime.now());
  }

  /// Delete food item (Merchant only)
  ///
  /// TODO: Replace with Firebase Firestore
  Future<void> deleteFoodItem(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Update stock quantity
  ///
  /// TODO: Replace with Firebase Firestore transaction
  Future<void> updateStock(String id, int newStock) async {
    await _firestore.collection(_collection).doc(id).update({
      'stock': newStock,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// When [now] is on or after listing [closingTime], **or** the store session
  /// is closed in Malaysia (schedule + [MerchantModel.isOpen] fallback), sets
  /// [ListingStatus.expired] and
  /// [isAvailable] false. Idempotent.
  Future<void> applyListingLifecycleForMerchant(
    String merchantId, {
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final merchantDoc =
        await _firestore.collection(_merchantCollection).doc(merchantId).get();
    final MerchantModel? merchant =
        merchantDoc.exists && merchantDoc.data() != null
            ? MerchantModel.fromFirestore(merchantDoc.data()!, merchantDoc.id)
            : null;

    final snap = await _firestore
        .collection(_collection)
        .where('merchantId', isEqualTo: merchantId)
        .limit(100)
        .get();

    WriteBatch batch = _firestore.batch();
    var ops = 0;

    Future<void> commitIfNeeded() async {
      if (ops == 0) return;
      await batch.commit();
      batch = _firestore.batch();
      ops = 0;
    }

    for (final doc in snap.docs) {
      final data = doc.data();
      if (!_shouldExpireActiveListing(data, merchant, effectiveNow)) continue;

      batch.update(doc.reference, _expireListingFieldUpdates());
      ops++;
      if (ops >= 450) {
        await commitIfNeeded();
      }
    }
    await commitIfNeeded();
  }

  Map<String, dynamic> _expireListingFieldUpdates() {
    return {
      'status': ListingStatus.expired.name,
      'isAvailable': false,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Active listing should end: past **item** closing, or past **store** closing (Malaysia).
  bool _shouldExpireActiveListing(
    Map<String, dynamic> data,
    MerchantModel? merchant,
    DateTime now,
  ) {
    final status = ListingStatus.fromFirestore(data['status'] as String?);
    if (status != ListingStatus.active) return false;

    if (isListingPastStoreSessionMalaysia(merchant)) {
      return true;
    }

    final closing = dateTimeFromFirestore(data['closingTime']);
    if (closing == null || now.isBefore(closing)) return false;
    return true;
  }

  Future<Map<String, MerchantModel?>> _fetchMerchantsByIds(
      Set<String> ids) async {
    final out = <String, MerchantModel?>{};
    if (ids.isEmpty) return out;
    final list = ids.toList(growable: false);
    for (var i = 0; i < list.length; i += 10) {
      final chunk = list.skip(i).take(10).toList(growable: false);
      final qs = await _firestore
          .collection(_merchantCollection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in qs.docs) {
        out[d.id] = MerchantModel.fromFirestore(d.data(), d.id);
      }
    }
    for (final id in ids) {
      out.putIfAbsent(id, () => null);
    }
    return out;
  }

  /// Writes `expired` for active docs past item closing **or** past store closing (MY).
  Future<void> _expireActivePastClosingInDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    DateTime now,
    Map<String, MerchantModel?> merchants,
  ) async {
    if (docs.isEmpty) return;
    WriteBatch batch = _firestore.batch();
    var ops = 0;

    Future<void> commitIfNeeded() async {
      if (ops == 0) return;
      await batch.commit();
      batch = _firestore.batch();
      ops = 0;
    }

    for (final doc in docs) {
      final data = doc.data();
      final mid = data['merchantId'] as String?;
      final merchant = mid != null ? merchants[mid] : null;
      if (!_shouldExpireActiveListing(data, merchant, now)) continue;

      batch.update(doc.reference, _expireListingFieldUpdates());
      ops++;
      if (ops >= 450) {
        await commitIfNeeded();
      }
    }
    await commitIfNeeded();
  }

  /// Snapshot may be stale after [_expireActivePastClosingInDocs]; align model with effective status.
  FoodItemModel _fromDocForConsumerCatalog(
    DocumentSnapshot<Map<String, dynamic>> doc,
    DateTime now, {
    Map<String, MerchantModel?>? merchants,
  }) {
    final out = _withConsumerAvailableStock(doc);
    if (out.listingStatus != ListingStatus.active) return out;

    final m = merchants?[out.merchantId];
    if (isListingPastStoreSessionMalaysia(m)) {
      return out.copyWith(
          listingStatus: ListingStatus.expired, isAvailable: false);
    }
    if (!now.isBefore(out.closingTime)) {
      return out.copyWith(
          listingStatus: ListingStatus.expired, isAvailable: false);
    }
    return out;
  }

  FoodItemModel _withConsumerAvailableStock(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final item = _fromDoc(doc);
    final physical = (data['stock'] as num?)?.toInt() ?? item.stock;
    final reserved = (data['reservedStock'] as num?)?.toInt() ?? 0;
    return item.copyWith(stock: max(0, physical - reserved));
  }

  /// Marks expired listings as hidden from merchant dashboard (Firestore only; does not delete).
  Future<void> dismissExpiredFromMerchantDashboard(String merchantId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('merchantId', isEqualTo: merchantId)
        .limit(100)
        .get();

    WriteBatch batch = _firestore.batch();
    var ops = 0;

    Future<void> commitIfNeeded() async {
      if (ops == 0) return;
      await batch.commit();
      batch = _firestore.batch();
      ops = 0;
    }

    for (final doc in snap.docs) {
      final data = doc.data();
      final status = ListingStatus.fromFirestore(data['status'] as String?);
      if (status != ListingStatus.expired) continue;
      final dismissed =
          data['dismissedFromMerchantDashboard'] as bool? ?? false;
      if (dismissed) continue;

      batch.update(doc.reference, {
        'dismissedFromMerchantDashboard': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ops++;
      if (ops >= 450) {
        await commitIfNeeded();
      }
    }
    await commitIfNeeded();
  }

  FoodItemModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = dateTimeFromFirestoreWithDefault(data['createdAt']);
    final updatedAt = dateTimeFromFirestore(data['updatedAt']);
    final closingTime = dateTimeFromFirestoreWithDefault(data['closingTime']);

    final categoryStr =
        (data['category'] as String?) ?? FoodCategory.other.name;
    final categoriesStr = (data['categories'] as List<dynamic>?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];
    final categories = categoriesStr
        .map(
          (s) => FoodCategory.values.firstWhere(
            (e) => e.name == s,
            orElse: () => FoodCategory.other,
          ),
        )
        .toList(growable: false);

    final category = FoodCategory.values.firstWhere(
      (e) => e.name == categoryStr,
      orElse: () =>
          categories.isNotEmpty ? categories.first : FoodCategory.other,
    );

    final tags = (data['dietaryTags'] as List<dynamic>?)
            ?.whereType<String>()
            .map((t) => DietaryTag.values.firstWhere(
                  (e) => e.name == t,
                  orElse: () => DietaryTag.none,
                ))
            .toList(growable: false) ??
        const <DietaryTag>[DietaryTag.none];

    final rangeMap = data['discountRange'] as Map<String, dynamic>?;
    final discountRange = rangeMap == null
        ? null
        : DiscountRange(
            minPercent: (rangeMap['minPercent'] as num).toInt(),
            maxPercent: (rangeMap['maxPercent'] as num).toInt(),
          );

    return FoodItemModel(
      id: (data['id'] as String?) ?? doc.id,
      name: (data['name'] as String?) ?? '',
      merchantId: (data['merchantId'] as String?) ?? '',
      merchantName: (data['merchantName'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      originalPrice: ((data['originalPrice'] as num?) ?? 0).toDouble(),
      discountedPrice: ((data['discountedPrice'] as num?) ?? 0).toDouble(),
      discountPercentage: (data['discountPercentage'] as num?)?.toInt() ?? 0,
      discountRange: discountRange,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      category: category,
      categories: categories.isNotEmpty ? categories : <FoodCategory>[category],
      dietaryTags: tags,
      closingTime: closingTime,
      imageUrl: (data['imageUrl'] as String?) ?? '',
      rating: (data['rating'] as num?)?.toDouble(),
      isAvailable: (data['isAvailable'] as bool?) ?? true,
      listingStatus: ListingStatus.fromFirestore(data['status'] as String?),
      dismissedFromMerchantDashboard:
          (data['dismissedFromMerchantDashboard'] as bool?) ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> _toFirestore(
    FoodItemModel item, {
    required String id,
    required String imageUrl,
    bool includeCreatedAt = true,
  }) {
    final map = <String, dynamic>{
      'id': id,
      'name': item.name,
      'merchantId': item.merchantId,
      'merchantName': item.merchantName,
      'description': item.description,
      'originalPrice': item.originalPrice,
      'discountedPrice': item.discountedPrice,
      'discountPercentage': item.discountPercentage,
      'discountRange': item.discountRange == null
          ? null
          : {
              'minPercent': item.discountRange!.minPercent,
              'maxPercent': item.discountRange!.maxPercent,
            },
      'stock': item.stock,
      'category': item.category.name,
      'categories': item.effectiveCategories.map((c) => c.name).toList(),
      'dietaryTags': item.dietaryTags.map((t) => t.name).toList(),
      'closingTime': Timestamp.fromDate(item.closingTime),
      'imageUrl': imageUrl,
      'rating': item.rating,
      'isAvailable': item.isAvailable,
      'status': item.listingStatus.name,
      'dismissedFromMerchantDashboard': item.dismissedFromMerchantDashboard,
    };
    if (includeCreatedAt) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    return map;
  }

  String _safeImageExtension(String? fileName) {
    if (fileName == null) return '.jpg';
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.webp')) return '.webp';
    if (lower.endsWith('.jpeg')) return '.jpeg';
    if (lower.endsWith('.jpg')) return '.jpg';
    return '.jpg';
  }

  String _contentTypeFromExt(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.jpeg':
        return 'image/jpeg';
      case '.jpg':
      default:
        return 'image/jpeg';
    }
  }

  Future<String> _uploadImageToStorage({
    required FirebaseStorage storage,
    required String merchantId,
    required String docId,
    required String ext,
    required Uint8List imageBytes,
    required String? imageContentType,
  }) async {
    debugPrint(
        '[FoodService] Uploading image for $docId to ${storage.ref().bucket}...');
    final ref = storage.ref().child('food_items/$merchantId/$docId$ext');

    try {
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: imageContentType ?? _contentTypeFromExt(ext),
        ),
      );

      // IMPORTANT: handle stream errors, otherwise PlatformException can crash the app
      // as an unhandled async error (seen as "Unable to establish connection on channel").
      final sub = uploadTask.snapshotEvents.listen(
        (snap) {
          if (snap.totalBytes > 0) {
            final pct =
                (snap.bytesTransferred / snap.totalBytes * 100).clamp(0, 100);
            debugPrint(
              '[FoodService] Upload progress $docId: '
              '${snap.bytesTransferred}/${snap.totalBytes} (${pct.toStringAsFixed(0)}%)',
            );
          }
        },
        onError: (Object e, StackTrace st) {
          debugPrint('[FoodService] Upload stream error $docId: $e');
        },
      );

      final snapshot = await uploadTask.timeout(const Duration(seconds: 120));
      await sub.cancel();
      final downloadUrl = await snapshot.ref
          .getDownloadURL()
          .timeout(const Duration(seconds: 20));
      debugPrint('[FoodService] Image uploaded for $docId');
      return downloadUrl;
    } on PlatformException catch (e) {
      debugPrint(
        '[FoodService] Image upload PlatformException for $docId: ${e.code} ${e.message}',
      );
      if (e.code == 'channel-error') {
        throw Exception(
          'Storage plugin channel error. Fully stop the app and do a clean rebuild '
          '(flutter clean, then reinstall iOS pods / rebuild).',
        );
      }
      throw Exception('Storage platform error: ${e.message ?? e.code}');
    } on FirebaseException catch (e) {
      debugPrint(
        '[FoodService] Image upload FirebaseException for $docId: ${e.code} ${e.message}',
      );
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        throw Exception(
          'Storage permission denied. Publish Storage rules to allow uploads to food_items/{merchantUid}/...',
        );
      }
      if (e.code == 'bucket-not-found') {
        throw Exception(
          'Storage bucket not found. Confirm Firebase Storage is enabled and bucket name is correct.',
        );
      }
      throw Exception('Storage error: ${e.message ?? e.code}');
    } catch (e) {
      debugPrint('[FoodService] Image upload failed for $docId: $e');
      if (e is TimeoutException) {
        throw Exception(
          'Image upload timed out. Check Storage rules (and App Check enforcement) in Firebase Console.',
        );
      }
      rethrow;
    }
  }
}
