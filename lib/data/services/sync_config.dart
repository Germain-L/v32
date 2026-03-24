/// Configuration for the sync service.
/// These values should be updated with your actual deployment details.
class SyncConfig {
  /// Backend URL (without trailing slash).
  /// Example: 'https://v32.gmn.lan' or 'http://192.168.1.100:8080'
  static const String baseUrl = String.fromEnvironment(
    'SYNC_URL',
    defaultValue: 'http://v32.gmn.lan',
  );
  
  /// API key for authentication.
  /// This should match the key set in the Kubernetes secret.
  static const String apiKey = String.fromEnvironment(
    'SYNC_API_KEY',
    defaultValue: 'v32_sk_d7f3a9c2e8b1f4d6a5c3e9f0b2d8a7c1',
  );
  
  /// Whether sync is enabled.
  /// Set to false to disable all sync operations.
  static const bool enabled = bool.fromEnvironment(
    'SYNC_ENABLED',
    defaultValue: true,
  );
}
