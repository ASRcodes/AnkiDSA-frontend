import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'push_client.dart';

class ReminderService extends ChangeNotifier {
  final PushClient push;
  final ApiService Function(String token) apiFactory;
  final Future<SharedPreferences> Function() preferences;
  ReminderService({
    PushClient? push,
    ApiService Function(String token)? apiFactory,
    Future<SharedPreferences> Function()? preferences,
  })  : push = push ?? FirebasePushClient(),
        apiFactory = apiFactory ?? ((token) => ApiService(token: token)),
        preferences = preferences ?? SharedPreferences.getInstance;

  bool available = false, enabled = false, busy = false;
  String? error, _session;
  int? _userId;
  int _generation = 0;
  bool _disposed = false, _refreshQueued = false;
  Future<void> _tasks = Future.value();
  StreamSubscription<String>? _tokens;
  StreamSubscription<void>? _opens;
  Timer? _retry;
  final _queueOpens = StreamController<void>.broadcast();
  Stream<void> get queueOpens => _queueOpens.stream;
  String _preferenceKey(int id) =>
      'ankidsa_reminders_${AppConstants.baseUrl}_$id';
  String get _deviceKey => 'ankidsa_push_device_${AppConstants.baseUrl}';

  bool _current(int generation) => !_disposed && generation == _generation;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _tasks.then((_) => operation());
    _tasks = next.catchError((Object _) {});
    return next;
  }

  void attach(AuthService auth) {
    if (_session == auth.token) return;
    final previous = _session;
    _session = auth.token;
    _userId = auth.userId;
    final generation = ++_generation;
    final session = _session, userId = _userId;
    available = enabled = busy = false;
    error = null;
    if (!push.configured) return;
    unawaited(_enqueue(() async {
      try {
        final prefs = await preferences();
        if (previous != null && previous != session) {
          final oldDevice = prefs.getString(_deviceKey);
          try {
            if (oldDevice != null) await _remove(previous, oldDevice);
          } finally {
            await _revoke(prefs);
          }
        }
      } catch (_) {
        // Logout still clears the session. Push payloads contain no account data.
      }
      if (!_current(generation) || session == null || userId == null) return;
      final api = apiFactory(session);
      try {
        final options = await api.request('/api/auth/options');
        if (!_current(generation)) return;
        available = options['dailyReminders'] == true;
        final prefs = await preferences();
        if (!_current(generation)) return;
        enabled = prefs.getBool(_preferenceKey(userId)) ?? false;
        if (available && enabled) {
          await _sync(generation, session);
        } else {
          final oldDevice = prefs.getString(_deviceKey);
          if (oldDevice != null) {
            try {
              await _remove(session, oldDevice);
            } finally {
              await _revoke(prefs);
            }
          }
        }
      } catch (_) {
        if (_current(generation)) {
          error = 'Reminders could not connect. Try again when you are online.';
        }
      } finally {
        api.dispose();
        if (_current(generation)) _changed();
      }
    }));
  }

  Future<void> setEnabled(bool value) {
    final generation = _generation, session = _session, userId = _userId;
    if (!available || session == null || userId == null || busy) {
      return Future.value();
    }
    busy = true;
    error = null;
    _changed();
    return _enqueue(() async {
      try {
        if (!_current(generation)) return;
        final prefs = await preferences();
        if (value) {
          if (!await push.permission(request: true)) {
            if (_current(generation)) {
              enabled = false;
              error =
                  'Notifications are blocked. Allow them in your phone settings, then try again.';
            }
            return;
          }
          if (!_current(generation)) return;
          await prefs.setBool(_preferenceKey(userId), true);
          enabled = true;
          await _sync(generation, session);
        } else {
          enabled = false;
          await prefs.setBool(_preferenceKey(userId), false);
          final device = prefs.getString(_deviceKey);
          try {
            if (device != null) await _remove(session, device);
          } finally {
            await _revoke(prefs);
          }
        }
      } catch (_) {
        if (_current(generation)) {
          error = value
              ? 'Reminders will retry when you reopen the app with a connection.'
              : 'Your preference is saved. Reconnect and open the app to finish turning reminders off.';
        }
      } finally {
        if (_current(generation)) {
          busy = false;
          _changed();
        }
      }
    });
  }

  Future<void> _sync(int generation, String session, {String? token}) async {
    if (!_current(generation) || !enabled) return;
    if (!await push.permission()) {
      if (!_current(generation)) return;
      final prefs = await preferences();
      final old = prefs.getString(_deviceKey);
      if (old != null) await _remove(session, old);
      error =
          'Notifications are blocked. Allow them in your phone settings to receive reminders.';
      return;
    }
    if (!_current(generation) || !enabled) return;
    _tokens ??= push.tokenChanges
        .listen((token) => refresh(token: token), onError: (Object _) {});
    _opens ??= push.queueOpens.listen((_) {
      if (_session != null && enabled) _queueOpens.add(null);
    });
    _retry ??= Timer.periodic(const Duration(minutes: 2), (_) => refresh());
    final device = token ?? await push.token();
    if (device == null) {
      error =
          'Your phone is still preparing notifications. We will retry shortly.';
      return;
    }
    if (!_current(generation) || !enabled) return;
    final prefs = await preferences();
    final old = prefs.getString(_deviceKey);
    final api = apiFactory(session);
    try {
      await api.request('/api/users/me/device',
          method: 'PUT', body: {'token': device});
      if (!_current(generation)) {
        await _remove(session, device);
        return;
      }
      await prefs.setString(_deviceKey, device);
      if (old != null && old != device) await _remove(session, old);
      error = null;
      if (await push.initialQueueOpen() && _current(generation)) {
        _queueOpens.add(null);
      }
    } finally {
      api.dispose();
    }
  }

  Future<void> _remove(String session, String token) async {
    final api = apiFactory(session);
    try {
      await api.request('/api/users/me/device',
          method: 'DELETE', body: {'token': token});
    } on ApiException catch (e) {
      if (e.status != 401) rethrow;
    } finally {
      api.dispose();
    }
  }

  Future<void> _revoke(SharedPreferences prefs) async {
    await push.revoke();
    await prefs.remove(_deviceKey);
  }

  Future<void> refresh({String? token}) {
    final session = _session, generation = _generation;
    if (!available ||
        !enabled ||
        session == null ||
        _refreshQueued ||
        _disposed) {
      return Future.value();
    }
    _refreshQueued = true;
    return _enqueue(() async {
      try {
        await _sync(generation, session, token: token);
      } catch (_) {
        if (_current(generation)) {
          error = 'Reminders could not connect. We will retry shortly.';
        }
      } finally {
        _refreshQueued = false;
        if (_current(generation)) _changed();
      }
    });
  }

  @visibleForTesting
  Future<void> get settled => _tasks;

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _tokens?.cancel();
    _opens?.cancel();
    _retry?.cancel();
    _queueOpens.close();
    super.dispose();
  }
}
