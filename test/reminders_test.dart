import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ankidsa/constants.dart';
import 'package:ankidsa/screens/home_screen.dart';
import 'package:ankidsa/screens/settings_screen.dart';
import 'package:ankidsa/services/study_store.dart';
import 'package:ankidsa/theme.dart';
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

class ManualRetryTimer implements Timer {
  final void Function(Timer) callback;
  ManualRetryTimer(this.callback);
  @override
  bool isActive = true;
  @override
  int tick = 0;
  @override
  void cancel() => isActive = false;
  void fire() {
    if (!isActive) return;
    tick++;
    callback(this);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakePush push;
  late ReminderService reminders;
  late AuthService auth;
  late List<http.Request> requests;
  bool dailyReminders = true;
  Future<void> Function(http.Request)? intercept;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    push = FakePush();
    requests = [];
    intercept = null;
    dailyReminders = true;
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
                  return http.Response(
                      jsonEncode({'dailyReminders': dailyReminders}), 200);
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

  test(
      'reopening after an unavailable server retries setup without signing out',
      () async {
    intercept = (request) async {
      if (request.url.path == '/api/auth/options') {
        throw const ApiException('Server is waking.', 503);
      }
    };
    reminders.attach(auth);
    await reminders.settled;
    expect(reminders.available, false);
    expect(reminders.error, isNotNull);
    intercept = null;
    await reminders.refresh();
    expect(reminders.available, true);
    expect(reminders.error, isNull);
    expect(reminders.enabled, false);
    expect(push.prompts, 0);
    await reminders.setEnabled(true);
    expect(requests.last.method, 'PUT');
    expect(jsonDecode(requests.last.body)['token'], 'phone-one');
  });

  test(
      'initial availability failure preserves consent and retries automatically',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final consentKey = 'ankidsa_reminders_${AppConstants.baseUrl}_1';
    await prefs.setBool(consentKey, true);
    intercept = (request) async {
      if (request.url.path == '/api/auth/options') {
        throw const ApiException('Server unavailable.', 503);
      }
    };
    late ManualRetryTimer retry;
    runZoned(() => reminders.attach(auth), zoneSpecification: ZoneSpecification(
        createPeriodicTimer: (self, parent, zone, duration, callback) {
      expect(duration, const Duration(minutes: 2));
      return retry = ManualRetryTimer(callback);
    }));
    await reminders.settled;
    expect(reminders.supported, true);
    expect(reminders.available, false);
    expect(reminders.enabled, true);
    expect(reminders.registered, false);
    expect(prefs.getBool(consentKey), true);
    expect(requests.where((r) => r.method == 'PUT'), isEmpty);

    intercept = null;
    retry.fire();
    await reminders.settled;
    expect(reminders.available, true);
    expect(reminders.enabled, true);
    expect(reminders.registered, true);
    expect(reminders.error, isNull);
    expect(push.prompts, 0);
    expect(requests.where((r) => r.method == 'PUT').length, 1);
  });

  test(
      'failed registration keeps consent without claiming registration, then retries',
      () async {
    reminders.attach(auth);
    await reminders.settled;
    intercept = (request) async {
      if (request.method == 'PUT') {
        throw const ApiException('Server unavailable.', 503);
      }
    };
    await reminders.setEnabled(true);
    expect(reminders.enabled, true);
    expect(reminders.registered, false);
    expect(reminders.error, contains('could not be confirmed'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('ankidsa_reminders_${AppConstants.baseUrl}_1'), true);
    expect(
        prefs.getString('ankidsa_push_device_${AppConstants.baseUrl}'), isNull);

    intercept = null;
    await reminders.refresh();
    expect(reminders.registered, true);
    expect(reminders.error, isNull);
    expect(prefs.getString('ankidsa_push_device_${AppConstants.baseUrl}'),
        'phone-one');
    expect(push.prompts, 1);
  });

  test('saved consent can be disabled while availability cannot be checked',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final consentKey = 'ankidsa_reminders_${AppConstants.baseUrl}_1';
    await prefs.setBool(consentKey, true);
    intercept = (request) async {
      if (request.url.path == '/api/auth/options') {
        throw const ApiException('Server unavailable.', 503);
      }
    };
    reminders.attach(auth);
    await reminders.settled;
    await reminders.setEnabled(false);
    expect(reminders.enabled, false);
    expect(reminders.registered, false);
    expect(prefs.getBool(consentKey), false);
    expect(push.revoked, 1);
  });

  for (final size in [const Size(360, 800), const Size(1100, 800)]) {
    testWidgets(
        'reminder controls remain reachable after startup failure at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      intercept = (request) async {
        if (request.url.path == '/api/auth/options') {
          throw const ApiException('Server unavailable.', 503);
        }
      };
      await tester.runAsync(() async {
        reminders.attach(auth);
        await reminders.settled;
      });
      final store = StudyStore();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider<ReminderService>.value(value: reminders),
          ChangeNotifierProvider<StudyStore>.value(value: store),
        ],
        child: MaterialApp(theme: appTheme(), home: const HomeScreen()),
      ));
      await tester.pumpAndSettle();
      if (size.width < 900) {
        await tester.tap(find.byTooltip('Account'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reminders'));
      } else {
        await tester.ensureVisible(find.text('Reminders'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reminders'));
      }
      await tester.pumpAndSettle();
      expect(find.text('Retry connection'), findsOneWidget);
      expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
          isNull);
      intercept = null;
      await tester.runAsync(() async {
        await tester.tap(find.text('Retry connection'));
        await reminders.settled;
      });
      await tester.pumpAndSettle();
      expect(reminders.available, true);
      expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
          isNotNull);
      expect(find.text('Daily reminders are off for this device.'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });
  }

  testWidgets('settings shows failed registration and a working retry action',
      (tester) async {
    await tester.runAsync(() async {
      reminders.attach(auth);
      await reminders.settled;
    });
    intercept = (request) async {
      if (request.method == 'PUT') {
        throw const ApiException('Server unavailable.', 503);
      }
    };
    await tester.runAsync(() => reminders.setEnabled(true));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<ReminderService>.value(value: reminders),
      ],
      child: MaterialApp(
          theme: appTheme(), home: const Scaffold(body: SettingsScreen())),
    ));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Your preference is saved. Device registration has not been confirmed.'),
        findsOneWidget);
    expect(find.text('Daily reminders are on for this device.'), findsNothing);
    await tester.ensureVisible(find.text('Retry connection'));
    await tester.pumpAndSettle();
    intercept = null;
    await tester.runAsync(() async {
      await tester.tap(find.text('Retry connection'));
      await reminders.settled;
    });
    await tester.pumpAndSettle();
    expect(
        find.text(
            'This device is registered for reminders when questions are due.'),
        findsOneWidget);
    expect(find.text('Retry connection'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  test('backend activation becomes available without changing account consent',
      () async {
    dailyReminders = false;
    reminders.attach(auth);
    await reminders.settled;
    expect(reminders.available, false);
    dailyReminders = true;
    await reminders.refresh();
    expect(reminders.available, true);
    expect(reminders.enabled, false);
    expect(push.prompts, 0);
    expect(requests.where((request) => request.method == 'PUT'), isEmpty);
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
    expect(reminders.registered, false);
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
    expect(reminders.registered, true);
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
    expect(reminders.registered, false);
    await subscription.cancel();
  });
}
