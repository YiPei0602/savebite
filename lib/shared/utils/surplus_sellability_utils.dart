import 'package:savebite/features/marketplace_surplus/domain/models/food_item_model.dart';

/// Purchasable only when listing is active, in stock, and before [closingTime].
/// Store schedule is not consulted here — [FoodItemModel.closingTime] is the only
/// runtime end time (derived from store hours at listing create/edit).
bool isSurplusSellableToConsumer(
  FoodItemModel item,
  DateTime now,
) {
  if (!item.isConsumerVisibleNow(now)) return false;
  if (item.stock <= 0 || !item.isAvailable) return false;
  return true;
}

/// Consumer UI: greyed card + "Unavailable" when not sellable by time/status
/// or when the merchant store is closed (Malaysia closing rule / [merchantStoreOpen]).
bool isConsumerListingUnavailableForDisplay(
  FoodItemModel item,
  DateTime now, {
  bool merchantStoreOpen = true,
}) {
  return !isSurplusSellableToConsumer(item, now) || !merchantStoreOpen;
}
