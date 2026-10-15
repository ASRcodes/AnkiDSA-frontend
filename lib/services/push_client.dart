import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

abstract class PushClient {
  Stream<void> get foregroundReminders => const Stream.empty();
  bool get configured;
  Future<bool> permission({bool request = false});
  Future<String?> token();
  Future<void> revoke();
  Stream<String> get tokenChanges;
  Stream<void> get queueOpens;
  Future<bool> initialQueueOpen();
}

class FirebasePushClient implements PushClient {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _sender = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _project = String.fromEnvironment('FIREBASE_PROJECT_ID');
  Future<void>? _initializing;
  final Set<String> _seen = {};
  static const options = FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _sender,
      projectId: _project,
      iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'));

  static Future<void> initializeForApp() async {
    final push = FirebasePushClient();
    if (!push.configured) return;
    await push._initialize();
    FirebaseMessaging.onBackgroundMessage(ankidsaBackgroundMessage);
  }

  @override
  bool get configured =>
      const bool.fromEnvironment('PUSH_NOTIFICATIONS_ENABLED',
          defaultValue: true) &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) &&
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _sender.isNotEmpty &&
      _project.isNotEmpty;

  Future<void> _initialize() => _initializing ??= () async {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(options: options);
        }
      }();

  @override
  Future<bool> permission({bool request = false}) async {
    await _initialize();
    final settings = request
        ? await FirebaseMessaging.instance.requestPermission()
        : await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> token() async {
    await _initialize();
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        await FirebaseMessaging.instance.getAPNSToken() == null) {
      return null;
    }
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    return FirebaseMessaging.instance.getToken();
  }

  @override
  Future<void> revoke() async {
    await _initialize();
    await FirebaseMessaging.instance.setAutoInitEnabled(false);
    await FirebaseMessaging.instance.deleteToken();
  }

  @override
  Stream<String> get tokenChanges => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<void> get foregroundReminders =>
      FirebaseMessaging.onMessage.where((message) {
        if (message.data['action'] != 'OPEN_QUEUE') return false;
        final id = message.data['deliveryId'] ?? message.messageId;
        if (id != null && !_seen.add(id)) return false;
        if (_seen.length > 128) _seen.remove(_seen.first);
        return true;
      }).map((_) {});

  @override
  Stream<void> get queueOpens => FirebaseMessaging.onMessageOpenedApp
      .where((message) => message.data['action'] == 'OPEN_QUEUE')
      .map((_) {});

  @override
  Future<bool> initialQueueOpen() async =>
      (await FirebaseMessaging.instance.getInitialMessage())?.data['action'] ==
      'OPEN_QUEUE';
}

@pragma('vm:entry-point')
Future<void> ankidsaBackgroundMessage(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: FirebasePushClient.options);
  }
  // Android displays notification payloads while backgrounded. Do not display a
  // second notification here, log payloads, or perform account-scoped writes.
}
