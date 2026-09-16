import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/study_store.dart';
import 'services/reminder_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/password_recovery_screen.dart';
import 'models/recovery_link.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
  runApp(const AnkiDSAApp());
}

class AnkiDSAApp extends StatefulWidget {
  const AnkiDSAApp({super.key});
  @override
  State<AnkiDSAApp> createState() => _AnkiDSAAppState();
}

class _AnkiDSAAppState extends State<AnkiDSAApp> {
  final _router = _AppRouter();
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()..tryAutoLogin()),
          ChangeNotifierProxyProvider<AuthService, ReminderService>(
              create: (_) => ReminderService(),
              lazy: false,
              update: (_, auth, reminders) => reminders!..attach(auth)),
          ChangeNotifierProxyProvider<AuthService, StudyStore>(
              create: (_) => StudyStore(),
              update: (_, auth, store) => store!..attach(auth)),
        ],
        child: MaterialApp.router(
          title: 'AnkiDSA · Keep what you learn',
          debugShowCheckedModeBanner: false,
          theme: appTheme(),
          routerDelegate: _router,
          routeInformationParser: const _AppRouteParser(),
        ),
      );
}

class _AppRoute {
  final RecoveryLink? recovery;
  const _AppRoute([this.recovery]);
}

class _AppRouteParser extends RouteInformationParser<_AppRoute> {
  const _AppRouteParser();
  @override
  Future<_AppRoute> parseRouteInformation(RouteInformation information) async {
    // Flutter's hash strategy exposes the fragment as a route path here.
    final uri = information.uri;
    return _AppRoute(RecoveryLink.fromUri(
        uri.hasFragment ? uri : Uri(fragment: uri.toString())));
  }

  @override
  RouteInformation restoreRouteInformation(_AppRoute configuration) {
    final recovery = configuration.recovery;
    return RouteInformation(
        uri: recovery == null
            ? Uri(path: '/')
            : Uri(
                path: recovery.mode == RecoveryMode.reset
                    ? '/reset-password'
                    : '/forgot-password',
                queryParameters: recovery.token == null
                    ? null
                    : {'token': recovery.token!}));
  }
}

class _AppRouter extends RouterDelegate<_AppRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<_AppRoute> {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();
  _AppRoute _route = const _AppRoute();

  @override
  _AppRoute get currentConfiguration => _route;

  @override
  Future<void> setNewRoutePath(_AppRoute configuration) async {
    _route = configuration;
  }

  void _finishRecovery() {
    _route = const _AppRoute();
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final recovery = _route.recovery;
    final Widget home;
    if (recovery?.mode == RecoveryMode.reset) {
      home = ResetPasswordScreen(
          token: recovery!.token,
          onDone: _finishRecovery,
          onPasswordChanged: auth.logout);
    } else if (recovery?.mode == RecoveryMode.request) {
      home = ForgotPasswordScreen(onDone: _finishRecovery);
    } else if (auth.isLoading) {
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      home = auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
    }
    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(key: ValueKey(recovery ?? auth.userId), child: home)
      ],
      onDidRemovePage: (_) {},
    );
  }
}
