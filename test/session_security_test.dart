import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ankidsa/services/api_service.dart';
import 'package:ankidsa/services/auth_service.dart';
import 'package:ankidsa/constants.dart';

class DelayedStorage extends FlutterSecureStorage {
  final started = Completer<void>(), release = Completer<void>();
  @override
  Future<void> write(
      {required String key,
      required String? value,
      IOSOptions? iOptions,
      AndroidOptions? aOptions,
      LinuxOptions? lOptions,
      WebOptions? webOptions,
      MacOsOptions? mOptions,
      WindowsOptions? wOptions}) async {
    if (key == 'ankidsa_session_v2') {
      if (!started.isCompleted) started.complete();
      await release.future;
    }
    await super.write(key: key, value: value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });
  for (final status in [200, 401]) {
    test('saved session renders before delayed verification ($status)',
        () async {
      FlutterSecureStorage.setMockInitialValues({
        'ankidsa_session_v2': jsonEncode({
          'token': 'saved',
          'userId': 7,
          'name': 'Saved',
          'email': 'saved@example.test'
        })
      });
      final started = Completer<void>();
      final response = Completer<http.Response>();
      final auth = AuthService(
          apiFactory: (token, base) => ApiService(
              token: token,
              coldStart: false,
              client: MockClient((request) async {
                started.complete();
                return response.future;
              })));
      final restore = auth.tryAutoLogin();
      await started.future;
      expect(auth.isLoading, false);
      expect(auth.isLoggedIn, true);
      response.complete(http.Response(
          jsonEncode(
              {'userId': 7, 'name': 'Verified', 'email': 'saved@example.test'}),
          status));
      await restore;
      expect(auth.isLoggedIn, status == 200);
      expect(auth.userId, status == 200 ? 7 : null);
      auth.dispose();
    });
  }
  test('late verification cannot overwrite a replacement session', () async {
    FlutterSecureStorage.setMockInitialValues({
      'ankidsa_session_v2': jsonEncode({
        'token': 'old',
        'userId': 1,
        'name': 'Old',
        'email': 'old@example.test'
      })
    });
    final started = Completer<void>();
    final response = Completer<http.Response>();
    final auth = AuthService(
        apiFactory: (token, base) => ApiService(
            token: token,
            coldStart: false,
            client: MockClient((request) async {
              if (request.url.path.endsWith('/verify')) {
                started.complete();
                return response.future;
              }
              return http.Response(
                  jsonEncode({
                    'token': 'new',
                    'userId': 2,
                    'name': 'New',
                    'email': 'new@example.test'
                  }),
                  200);
            })));
    final restore = auth.tryAutoLogin();
    await started.future;
    await auth.authenticate('new@example.test', 'Password!', 'New');
    response.complete(http.Response('{}', 401));
    await restore;
    expect(auth.token, 'new');
    expect(auth.userId, 2);
    auth.dispose();
  });
  test('logout during secure-storage write cannot restore the old session',
      () async {
    final storage = DelayedStorage();
    final auth = AuthService(
        storage: storage,
        apiFactory: (token, base) => ApiService(
            client: MockClient((_) async => http.Response(
                jsonEncode({
                  'token': 'fixture-session',
                  'userId': 1,
                  'name': 'Fixture',
                  'email': 'fixture@example.test'
                }),
                200))));
    final login = auth.authenticate(
        'fixture@example.test', 'FixturePassword!', 'Fixture');
    await storage.started.future;
    final logout = auth.logout();
    storage.release.complete();
    await Future.wait([login, logout]);
    expect(auth.isLoggedIn, false);
    expect(await storage.read(key: 'ankidsa_session_v2'), isNull);
    auth.dispose();
  });
  test('logout captures device ownership before notifying cleanup listeners',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'ankidsa_push_device_${AppConstants.baseUrl}';
    await prefs.setString(key, 'fixture-device');
    final requests = <http.Request>[];
    final auth = AuthService(
        apiFactory: (token, base) => ApiService(
            token: token,
            client: MockClient((request) async {
              requests.add(request);
              return http.Response('', 204);
            })))
      ..token = 'fixture-session';
    auth.addListener(() {
      unawaited(prefs.remove(key));
    });
    await auth.logout();
    expect(requests.single.url.path, '/api/auth/logout');
    expect(requests.single.headers['Authorization'], 'Bearer fixture-session');
    expect(jsonDecode(requests.single.body)['deviceToken'], 'fixture-device');
    expect(await auth.storage.read(key: 'ankidsa_pending_logout_v1'), isNull);
    auth.dispose();
  });
}
