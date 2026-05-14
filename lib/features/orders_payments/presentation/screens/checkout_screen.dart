import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/orders_payments/data/services/stock_reservation_service.dart';
import 'package:savebite/features/orders_payments/domain/checkout_payment_method_key.dart';
import 'package:savebite/features/orders_payments/domain/payment_checkout_args.dart';
import 'package:savebite/features/orders_payments/presentation/widgets/checkout_reservation_ui.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';
import 'package:savebite/features/orders_payments/state/providers/cart_provider.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/merchant_model.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/merchant_provider.dart';
import 'package:savebite/shared/utils/merchant_display_name_utils.dart';
import 'package:savebite/shared/widgets/places_autocomplete_field.dart';

String _normalizeHhMm24(String? raw) {
  if (raw == null) return '';
  final t = raw.trim();
  if (t.isEmpty) return '';
  final p = t.split(':');
  if (p.length < 2) return t;
  final h = int.tryParse(p[0]) ?? 0;
  final min = int.tryParse(p[1]) ?? 0;
  return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
}

/// `Pickup: Today, HH:mm - HH:mm` when both times exist on [m]; otherwise `null`.
String? _pickupTodayLine24(MerchantModel? m) {
  final o = _normalizeHhMm24(m?.openingTime);
  final c = _normalizeHhMm24(m?.closingTime);
  if (o.isEmpty || c.isEmpty) return null;
  return 'Pickup: Today, $o - $c';
}

/// Checkout Screen
///
/// Final step before placing an order.
/// Includes fulfillment method, payment selection, and order summary.
class CheckoutScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>>? cartItems;
  final double? subtotal;
  final double? totalSavings;

  const CheckoutScreen({
    super.key,
    this.cartItems,
    this.subtotal,
    this.totalSavings,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Fulfillment method: true = Self-Pickup, false = Delivery
  bool _isSelfPickup = true;

  String _selectedPaymentMethod = CheckoutPaymentMethodKey.card;

  final TextEditingController _deliveryAddressController =
      TextEditingController();

  double? _deliveryLat;
  double? _deliveryLng;
  String? _deliveryPlaceId;

  Timer? _reservationTicker;
  bool _reservationLoading = true;
  bool _reservationFailed = false;
  String? _reservationErrorMessage;
  DateTime? _reservationExpiresAtUtc;

  /// True after countdown hits zero; dialogs + redirect triggered.
  bool _reservationExpiredHandled = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrapReservation();
      // Pre-fill text from profile; user must pick a suggestion for coordinates.
      final addr = context.read<AuthProvider>().currentUser?.address?.trim();
      if (addr != null &&
          addr.isNotEmpty &&
          _deliveryAddressController.text.isEmpty) {
        _deliveryAddressController.text = addr;
      }
    });
  }

  @override
  void dispose() {
    _reservationTicker?.cancel();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapReservation() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _reservationLoading = false;
        _reservationFailed = true;
        _reservationErrorMessage = 'Please login again before checkout.';
      });
      return;
    }

    final cartProvider = context.read<CartProvider>();
    if (cartProvider.isEmpty) {
      if (!mounted) return;
      setState(() {
        _reservationLoading = false;
        _reservationFailed = true;
        _reservationErrorMessage = 'Your cart is empty.';
      });
      return;
    }
    if (cartProvider.hasMultipleMerchants) {
      if (!mounted) return;
      setState(() {
        _reservationLoading = false;
        _reservationFailed = true;
        _reservationErrorMessage =
            'Please checkout items from one store at a time.';
      });
      return;
    }

    final outcome = await StockReservationService()
        .placeCheckoutHoldStrict(cartProvider.items);
    if (!mounted) return;
    if (!outcome.success || outcome.expiresAtUtc == null) {
      setState(() {
        _reservationLoading = false;
        _reservationFailed = true;
        _reservationErrorMessage = outcome.errorMessage ??
            'Could not reserve stock for checkout. Try again.';
      });
      return;
    }

    setState(() {
      _reservationLoading = false;
      _reservationFailed = false;
      _reservationErrorMessage = null;
      _reservationExpiresAtUtc = outcome.expiresAtUtc!;
    });
    _startReservationTicker();
  }

  void _startReservationTicker() {
    _reservationTicker?.cancel();
    _reservationTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted ||
          _reservationExpiresAtUtc == null ||
          _reservationExpiredHandled) {
        return;
      }
      if (checkoutReservationExpired(_reservationExpiresAtUtc!)) {
        _fireReservationExpired();
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _fireReservationExpired() async {
    if (_reservationExpiredHandled) return;
    _reservationExpiredHandled = true;
    _reservationTicker?.cancel();
    if (!mounted) return;
    setState(() {});
    await showReservationExpiredDialog(context);
    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _onCheckoutBackRequested() async {
    if (_reservationLoading && !_reservationFailed) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
      return;
    }
    if (_reservationFailed) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
      return;
    }
    if (_reservationExpiredHandled) return;
    final leave = await showLeaveCheckoutDialog(context);
    if (!mounted) return;
    if (leave) {
      context.go('/home');
    }
  }

  bool get _checkoutActionsDisabled =>
      _reservationLoading ||
      _reservationFailed ||
      _reservationExpiredHandled ||
      (_reservationExpiresAtUtc != null &&
          checkoutReservationExpired(_reservationExpiresAtUtc!));

  // Get cart data from provider or widget
  Map<String, Map<String, dynamic>> get _cartItems {
    if (widget.cartItems != null) {
      return widget.cartItems!;
    }
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final merchantProvider =
        Provider.of<MerchantProvider>(context, listen: false);
    MerchantModel? mFor(String id) {
      for (final m in merchantProvider.merchants) {
        if (m.id == id) return m;
      }
      return null;
    }

    final Map<String, Map<String, dynamic>> items = {};
    for (var item in cartProvider.items) {
      items[item.id] = {
        'id': item.id,
        'name': item.foodItem.name,
        'merchantName': consumerShopDisplayName(
          merchantId: item.foodItem.merchantId,
          merchantProfile: mFor(item.foodItem.merchantId),
          fromFoodItem: item.foodItem.merchantName,
        ),
        'imageUrl': item.foodItem.imageUrl,
        'price': item.foodItem.effectiveDiscountedPrice,
        'originalPrice': item.foodItem.originalPrice,
        'quantity': item.quantity,
        'maxQuantity': item.foodItem.stock,
      };
    }
    return items;
  }

  double get _subtotal {
    return widget.subtotal ??
        Provider.of<CartProvider>(context, listen: false).subtotal;
  }

  double get _totalSavings {
    return widget.totalSavings ??
        Provider.of<CartProvider>(context, listen: false).totalSavings;
  }

  double get _total {
    double total = _subtotal;
    if (!_isSelfPickup) {
      total += _deliveryFee;
    }
    return total;
  }

  MerchantModel? _merchantProfileForCart(CartProvider cart) {
    if (cart.isEmpty) return null;
    final merchantId = cart.items.first.foodItem.merchantId;
    for (final m in context.read<MerchantProvider>().merchants) {
      if (m.id == merchantId) return m;
    }
    return null;
  }

  double? get _deliveryDistanceKm {
    if (_isSelfPickup || _deliveryLat == null || _deliveryLng == null) {
      return null;
    }
    final cart = context.read<CartProvider>();
    final merchant = _merchantProfileForCart(cart);
    final merchantLat = merchant?.latitude;
    final merchantLng = merchant?.longitude;
    if (merchantLat == null || merchantLng == null) {
      return null;
    }
    return _haversineKm(
      merchantLat,
      merchantLng,
      _deliveryLat!,
      _deliveryLng!,
    );
  }

  double? get _calculatedDeliveryFee {
    final km = _deliveryDistanceKm;
    if (km == null) return null;
    if (km <= 3) return 2.00;
    if (km <= 5) return 4.00;
    if (km <= 8) return 6.00;
    return 8.00;
  }

  double get _deliveryFee =>
      _isSelfPickup ? 0.0 : (_calculatedDeliveryFee ?? 0.0);

  String? get _deliveryBlockReason {
    if (_isSelfPickup) return null;
    final addr = _deliveryAddressController.text.trim();
    if (addr.isEmpty || _deliveryLat == null || _deliveryLng == null) {
      return 'Please search and select your delivery address from the list.';
    }
    final cart = context.read<CartProvider>();
    final merchant = _merchantProfileForCart(cart);
    if (merchant?.latitude == null || merchant?.longitude == null) {
      return 'Delivery is unavailable because this store location is not configured.';
    }
    return null;
  }

  double _haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;

  PaymentMethod _paymentMethodFromKey(String key) {
    switch (key) {
      case CheckoutPaymentMethodKey.ewallet:
        return PaymentMethod.ewallet;
      case CheckoutPaymentMethodKey.onlineBanking:
        return PaymentMethod.onlineBanking;
      case CheckoutPaymentMethodKey.card:
      default:
        return PaymentMethod.card;
    }
  }

  Future<void> _placeOrder() async {
    if (_checkoutActionsDisabled) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again to place an order.')),
      );
      return;
    }

    final cartProvider = context.read<CartProvider>();
    if (cartProvider.isEmpty) return;

    if (cartProvider.hasMultipleMerchants) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please checkout items from one store at a time.')),
      );
      return;
    }

    if (!_isSelfPickup) {
      final reason = _deliveryBlockReason;
      if (reason != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason)),
        );
        return;
      }
    }

    final holdAgain = await StockReservationService()
        .placeCheckoutHoldStrict(cartProvider.items);
    if (!mounted) return;
    if (!holdAgain.success || holdAgain.expiresAtUtc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            holdAgain.errorMessage ??
                'Could not refresh your reservation. Try again shortly.',
          ),
        ),
      );
      return;
    }
    final reservationExpiryUtc = holdAgain.expiresAtUtc!;
    setState(() {
      _reservationExpiresAtUtc = reservationExpiryUtc;
    });

    if (!mounted) return;
    final first = cartProvider.items.first;
    final merchantId = first.foodItem.merchantId;
    MerchantModel? merchantProfile;
    for (final m in context.read<MerchantProvider>().merchants) {
      if (m.id == merchantId) {
        merchantProfile = m;
        break;
      }
    }
    final merchantName = consumerShopDisplayName(
      merchantId: merchantId,
      merchantProfile: merchantProfile,
      fromFoodItem: first.foodItem.merchantName,
    );

    final snapshotItems = cartProvider.items
        .map(
          (ci) => ci.copyWith(
            foodItem: ci.foodItem.copyWith(
              discountedPrice: ci.foodItem.effectiveDiscountedPrice,
              discountPercentage: ci.foodItem.effectiveDiscountPercentage,
            ),
          ),
        )
        .toList(growable: false);

    final args = PaymentCheckoutArgs(
      userId: userId,
      merchantId: merchantId,
      merchantName: merchantName,
      items: snapshotItems,
      subtotal: _subtotal,
      serviceFee: 0.0,
      deliveryFee: _isSelfPickup ? 0.0 : _deliveryFee,
      totalPrice: _total,
      totalSavings: _totalSavings,
      fulfillmentType:
          _isSelfPickup ? FulfillmentType.pickup : FulfillmentType.delivery,
      paymentMethod: _paymentMethodFromKey(_selectedPaymentMethod),
      paymentMethodLabelKey: _selectedPaymentMethod,
      isSelfPickup: _isSelfPickup,
      cartItemsForTracking: Map<String, Map<String, dynamic>>.from(_cartItems),
      deliveryAddress:
          _isSelfPickup ? null : _deliveryAddressController.text.trim(),
      deliveryLatitude: _isSelfPickup ? null : _deliveryLat,
      deliveryLongitude: _isSelfPickup ? null : _deliveryLng,
      deliveryPlaceId: _isSelfPickup ? null : _deliveryPlaceId,
      pickupAddress: _isSelfPickup
          ? (merchantProfile != null &&
                  merchantProfile.address.trim().isNotEmpty
              ? merchantProfile.address.trim()
              : null)
          : null,
      reservationExpiresAt: reservationExpiryUtc,
    );

    context.push('/payment', extra: args);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        await _onCheckoutBackRequested();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
            tooltip: 'Back',
            onPressed: _onCheckoutBackRequested,
          ),
          title: Text(
            'Checkout',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
          actions: [
            if (!_reservationLoading &&
                !_reservationFailed &&
                !_reservationExpiredHandled &&
                _reservationExpiresAtUtc != null)
              Padding(
                padding: const EdgeInsets.only(right: AppConstants.paddingS),
                child: Center(
                  child: ReservationCountdownBadge(
                    expiresAtUtc: _reservationExpiresAtUtc!,
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFulfillmentSection(),
                        const SizedBox(height: AppConstants.paddingL),
                        _buildOrderSummary(),
                        const SizedBox(height: AppConstants.paddingL),
                        _buildPaymentSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                _buildPlaceOrderButton(),
              ],
            ),
            if (_reservationLoading)
              Positioned.fill(
                child: Material(
                  color: AppColors.overlay,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),
            if (_reservationFailed)
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.background.withOpacity(0.96),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingXL),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _reservationErrorMessage ??
                                'Could not reserve your items.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingL),
                          ElevatedButton(
                            onPressed: () => context.go('/home'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textOnPrimary,
                            ),
                            child: const Text('Return to marketplace'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFulfillmentSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fulfillment Method', style: AppTypography.h4),
            const SizedBox(height: AppConstants.paddingM),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isSelfPickup = true),
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.paddingM,
                      ),
                      decoration: BoxDecoration(
                        color: _isSelfPickup
                            ? const Color(0xFF00695C)
                            : const Color(0xFFE0F2F1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusM),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.store,
                            color: _isSelfPickup
                                ? Colors.white
                                : const Color(0xFF00695C),
                            size: 28,
                          ),
                          const SizedBox(height: AppConstants.paddingXS),
                          Text(
                            'Self-Pickup',
                            style: AppTypography.bodyMedium.copyWith(
                              color: _isSelfPickup
                                  ? Colors.white
                                  : const Color(0xFF00695C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingXS),
                          Text(
                            'Free',
                            style: AppTypography.bodySmall.copyWith(
                              color: _isSelfPickup
                                  ? Colors.white
                                  : const Color(0xFF00695C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingS),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isSelfPickup = false),
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.paddingM,
                      ),
                      decoration: BoxDecoration(
                        color: !_isSelfPickup
                            ? const Color(0xFF00695C)
                            : const Color(0xFFE0F2F1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusM),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.delivery_dining,
                            color: !_isSelfPickup
                                ? Colors.white
                                : const Color(0xFF00695C),
                            size: 28,
                          ),
                          const SizedBox(height: AppConstants.paddingXS),
                          Text(
                            'Delivery',
                            style: AppTypography.bodyMedium.copyWith(
                              color: !_isSelfPickup
                                  ? Colors.white
                                  : const Color(0xFF00695C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingXS),
                          Text(
                            _calculatedDeliveryFee == null
                                ? '${AppConstants.currencySymbol}--'
                                : '${AppConstants.currencySymbol}${_calculatedDeliveryFee!.toStringAsFixed(2)}',
                            style: AppTypography.bodySmall.copyWith(
                              color: !_isSelfPickup
                                  ? Colors.white
                                  : const Color(0xFF00695C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingL),
            if (_isSelfPickup) _buildPickupPointInfo(),
            if (!_isSelfPickup) _buildDeliveryAddressInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupPointInfo() {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.isEmpty) return const SizedBox.shrink();
        final first = cart.items.first;
        final merchantId = first.foodItem.merchantId;
        final merchantProvider = context.read<MerchantProvider>();
        MerchantModel? fromList;
        for (final m in merchantProvider.merchants) {
          if (m.id == merchantId) {
            fromList = m;
            break;
          }
        }
        return StreamBuilder<MerchantModel?>(
          stream: merchantProvider.watchMerchant(merchantId),
          initialData: fromList,
          builder: (context, snapshot) {
            final m = snapshot.data;
            final shopName = consumerShopDisplayName(
              merchantId: merchantId,
              merchantProfile: m,
              fromFoodItem: first.foodItem.merchantName,
            );
            final address = (m?.address ?? '').trim();
            final addressLine =
                address.isNotEmpty ? address : 'Address not set';
            final pickupLine = _pickupTodayLine24(m);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup Location',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingS),
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.store, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppConstants.paddingS),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shopName,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingXS),
                            Text(
                              addressLine,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingS),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: AppConstants.paddingXS),
                    Expanded(
                      child: Text(
                        pickupLine ?? 'Pickup hours unavailable',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDeliveryAddressInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Address',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.paddingXS),
        Text(
          'Search and select your address (Malaysia).',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.paddingS),
        PlacesAutocompleteField(
          controller: _deliveryAddressController,
          hintText: 'Search delivery address',
          onPlaceSelected: (d) {
            setState(() {
              _deliveryLat = d.latitude;
              _deliveryLng = d.longitude;
              _deliveryPlaceId = d.placeId;
            });
          },
          onChanged: (_) {
            setState(() {
              _deliveryLat = null;
              _deliveryLng = null;
              _deliveryPlaceId = null;
            });
          },
        ),
        if (_deliveryLat != null && _deliveryLng != null) ...[
          const SizedBox(height: AppConstants.paddingS),
          _buildDeliveryFeePreview(),
        ],
      ],
    );
  }

  Widget _buildDeliveryFeePreview() {
    final distanceKm = _deliveryDistanceKm;
    final fee = _calculatedDeliveryFee;
    final reason = _deliveryBlockReason;
    if (distanceKm == null || fee == null) {
      return Text(
        reason ?? 'Delivery distance unavailable.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
      );
    }
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingS),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Row(
        children: [
          const Icon(Icons.route, size: 18, color: AppColors.info),
          const SizedBox(width: AppConstants.paddingS),
          Expanded(
            child: Text(
              '${distanceKm.toStringAsFixed(2)} km from store · '
              'Delivery ${AppConstants.currencySymbol}${fee.toStringAsFixed(2)}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Method', style: AppTypography.h4),
            const SizedBox(height: AppConstants.paddingM),
            _buildPaymentOption(
              CheckoutPaymentMethodKey.card,
              'Credit/Debit Card',
              Icons.credit_card,
              'Visa, Mastercard, Amex',
              const Color(0xFF2196F3),
            ),
            const SizedBox(height: AppConstants.paddingS),
            _buildPaymentOption(
              CheckoutPaymentMethodKey.ewallet,
              'E-Wallet',
              Icons.account_balance_wallet,
              'Touch \'n Go, GrabPay, Boost',
              const Color(0xFFFF9800),
            ),
            const SizedBox(height: AppConstants.paddingS),
            _buildPaymentOption(
              CheckoutPaymentMethodKey.onlineBanking,
              'Online Banking',
              Icons.account_balance,
              'Maybank, CIMB, Public Bank',
              const Color(0xFF9C27B0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    IconData icon,
    String subtitle,
    Color accentColor,
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(AppConstants.radiusS),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingS),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withOpacity(0.2)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Icon(
                icon,
                color: isSelected ? accentColor : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? accentColor : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingXS),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? accentColor : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Summary', style: AppTypography.h4),
            const SizedBox(height: AppConstants.paddingM),
            _buildSummaryRow(
              'Subtotal',
              '${AppConstants.currencySymbol}${_subtotal.toStringAsFixed(2)}',
            ),
            if (!_isSelfPickup) ...[
              const SizedBox(height: AppConstants.paddingS),
              if (_deliveryDistanceKm != null)
                _buildSummaryRow(
                  'Delivery Distance',
                  '${_deliveryDistanceKm!.toStringAsFixed(2)} km',
                ),
              if (_deliveryDistanceKm != null)
                const SizedBox(height: AppConstants.paddingS),
              _buildSummaryRow(
                'Delivery Fee',
                _calculatedDeliveryFee == null
                    ? '${AppConstants.currencySymbol}--'
                    : '${AppConstants.currencySymbol}${_calculatedDeliveryFee!.toStringAsFixed(2)}',
              ),
            ],
            const SizedBox(height: AppConstants.paddingS),
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingS),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Savings',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '-${AppConstants.currencySymbol}${_totalSavings.toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            const Divider(),
            const SizedBox(height: AppConstants.paddingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppTypography.h4),
                Text(
                  '${AppConstants.currencySymbol}${_total.toStringAsFixed(2)}',
                  style: AppTypography.h3.copyWith(
                    color: const Color(0xFFFF5722),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: AppConstants.primaryCtaFooterBlockPadding,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checkoutActionsDisabled ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.primaryCtaVerticalPadding,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.primaryCtaPillRadius,
                  ),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 24),
                  const SizedBox(width: AppConstants.paddingS),
                  Text(
                    'Place Order - ${AppConstants.currencySymbol}${_total.toStringAsFixed(2)}',
                    style: AppTypography.buttonMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
