/// Keys used by checkout UI and Firestore `paymentMethod` (matches [PaymentMethod] names).
abstract final class CheckoutPaymentMethodKey {
  static const String card = 'card';
  static const String ewallet = 'ewallet';
  static const String onlineBanking = 'onlineBanking';
}
