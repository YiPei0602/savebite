/// Google Places Web Service API key (server key or restricted browser key).
///
/// Prefer `--dart-define=GOOGLE_PLACES_API_KEY=your_key` for local/dev.
/// Restrict the key in Google Cloud Console (HTTP referrers / app restrictions).
abstract final class GooglePlacesApiKey {
  static const String value = String.fromEnvironment(
     'GOOGLE_PLACES_API_KEY',
    defaultValue: '',
  );
}
