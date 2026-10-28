import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../constants.dart';

class AuthService extends ChangeNotifier {
  final FlutterSecureStorage storage;
  final ApiService Function(String? token, String? baseUrl) _api;
  AuthService(
      {this.storage = const FlutterSecureStorage(),
      ApiService Function(String? token, String? baseUrl)? apiFactory})
      : _api = apiFactory ??
            ((token, baseUrl) => ApiService(token: token, baseUrl: baseUrl));
  String? token, name, email;
  int? userId;
  bool isLoading = true;
  String? startupError;
  int _generation = 0;
  Future<void> _revocations = Future.value();
  Future<void> _sessionWrites = Future.value();
  Future<void> _persistSession(int generation, Map<String, dynamic>? data) {
    final next = _sessionWrites.then((_) async {
      if (generation != _generation) return;
      if (data == null) {
        await storage.delete(key: 'ankidsa_session_v2');
      } else {
        await storage.write(key: 'ankidsa_session_v2', value: jsonEncode(data));
      }
    });
    _sessionWrites = next.catchError((Object _) {});
    return next;
  }

  bool get isLoggedIn => token != null;

  Future<void> tryAutoLogin() async {
    final generation = _generation;
    unawaited(_flushRevocations());
    try {
      // Retire tokens issued by the old email-only sign-in.
      final prefs = await SharedPreferences.getInstance();
      for (final key in ['jwt_token', 'user_id', 'user_email', 'user_name']) {
        await prefs.remove(key);
      }
      final saved = await storage.read(key: 'ankidsa_session_v2');
      if (saved != null) {
        if (generation != _generation) return;
        final session = jsonDecode(saved) as Map<String, dynamic>;
        _assign(session);
        // Render the local session immediately. Protected API calls still verify
        // authorization on the server and revoke an expired session on 401.
        isLoading = false;
        notifyListeners();
        if (generation != _generation) return;
        final api = _api(token, null);
        try {
          final user = await api.request('/api/auth/verify');
          if (generation != _generation) return;
          name = user['name'];
          email = user['email'];
          userId = user['userId'];
        } on ApiException catch (e) {
          if (e.status == 401) {
            if (generation != _generation) return;
            expire();
            return;
          }
          // An offline start preserves the session; the collection shows a retry action.
        } finally {
          api.dispose();
        }
      }
    } catch (_) {
      if (generation != _generation) return;
      token = null;
      startupError = 'Could not restore your session. Please sign in again.';
    }
    if (generation != _generation) return;
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  void _assign(Map<String, dynamic> data) {
    token = data['token'];
    userId = data['userId'];
    name = data['name'];
    email = data['email'];
  }

  Future<void> authenticate(String email, String password, String name,
      {bool register = false}) async {
    final api = _api(null, null);
    final generation = ++_generation;
    try {
      final data = Map<String, dynamic>.from(await api.request(
          '/api/auth/${register ? 'register' : 'login'}',
          method: 'POST',
          body: {
            'email': email.trim(),
            'password': password,
            'name': name.trim()
          }));
      if (generation != _generation) return;
      await _persistSession(generation, data);
      if (generation != _generation) return;
      _assign(data);
      startupError = null;
      notifyListeners();
      unawaited(_flushRevocations());
    } finally {
      api.dispose();
    }
  }

  Future<void> logout() async {
    final previous = token;
    final generation = ++_generation;
    String? device;
    try {
      final prefs = await SharedPreferences.getInstance();
      device = prefs.getString('ankidsa_push_device_${AppConstants.baseUrl}');
    } catch (_) {/* Local sign-out must still work if preferences fail. */}
    if (generation != _generation) return;
    token = null;
    userId = null;
    name = null;
    email = null;
    notifyListeners();
    await _persistSession(generation, null);
    if (previous != null) {
      await _flushRevocations(
          add: {'token': previous, if (device != null) 'deviceToken': device});
    }
  }

  Future<void> _flushRevocations({Map<String, dynamic>? add}) {
    final next = _revocations.then((_) async {
      const key = 'ankidsa_pending_logout_v1';
      final saved = await storage.read(key: key);
      final pending = saved == null ? <dynamic>[] : jsonDecode(saved) as List;
      if (add != null) pending.add({...add, 'baseUrl': AppConstants.baseUrl});
      // Persist before sending; a closed app can finish logout on its next launch.
      await storage.write(key: key, value: jsonEncode(pending));
      final remaining = <dynamic>[];
      for (final item in pending) {
        final api = _api(item['token'], item['baseUrl']);
        try {
          await api.request('/api/auth/logout', method: 'POST', body: {
            if (item['deviceToken'] != null) 'deviceToken': item['deviceToken']
          });
        } on ApiException catch (e) {
          if (e.status != 401) remaining.add(item);
        } finally {
          api.dispose();
        }
      }
      if (remaining.isEmpty) {
        await storage.delete(key: key);
      } else {
        await storage.write(key: key, value: jsonEncode(remaining));
      }
    });
    _revocations = next.catchError((Object _) {});
    return _revocations;
  }

  void expire() {
    final generation = ++_generation;
    token = null;
    userId = null;
    name = null;
    email = null;
    startupError = 'Your session expired. Sign in to continue.';
    notifyListeners();
    unawaited(_persistSession(generation, null).catchError((Object _) {}));
  }
}
