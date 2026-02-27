import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/services/auth_token_provider.dart';

void main() {
  group('AuthTokenProvider', () {
    test('interface can be implemented', () {
      expect(() => _TestAuthTokenProvider(), returnsNormally);
    });

    test('getToken returns Future<String?>', () async {
      final provider = _TestAuthTokenProvider();

      final token = await provider.getToken();

      expect(token, isNull);
    });

    test('setToken accepts String', () async {
      final provider = _TestAuthTokenProvider();

      await expectLater(provider.setToken('Bearer abc123'), completes);
    });

    test('clearToken returns Future<void>', () async {
      final provider = _TestAuthTokenProvider();

      await expectLater(provider.clearToken(), completes);
    });

    test('isAuthenticated returns Future<bool>', () async {
      final provider = _TestAuthTokenProvider();

      final isAuth = await provider.isAuthenticated();

      expect(isAuth, isA<bool>());
    });
  });
}

class _TestAuthTokenProvider implements AuthTokenProvider {
  String? _token;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> setToken(String token) async {
    _token = token;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
  }

  @override
  Future<bool> isAuthenticated() async => _token != null;
}
