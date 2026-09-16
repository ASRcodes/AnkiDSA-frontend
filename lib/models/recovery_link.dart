enum RecoveryMode { request, reset }

class RecoveryLink {
  final RecoveryMode mode;
  final String? token;
  const RecoveryLink(this.mode, {this.token});

  static RecoveryLink? fromUri(Uri uri) {
    final route = Uri.tryParse(uri.fragment);
    if (route?.path == '/forgot-password') {
      return const RecoveryLink(RecoveryMode.request);
    }
    if (route?.path == '/reset-password') {
      return RecoveryLink(RecoveryMode.reset,
          token: route!.queryParameters['token']);
    }
    return null;
  }
}
