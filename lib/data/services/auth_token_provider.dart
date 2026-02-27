/// Provides authentication tokens for API requests.
/// Implementations can use secure storage, SharedPreferences, or mock tokens for testing.
abstract class AuthTokenProvider {
  /// Get the current auth token (e.g., "Bearer abc123")
  Future<String?> getToken();

  /// Store a new auth token
  Future<void> setToken(String token);

  /// Clear the auth token (logout)
  Future<void> clearToken();

  /// Check if a token exists
  Future<bool> isAuthenticated();
}
