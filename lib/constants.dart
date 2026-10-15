import 'package:flutter/foundation.dart';

class AppConstants {
  static const environment = String.fromEnvironment('APP_ENV',
      defaultValue: kReleaseMode ? 'production' : 'development');
  static bool get hosted => environment != 'development';
  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');
  static void validate() {
    if (!['development', 'staging', 'production'].contains(environment)) {
      throw StateError('APP_ENV must be development, staging or production.');
    }
    if (!hosted) return;
    final uri = Uri.tryParse(_configuredUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw StateError(
          'A hosted build requires an explicit HTTPS API_BASE_URL.');
    }
    if (const bool.fromEnvironment('DEMO_MODE')) {
      throw StateError('Demo mode is forbidden in hosted builds.');
    }
  }

  static String get baseUrl => _configuredUrl.isNotEmpty
      ? (_configuredUrl.endsWith('/')
          ? _configuredUrl.substring(0, _configuredUrl.length - 1)
          : _configuredUrl)
      : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:8081'
          : 'http://localhost:8081';
}
