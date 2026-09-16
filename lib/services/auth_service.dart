import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final FlutterSecureStorage storage;
  AuthService({this.storage = const FlutterSecureStorage()});
  String? token, name, email;
  int? userId;
  bool isLoading = true;
  String? startupError;
  bool get isLoggedIn => token != null;

  Future<void> tryAutoLogin() async {
    try {
      // Retire tokens issued by the old email-only sign-in.
      final prefs = await SharedPreferences.getInstance();
      for (final key in ['jwt_token', 'user_id', 'user_email', 'user_name']) {
        await prefs.remove(key);
      }
      final saved = await storage.read(key: 'ankidsa_session_v2');
      if (saved != null) {
        final session = jsonDecode(saved) as Map<String, dynamic>;
        _assign(session);
        final api = ApiService(token: token);
        try {
          final user = await api.request('/api/auth/verify');
          name = user['name'];
          email = user['email'];
          userId = user['userId'];
        } on ApiException catch (e) {
          if (e.status == 401) {
            token = null;
            await storage.delete(key: 'ankidsa_session_v2');
          }
          // An offline start preserves the session; the collection shows a retry action.
        } finally {
          api.dispose();
        }
      }
    } catch (_) {
      token = null;
      startupError = 'Could not restore your session. Please sign in again.';
    }
    isLoading = false;
    notifyListeners();
  }

  void _assign(Map<String, dynamic> data) {
    token = data['token'];
    userId = data['userId'];
    name = data['name'];
    email = data['email'];
  }

  Future<void> authenticate(String email, String password, String name,
      {bool register = false}) async {
    final api = ApiService();
    try {
      final data = Map<String, dynamic>.from(await api.request(
          '/api/auth/${register ? 'register' : 'login'}',
          method: 'POST',
          body: {
            'email': email.trim(),
            'password': password,
            'name': name.trim()
          }));
      await storage.write(key: 'ankidsa_session_v2', value: jsonEncode(data));
      _assign(data);
      startupError = null;
      notifyListeners();
    } finally {
      api.dispose();
    }
  }

  Future<void> logout() async {
    token = null;
    userId = null;
    name = null;
    email = null;
    notifyListeners();
    await storage.delete(key: 'ankidsa_session_v2');
  }

  void expire() {
    token = null;
    userId = null;
    startupError = 'Your session expired. Sign in to continue.';
    notifyListeners();
    storage.delete(key: 'ankidsa_session_v2');
  }
}
