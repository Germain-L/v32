/// Configuration for the sync service.
/// These values should be updated with your actual deployment details.
class SyncConfig {
  /// Backend URL (without trailing slash).
  static const String baseUrl = String.fromEnvironment(
    'SYNC_URL',
    defaultValue: '',
  );

  /// API key for authentication.
  static const String apiKey = String.fromEnvironment(
    'SYNC_API_KEY',
    defaultValue: '',
  );

  /// Whether sync is enabled.
  static const bool enabled = bool.fromEnvironment(
    'SYNC_ENABLED',
    defaultValue: false,
  );

  static const bool hasCredentials = baseUrl != '' && apiKey != '';
}
