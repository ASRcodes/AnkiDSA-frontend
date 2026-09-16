import 'package:flutter/foundation.dart';

class AppConstants {
  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');
  static String get baseUrl => _configuredUrl.isNotEmpty
      ? _configuredUrl
      : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:8081'
          : 'http://localhost:8081';
}
