import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ankidsa/services/api_service.dart';
import 'package:ankidsa/services/auth_service.dart';
import 'package:ankidsa/services/push_client.dart';
import 'package:ankidsa/services/reminder_service.dart';

class FakePush extends PushClient {
  bool allowed = true;
  bool ready = true;
  int revoked = 0, prompts = 0;
  String current = 'phone-one';
  final changes = StreamController<String>.broadcast();
  final opens = StreamController<void>.broadcast();
  @override
  bool get configured => ready;
  @override
  Future<bool> permission({bool request = false}) async {
    if (request) prompts++;
    return allowed;
  }

  @override
  Future<String?> token() async => current;
  @override
  Future<void> revoke() async {
    revoked++;
  }

  @override
  Stream<String> get tokenChanges => changes.stream;
  @override
  Stream<void> get queueOpens => opens.stream;
  @override
  Future<bool> initialQueueOpen() async => false;
  Future<void> close() async {
    await changes.close();
    await opens.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakePush push;
  late ReminderService reminders;
  late AuthService auth;
  late List<http.Request> requests;
  Future<void> Function(http.Request)? intercept;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    push = FakePush();
    requests = [];
    intercept = null;
    auth = AuthService()
      ..token = 'session-one'
      ..userId = 1;
    reminders = ReminderService(
        push: push,
        apiFactory: (token) => ApiService(
              token: token,
              client: MockClient((request) async {
                requests.add(request);
                await intercept?.call(request);
                if (request.url.path == '/api/auth/options') {
                  return http.Response('{"dailyReminders":true}', 200);
                }
                return http.Response('', 204);
              }),
            ));
  });
  tearDown(() async {
    reminders.dispose();
    auth.dispose();
    await push.close();
  });

  test('permission denial never registers a phone or enables reminders',
      () async {
    reminders.attach(auth);
    await reminders.settled;
    expect(push.prompts, 0);
    push.allowed = false;
    await reminders.setEnabled(true);
    expect(reminders.enabled, false);
    expect(reminders.error, contains('blocked'));
    expect(requests.where((r) => r.method == 'PUT'), isEmpty);
  });

  test('token changes register the new token and remove only the previous one',
      () async {
    reminders.attach(auth);
    await reminders.settled;
    await reminders.setEnabled(true);
    push.current = 'phone-two';
    push.changes.add('phone-two');
    await Future<void>.delayed(Duration.zero);
    await reminders.settled;
    final mutations = requests.where((r) => r.method != 'GET').toList();
    expect(mutations.map((r) => '${r.method}:${jsonDecode(r.body)['token']}'),
        ['PUT:phone-one', 'PUT:phone-two', 'DELETE:phone-one']);
    await reminders.setEnabled(false);
    expect(reminders.enabled, false);
    expect(push.revoked, 1);
    expect(jsonDecode(requests.last.body)['token'], 'phone-two');
  });

  test(
      'logout during registration cleans the old account and requires new consent',
      () async {
    reminders.attach(auth);
    await reminders.settled;
    final entered = Completer<void>(), release = Completer<void>();
    intercept = (request) async {
      if (request.method == 'PUT' && !entered.isCompleted) {
        entered.complete();
        await release.future;
      }
    };
    final enabling = reminders.setEnabled(true);
    await entered.future;
    auth
      ..token = 'session-two'
      ..userId = 2;
    reminders.attach(auth);
    release.complete();
    await enabling;
    await reminders.settled;
    expect(reminders.enabled, false);
    final deletes = requests.where((r) => r.method == 'DELETE');
    expect(deletes, isNotEmpty);
    expect(
        deletes
            .every((r) => r.headers['Authorization'] == 'Bearer session-one'),
        true);
    expect(
        requests.where((r) =>
            r.method == 'PUT' &&
            r.headers['Authorization'] == 'Bearer session-two'),
        isEmpty);
    expect(push.revoked, 1);
    await reminders.setEnabled(true);
    expect(requests.last.headers['Authorization'], 'Bearer session-two');
  });

  test('a reminder opens the queue only while the account has opted in',
      () async {
    reminders.attach(auth);
    await reminders.settled;
    await reminders.setEnabled(true);
    int opened = 0;
    final subscription = reminders.queueOpens.listen((_) => opened++);
    push.opens.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(opened, 1);
    auth
      ..token = null
      ..userId = null;
    reminders.attach(auth);
    await reminders.settled;
    push.opens.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(opened, 1);
    await subscription.cancel();
  });
}
