import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/infrastructure/api/api_client.dart';

ApiClient client(MockClientHandler handler, {String? token = 'tok'}) =>
    ApiClient(
      baseUrl: 'http://server',
      tokenProvider: () async => token,
      httpClient: MockClient(handler),
    );

http.Response json(Object body, int status) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

void main() {
  group('login', () {
    test('returns the session data on success', () async {
      final api = client((req) async {
        expect(req.url.path, '/auth/login');
        expect(jsonDecode(req.body), {'username': 'asha', 'password': 'pw'});
        return json({
          'access_token': 't1',
          'username': 'asha',
          'role': 'asha_worker',
          'full_name': 'Demo',
        }, 200);
      }, token: null);

      final data = await api.login(username: 'asha', password: 'pw');

      expect(data['access_token'], 't1');
      expect(data['role'], 'asha_worker');
    });

    test('wrong credentials keep the server message (not "login required")',
        () async {
      final api = client(
          (_) async => json({'detail': 'Invalid username or password'}, 401));

      expect(
        () => api.login(username: 'a', password: 'b'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'status', 401)
            .having((e) => e.detail, 'detail', 'Invalid username or password')),
      );
    });

    test('unreachable server is a NetworkException', () async {
      final api = client((_) async => throw const SocketException('down'));

      expect(() => api.login(username: 'a', password: 'b'),
          throwsA(isA<NetworkException>()));
    });
  });

  group('isSessionValid', () {
    test('true when the server accepts the token', () async {
      final api = client((req) async {
        expect(req.headers['Authorization'], 'Bearer tok');
        return json({'username': 'asha', 'role': 'asha_worker'}, 200);
      });
      expect(await api.isSessionValid(), isTrue);
    });

    test('false when the token is rejected', () async {
      final api = client((_) async => json({'detail': 'Token has expired'}, 401));
      expect(await api.isSessionValid(), isFalse);
    });

    test('offline is reported, not treated as invalid', () async {
      final api = client((_) async => throw const SocketException('down'));
      expect(api.isSessionValid, throwsA(isA<NetworkException>()));
    });
  });
}
