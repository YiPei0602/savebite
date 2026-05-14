import 'dart:convert';
import 'dart:math' show min;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:savebite/features/orders_payments/domain/models/cart_item_model.dart';
import 'package:savebite/shared/constants/app_constants.dart';

/// Outcome from [StockReservationService.placeCheckoutHoldStrict].
class StockReservationOutcome {
  const StockReservationOutcome._({
    required this.success,
    this.expiresAtUtc,
    this.errorMessage,
  });

  factory StockReservationOutcome.success(DateTime expiresAtUtc) {
    return StockReservationOutcome._(
      success: true,
      expiresAtUtc: expiresAtUtc,
    );
  }

  factory StockReservationOutcome.failure(String message) {
    return StockReservationOutcome._(
      success: false,
      errorMessage: message,
    );
  }

  final bool success;

  /// Server-side reservation end (prefer this over local clock drift).
  final DateTime? expiresAtUtc;
  final String? errorMessage;
}

/// Temporary stock holds for checkout via HTTPS Cloud Functions (Admin SDK).
///
/// See [placeStockReservations] and [releaseStockReservations] in `functions/src/index.ts`.
class StockReservationService {
  StockReservationService._();
  static final StockReservationService instance = StockReservationService._();
  factory StockReservationService() => instance;

  Uri _callableUri(String functionName) {
    final projectId = Firebase.app().options.projectId;
    if (projectId.isEmpty) {
      throw Exception('Firebase project is not configured.');
    }
    return Uri.parse(
      'https://us-central1-$projectId.cloudfunctions.net/$functionName',
    );
  }

  Future<String?> _idToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) return null;
    return token;
  }

  void _logReservationFailure(String where, Object e) {
    if (kDebugMode) {
      debugPrint('[StockReservation] $where: $e');
    }
  }

  Map<String, dynamic> _extractResultMap(Map<String, dynamic> envelope) {
    final err = envelope['error'];
    if (err is Map && err.isNotEmpty) {
      final msg =
          err['message'] as String? ??
          err['details']?.toString() ??
          'Reservation callable returned an error.';
      throw Exception(msg);
    }
    if (!envelope.containsKey('result')) {
      throw Exception(
        'Reservation response missing result (deploy placeStockReservations?).',
      );
    }
    final raw = envelope['result'];
    if (raw is! Map) {
      throw Exception('Reservation response has invalid result shape.');
    }
    return Map<String, dynamic>.from(raw);
  }

  /// Applies a checkout hold server-side (required before checkout proceeds).
  /// Returns [expiresAtUtc] from callable when successful.
  Future<StockReservationOutcome> placeCheckoutHoldStrict(
    List<CartItemModel> items, {
    int ttlMinutes = AppConstants.stockReservationTtlMinutes,
  }) async {
    if (items.isEmpty) {
      return StockReservationOutcome.failure('Your cart is empty.');
    }

    try {
      final token = await _idToken();
      if (token == null) {
        return StockReservationOutcome.failure(
          'Your session expired. Please sign in again.',
        );
      }

      final url = _callableUri('placeStockReservations');
      final payload = {
        'items': items
            .map(
              (e) => <String, dynamic>{
                'foodItemId': e.foodItem.id,
                'quantity': e.quantity,
              },
            )
            .toList(growable: false),
        'ttlMinutes': ttlMinutes,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'data': payload}),
      );

      final raw = response.body.trimLeft();
      if (response.statusCode != 200) {
        final preview = raw.length > 160 ? '${raw.substring(0, 160)}…' : raw;
        return StockReservationOutcome.failure(
          'Could not reserve items (HTTP ${response.statusCode}'
          '${preview.isNotEmpty ? ': $preview' : ''}).',
        );
      }

      Map<String, dynamic> envelope;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) {
          throw FormatException('Top-level JSON is not an object.');
        }
        envelope = Map<String, dynamic>.from(decoded);
      } on FormatException catch (e) {
        final snippet = raw.length > min(100, raw.length)
            ? raw.substring(0, min(100, raw.length))
            : raw;
        return StockReservationOutcome.failure(
          'Reservation service unreachable or not deployed (${e.message}).'
          '${snippet.isNotEmpty ? ' ($snippet…)' : ''}',
        );
      }

      Map<String, dynamic> resultMap;
      try {
        resultMap = _extractResultMap(envelope);
      } on Exception catch (e) {
        return StockReservationOutcome.failure('$e');
      }

      DateTime expiresAtUtc;
      final ms = resultMap['expiresAt'];
      if (ms is num) {
        expiresAtUtc =
            DateTime.fromMillisecondsSinceEpoch(ms.toInt(), isUtc: true);
      } else {
        expiresAtUtc = DateTime.now().toUtc().add(
              Duration(minutes: ttlMinutes),
            );
      }
      return StockReservationOutcome.success(expiresAtUtc);
    } catch (e, st) {
      _logReservationFailure('placeCheckoutHoldStrict', e);
      if (kDebugMode) {
        debugPrint('$st');
      }
      return StockReservationOutcome.failure(
        'Could not reserve items. ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  /// Optional manual release — not invoked when user leaves checkout (release on timeout instead).
  Future<void> releaseCheckoutHold() async {
    try {
      final token = await _idToken();
      if (token == null) return;

      final url = _callableUri('releaseStockReservations');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'data': <String, dynamic>{}}),
      );

      if (response.statusCode != 200) return;

      final raw = response.body.trimLeft();
      Map<String, dynamic> envelope;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) return;
        envelope = Map<String, dynamic>.from(decoded);
      } on FormatException {
        return;
      }

      try {
        _extractResultMap(envelope);
      } catch (_) {}
    } catch (e) {
      _logReservationFailure('releaseCheckoutHold', e);
    }
  }
}
