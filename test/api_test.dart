import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ankidsa/services/api_service.dart';

void main() {
  test('expired credentials notify the session and preserve a readable error',
      () async {
    var expired = false;
    final api = ApiService(
        token: 'expired',
        onUnauthorized: () => expired = true,
        client: MockClient((req) async {
          expect(req.headers['Authorization'], 'Bearer expired');
          return http.Response('{"message":"Sign in again"}', 401);
        }));
    await expectLater(api.getStats(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)));
    expect(expired, isTrue);
    api.dispose();
  });
  test('non-JSON gateway failures do not leak parser errors', () async {
    final api = ApiService(
        client: MockClient(
            (_) async => http.Response('<html>Bad gateway</html>', 502)));
    await expectLater(
        api.getStats(),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', contains('server'))));
    api.dispose();
  });
  test('saving edits sends the observed version and preserves multiline notes',
      () async {
    final api = ApiService(
        token: 'session',
        client: MockClient((req) async {
          expect(req.method, 'PUT');
          expect(req.url.path, '/api/problems/3');
          final body = jsonDecode(req.body);
          expect(body['version'], 2);
          expect(body['notes'], 'First line\nSecond line');
          return http.Response(
              jsonEncode({
                'id': 3,
                'version': 3,
                'title': 'Two Sum',
                'difficulty': 'EASY',
                'tags': []
              }),
              200);
        }));
    final result = await api
        .saveProblem({'version': 2, 'notes': 'First line\nSecond line'}, id: 3);
    expect(result.version, 3);
    api.dispose();
  });
}
