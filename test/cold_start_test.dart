import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ankidsa/services/api_service.dart';

void main() {
  test('cold start retries readiness before sending a mutation exactly once',
      () async {
    var probes = 0, writes = 0;
    final api = ApiService(
        baseUrl: 'https://cold-start.test',
        coldStart: true,
        token: 'session',
        client: MockClient((request) async {
          if (request.url.path == '/ready') {
            expect(request.headers.containsKey('Authorization'), false);
            return http.Response(
                '{"status":"ready"}', ++probes == 1 ? 503 : 200);
          }
          writes++;
          expect(request.method, 'POST');
          return http.Response(jsonEncode({'saved': true}), 200);
        }));
    expect(
        await api.request('/api/problems',
            method: 'POST', body: {'title': 'Two Sum'}),
        {'saved': true});
    expect(probes, 2);
    expect(writes, 1);
    api.dispose();
  });
  test('readiness survives more than three quick unavailable responses',
      () async {
    var probes = 0, writes = 0;
    final api = ApiService(
        baseUrl: 'https://slow-wake.test',
        coldStart: true,
        retryDelay: const Duration(milliseconds: 1),
        client: MockClient((request) async {
          if (request.url.path == '/ready') {
            return http.Response('{}', ++probes < 6 ? 503 : 200);
          }
          writes++;
          return http.Response('{}', 200);
        }));
    await api.request('/api/problems', method: 'POST', body: {});
    expect(probes, 6);
    expect(writes, 1);
    api.dispose();
  });
  test('readiness has a total deadline and never sends a write on failure',
      () async {
    var writes = 0;
    final api = ApiService(
        baseUrl: 'https://unavailable-wake.test',
        coldStart: true,
        wakeTimeout: const Duration(milliseconds: 30),
        retryDelay: const Duration(milliseconds: 5),
        client: MockClient((request) async {
          if (request.url.path != '/ready') writes++;
          return http.Response('{}', 503);
        }));
    await expectLater(api.request('/api/problems', method: 'POST', body: {}),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 503)));
    expect(writes, 0);
    api.dispose();
  });
  test('ambiguous write failure never automatically replays the mutation',
      () async {
    var writes = 0;
    final api = ApiService(
        baseUrl: 'https://ambiguous-write.test',
        coldStart: true,
        client: MockClient((request) async {
          if (request.url.path == '/ready') return http.Response('{}', 200);
          writes++;
          throw http.ClientException('connection closed');
        }));
    await expectLater(api.request('/api/problems', method: 'POST', body: {}),
        throwsA(isA<ApiException>()));
    expect(writes, 1);
    api.dispose();
  });
}
