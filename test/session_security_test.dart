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
