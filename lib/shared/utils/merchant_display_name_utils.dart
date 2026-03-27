import 'package:savebite/features/marketplace_surplus/domain/models/merchant_model.dart';

/// Consumer-facing shop title: always prefer the store profile name from Firestore.
String consumerShopDisplayName({
  required String merchantId,
  MerchantModel? merchantProfile,
  String? fromFoodItem,
}) {
  final profile = merchantProfile?.name.trim();
  if (profile != null && profile.isNotEmpty) return profile;

  final fromItem = fromFoodItem?.trim();
  if (fromItem != null && fromItem.isNotEmpty) {
    if (!_isLikelyRawMerchantIdLabel(fromItem, merchantId)) return fromItem;
  }

  return 'Store';
}

bool _isLikelyRawMerchantIdLabel(String text, String merchantId) {
  if (text == merchantId) return true;
  final lower = text.toLowerCase();
  if (lower.startsWith('merchant ') && text.contains(merchantId)) return true;
  return false;
}
