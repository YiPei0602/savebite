import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide PaymentMethod;
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/orders_payments/data/services/stock_reservation_service.dart';
import 'package:savebite/features/orders_payments/domain/payment_checkout_args.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/shared/utils/order_customer_name_utils.dart';
import 'package:savebite/features/orders_payments/domain/models/order_model.dart';
import 'package:savebite/features/orders_payments/presentation/widgets/checkout_reservation_ui.dart';
import 'package:savebite/features/orders_payments/presentation/widgets/order_placed_success_dialog.dart';
import 'package:savebite/features/orders_payments/state/providers/cart_provider.dart';
import 'package:savebite/features/orders_payments/state/providers/order_provider.dart';

/// Stripe card (CardField + confirmPayment); order is created only after payment succeeds.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.args});

  final PaymentCheckoutArgs args;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _busy = false;
  bool _cardComplete = false;
  bool _orderPlaced = false;

  late DateTime _reservationExpiresUtc;
  Timer? _reservationTicker;
  bool _reservationExpiredHandled = false;

  PaymentCheckoutArgs get args => widget.args;

  @override
  void initState() {
    super.initState();
    _reservationExpiresUtc = widget.args.reservationExpiresAt.toUtc();
    if (checkoutReservationExpired(_reservationExpiresUtc)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleReservationExpiry();
        }
      });
      return;
    }
    _reservationTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _reservationExpiredHandled) return;
      if (checkoutReservationExpired(_reservationExpiresUtc)) {
        _handleReservationExpiry();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _stopReservationTicker();
    super.dispose();
  }

  void _stopReservationTicker() {
    _reservationTicker?.cancel();
    _reservationTicker = null;
  }

  /// Reservation is consumed once payment succeeds — stop countdown permanently.
  void _finalizeReservationAfterPayment() {
    if (_orderPlaced) return;
    _orderPlaced = true;
    _reservationExpiredHandled = true;
    _stopReservationTicker();
    if (mounted) setState(() {});
  }

  Future<void> _handleReservationExpiry() async {
    if (_orderPlaced || _reservationExpiredHandled) return;
    _reservationExpiredHandled = true;
    _stopReservationTicker();
    if (!mounted) return;
    setState(() {});
    await showReservationExpiredDialog(context);
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _onPaymentBackRequested() async {
    if (_orderPlaced) {
      context.pop(true);
      return;
    }
    if (_reservationExpiredHandled) return;
    final leave = await showLeaveCheckoutDialog(context);
    if (!mounted) return;
    if (leave) {
      context.go('/home');
    }
  }

  bool get _paymentBlocked =>
      _orderPlaced ||
      _reservationExpiredHandled ||
      checkoutReservationExpired(_reservationExpiresUtc);

  static String _paymentMethodLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.ewallet:
        return 'E-Wallet';
      case PaymentMethod.onlineBanking:
        return 'Online banking';
      case PaymentMethod.cash:
        return 'Cash';
    }
  }

  int get _amountCents {
    final cents = (args.totalPrice * 100).round();
    return cents < 1 ? 1 : cents;
  }

  /// Step 1: Firebase callable `createPaymentIntent` → Stripe `clientSecret`.
  ///
  /// Uses HTTPS callable protocol (same as `cloud_functions`) so this screen
  /// does not depend on `package:cloud_functions` — avoids IDE/analysis issues
  /// when the package graph is not resolved.
  Future<String> _createPaymentIntentClientSecret() async {
    final auth = FirebaseAuth.instance;
    await auth.authStateChanges().first;

    var firebaseUser = auth.currentUser;
    if (kDebugMode) {
      debugPrint(
        '[Payment] after authStateChanges.first: '
        'currentUser=${firebaseUser != null ? "set" : "null"} '
        'uid=${firebaseUser?.uid}',
      );
    }

    if (firebaseUser == null) {
      throw Exception(
        'Your session expired. Please sign out and sign in again, then retry payment.',
      );
    }

    final token = await firebaseUser.getIdToken(true);
    if (kDebugMode) {
      final prefix = token == null || token.length < 28
          ? token
          : '${token.substring(0, 24)}…';
      debugPrint(
        '[Payment] getIdToken(forceRefresh): '
        'len=${token?.length ?? 0} prefix=$prefix',
      );
    }

    if (token == null || token.isEmpty) {
      throw Exception(
        'Your session expired. Please sign out and sign in again, then retry payment.',
      );
    }

    final projectId = Firebase.app().options.projectId;
    if (projectId.isEmpty) {
      throw Exception('Firebase project is not configured.');
    }

    final url = Uri.parse(
      'https://us-central1-$projectId.cloudfunctions.net/createPaymentIntent',
    );
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'data': <String, dynamic>{'amount': _amountCents},
      }),
    );

    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw Exception('Invalid response from payment server.');
      }
      body = Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw Exception('Invalid response from payment server.');
    }

    final err = body['error'];
    if (err is Map) {
      final errMap = Map<String, dynamic>.from(err);
      final status = (errMap['status'] as String? ?? '').toLowerCase();
      final message =
          errMap['message'] as String? ?? 'Could not start payment.';
      throw FirebaseException(
        plugin: 'firebase_functions',
        message: message,
        code: status.isEmpty ? 'functions-error' : status,
      );
    }

    final raw = body['result'];
    if (raw is! Map) {
      throw Exception('Invalid response from payment server.');
    }
    final map = Map<String, dynamic>.from(raw);
    final secret = map['clientSecret'] as String?;
    if (secret == null || secret.isEmpty) {
      throw Exception('Missing payment client secret.');
    }
    if (kDebugMode) {
      debugPrint('[Payment] createPaymentIntent OK');
    }
    return secret;
  }

  Future<void> _showError(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// True when the intent is paid or authorized enough to persist an order.
  /// (Strict [Succeeded] alone blocked Firestore when the SDK returned
  /// [Processing] or [RequiresCapture], or after multi-step 3DS.)
  bool _paymentIntentAllowsOrder(PaymentIntent pi) {
    switch (pi.status) {
      case PaymentIntentsStatus.Succeeded:
      case PaymentIntentsStatus.Processing:
      case PaymentIntentsStatus.RequiresCapture:
        return true;
      case PaymentIntentsStatus.RequiresPaymentMethod:
      case PaymentIntentsStatus.RequiresConfirmation:
      case PaymentIntentsStatus.Canceled:
      case PaymentIntentsStatus.RequiresAction:
      case PaymentIntentsStatus.Unknown:
        return false;
    }
  }

  Future<void> _onPayWithStripe() async {
    if (_busy) return;
    if (!_cardComplete) {
      await _showError('Please enter a complete card number.');
      return;
    }
    if (_paymentBlocked) {
      await _showError(
        'Reservation expired. Please place your order again from the marketplace.',
      );
      return;
    }

    PaymentIntent? successfulIntent;

    setState(() => _busy = true);

    try {
      final refreshed =
          await StockReservationService().placeCheckoutHoldStrict(args.items);
      if (!mounted) return;
      if (!refreshed.success || refreshed.expiresAtUtc == null) {
        setState(() => _busy = false);
        await _showError(
          refreshed.errorMessage ??
              'Could not refresh reservation. Try again shortly.',
        );
        return;
      }
      _reservationExpiresUtc = refreshed.expiresAtUtc!;

      final clientSecret = await _createPaymentIntentClientSecret();

      var paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      var guard = 0;
      while (paymentIntent.status == PaymentIntentsStatus.RequiresAction &&
          guard < 8) {
        guard++;
        paymentIntent = await Stripe.instance.handleNextAction(
          clientSecret,
          returnURL: 'savebite://stripe-redirect',
        );
      }

      if (kDebugMode) {
        debugPrint(
          '[Payment] PaymentIntent status after confirm/nextAction: '
          '${paymentIntent.status}',
        );
      }

      if (!_paymentIntentAllowsOrder(paymentIntent)) {
        await _showError('Payment could not be completed.');
        if (!mounted) return;
        setState(() => _busy = false);
        return;
      }

      successfulIntent = paymentIntent;
    } on StripeException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      final code = e.error.code;
      if (code == FailureCode.Canceled) {
        await _showError('Payment was cancelled.');
        return;
      }
      await _showError(
        e.error.localizedMessage ??
            e.error.message ??
            'Payment could not be completed.',
      );
      return;
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _busy = false);

      if (e is FirebaseException && e.plugin == 'firebase_functions') {
        if (kDebugMode) {
          debugPrint(
            '[Payment] FirebaseFunctions code=${e.code} '
            'message=${e.message} stack=$st',
          );
        }
        final msg = e.code.toLowerCase() == 'unauthenticated'
            ? 'Please sign in again. Payment requires an active account session.'
            : (e.message ?? 'Could not start payment. Check your connection.');
        await _showError(msg);
        return;
      }

      final msg = e.toString().replaceFirst('Exception: ', '');
      await _showError(
        msg.isEmpty ? 'Something went wrong. Please try again.' : msg,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _busy = false);

    await _completeOrderAfterPayment(
      context,
      stripePaymentIntentId: successfulIntent?.id,
    );
  }

  Future<void> _completeOrderAfterPayment(
    BuildContext context, {
    String? stripePaymentIntentId,
  }) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final orderProvider = context.read<OrderProvider>();
    final cartProvider = context.read<CartProvider>();
    final customerName = args.customerName?.trim().isNotEmpty == true
        ? args.customerName!.trim()
        : customerNameFromUser(context.read<AuthProvider>().currentUser);

    try {
      final order = await orderProvider.createOrder(
        userId: args.userId,
        merchantId: args.merchantId,
        merchantName: args.merchantName,
        customerName: customerName,
        items: args.items,
        subtotal: args.subtotal,
        serviceFee: args.serviceFee,
        deliveryFee: args.deliveryFee,
        totalPrice: args.totalPrice,
        totalSavings: args.totalSavings,
        fulfillmentType: args.fulfillmentType,
        paymentMethod: args.paymentMethod,
        paymentStatus: PaymentStatus.paid,
        deliveryAddress: args.deliveryAddress,
        pickupAddress: args.pickupAddress,
        deliveryLatitude: args.deliveryLatitude,
        deliveryLongitude: args.deliveryLongitude,
        deliveryPlaceId: args.deliveryPlaceId,
        stripePaymentIntentId: stripePaymentIntentId,
      );

      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (order == null) {
        final msg = orderProvider.errorMessage ??
            'Payment succeeded but the order could not be saved. Contact support.';
        await _showError(msg);
        return;
      }

      _finalizeReservationAfterPayment();
      cartProvider.clearCart();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });

      await showOrderPlacedSuccessDialog(
        context: context,
        orderId: order.id,
        onTrackOrder: () {
          Navigator.of(context).pop();
          context.pop(true);
          context.push('/order-tracking/${order.id}');
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      final msg = e.toString().replaceFirst('Exception: ', '');
      await _showError(
        msg.isEmpty
            ? 'Payment succeeded but placing the order failed. Contact support.'
            : msg,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        await _onPaymentBackRequested();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            tooltip: 'Back',
            onPressed: _onPaymentBackRequested,
          ),
          title: Text(
            'Payment',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
          actions: [
            if (!_orderPlaced &&
                !_reservationExpiredHandled)
              Padding(
                padding: const EdgeInsets.only(right: AppConstants.paddingS),
                child: Center(
                  child: ReservationCountdownBadge(
                    expiresAtUtc: _reservationExpiresUtc,
                  ),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Total',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingXS),
              Text(
                '${AppConstants.currencySymbol}${args.totalPrice.toStringAsFixed(2)}',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),
              Text(
                'Checkout preference',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingXS),
              Text(
                _paymentMethodLabel(args.paymentMethod),
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              Text(
                'Enter your card below.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              SizedBox(
                height: 56,
                child: CardField(
                  onCardChanged: (card) {
                    setState(() {
                      _cardComplete = card?.complete ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(height: AppConstants.paddingXL),
              ElevatedButton(
                onPressed: (_busy || !_cardComplete || _paymentBlocked)
                    ? null
                    : () => _onPayWithStripe(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF212121),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.primaryCtaVerticalPadding,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.primaryCtaPillRadius,
                    ),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Pay now',
                        style: AppTypography.buttonMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: AppConstants.paddingM),
            ],
          ),
        ),
      ),
    );
  }
}
