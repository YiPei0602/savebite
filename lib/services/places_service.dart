import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:savebite/core/config/google_places_api_key.dart';

/// Single prediction from [PlacesService.fetchSuggestions].
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.description,
    required this.placeId,
  });

  final String description;
  final String placeId;
}

/// Result of [PlacesService.getPlaceDetails].
class PlaceDetailsResult {
  const PlaceDetailsResult({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.placeId,
  });

  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String placeId;
}

/// Thrown when the Places HTTP API returns an error or unexpected payload.
class PlacesApiException implements Exception {
  PlacesApiException(this.message);
  final String message;

  @override
  String toString() => 'PlacesApiException: $message';
}

/// Google Places Web Service (legacy JSON): Autocomplete + Place Details.
///
/// Docs: https://developers.google.com/maps/documentation/places/web-service/overview
///
/// Endpoints used:
/// - `.../place/autocomplete/json`
/// - `.../place/details/json`
class PlacesService {
  PlacesService({http.Client? httpClient, String? apiKey})
      : _client = httpClient ?? http.Client(),
        _apiKey = apiKey ?? GooglePlacesApiKey.value;

  static const String _host = 'maps.googleapis.com';
  static const String _autocompletePath = '/maps/api/place/autocomplete/json';
  static const String _detailsPath = '/maps/api/place/details/json';

  final http.Client _client;
  final String _apiKey;

  void _assertKey() {
    if (_apiKey.isEmpty) {
      throw PlacesApiException(
        'Missing Google Places API key. Pass PlacesService(apiKey: ...) or '
        'build with --dart-define=GOOGLE_PLACES_API_KEY=...',
      );
    }
  }

  /// Calls Place Autocomplete; returns [PlaceSuggestion] list (description + placeId).
  Future<List<PlaceSuggestion>> fetchSuggestions(String input) async {
    final q = input.trim();
    if (q.length < 2) return const [];

    _assertKey();

    final uri = Uri.https(_host, _autocompletePath, <String, String>{
      'input': q,
      'key': _apiKey,
      'components': 'country:my',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw PlacesApiException(
        'Autocomplete HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final status = json['status'] as String? ?? 'UNKNOWN';
    if (status == 'ZERO_RESULTS') return const [];
    if (status != 'OK') {
      final err = json['error_message'] as String?;
      throw PlacesApiException(
        err ?? 'Autocomplete failed: status=$status',
      );
    }

    final predictions = json['predictions'] as List<dynamic>? ?? const [];
    return predictions.map((raw) {
      final m = raw as Map<String, dynamic>;
      return PlaceSuggestion(
        description: (m['description'] as String?)?.trim() ?? '',
        placeId: (m['place_id'] as String?)?.trim() ?? '',
      );
    }).where((s) => s.placeId.isNotEmpty && s.description.isNotEmpty).toList(
          growable: false,
        );
  }

  /// Returns formatted address, lat/lng, and place id for [placeId].
  Future<PlaceDetailsResult> getPlaceDetails(String placeId) async {
    final id = placeId.trim();
    if (id.isEmpty) {
      throw PlacesApiException('placeId is empty');
    }

    _assertKey();

    final uri = Uri.https(_host, _detailsPath, <String, String>{
      'place_id': id,
      'key': _apiKey,
      'fields': 'formatted_address,geometry/location,place_id',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw PlacesApiException(
        'Place Details HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final status = json['status'] as String? ?? 'UNKNOWN';
    if (status != 'OK') {
      final err = json['error_message'] as String?;
      throw PlacesApiException(
        err ?? 'Place Details failed: status=$status',
      );
    }

    final result = json['result'] as Map<String, dynamic>?;
    if (result == null) {
      throw PlacesApiException('Place Details: missing result');
    }

    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble();
    final lng = (location?['lng'] as num?)?.toDouble();

    if (lat == null || lng == null) {
      throw PlacesApiException('Place Details: missing coordinates');
    }

    final formatted =
        (result['formatted_address'] as String?)?.trim() ?? '';
    final outPlaceId = (result['place_id'] as String?)?.trim() ?? id;

    if (formatted.isEmpty) {
      throw PlacesApiException('Place Details: missing formatted_address');
    }

    return PlaceDetailsResult(
      formattedAddress: formatted,
      latitude: lat,
      longitude: lng,
      placeId: outPlaceId,
    );
  }

  void dispose() {
    _client.close();
  }
}
