import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/study_store.dart';
import 'services/reminder_service.dart';
import 'services/push_client.dart';
import 'constants.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/password_recovery_screen.dart';
import 'models/recovery_link.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConstants.validate();
  try {
    await FirebasePushClient.initializeForApp();
  } catch (_) {
    // Study/authentication remain available when notification setup is unavailable.
  }
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
  final int tab;
  final bool unknown;
  const _AppRoute([this.recovery, this.tab = 0, this.unknown = false]);
}

const _paths = ['/', '/collection', '/insights', '/schedule', '/settings'];

class _AppRouteParser extends RouteInformationParser<_AppRoute> {
  const _AppRouteParser();
  @override
  Future<_AppRoute> parseRouteInformation(RouteInformation information) async {
    // Flutter's hash strategy exposes the fragment as a route path here.
    final uri = information.uri;
    final link = RecoveryLink.fromUri(
        uri.hasFragment ? uri : Uri(fragment: uri.toString()));
    final path = uri.hasFragment ? Uri.parse(uri.fragment).path : uri.path;
    final tab = _paths.indexOf(path.isEmpty ? '/' : path);
    return _AppRoute(link, tab < 0 ? 0 : tab, tab < 0 && link == null);
  }

  @override
  RouteInformation restoreRouteInformation(_AppRoute configuration) {
    final recovery = configuration.recovery;
    return RouteInformation(
        uri: recovery == null
            ? Uri(path: _paths[configuration.tab])
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
      home = _route.unknown
          ? Scaffold(
              body: Center(
                  child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.explore_outlined, size: 40),
                        const SizedBox(height: 20),
                        Text('A page still to be written.',
                            style: editorial(28)),
                        const SizedBox(height: 16),
                        const Text(
                            'This link does not lead to a page in AnkiDSA.'),
                        const SizedBox(height: 20),
                        FilledButton(
                            onPressed: _finishRecovery,
                            child: const Text('Back to my practice')),
                      ]))))
          : auth.isLoggedIn
              ? HomeScreen(
                  initialIndex: _route.tab,
                  onNavigate: (tab) {
                    _route = _AppRoute(null, tab);
                    notifyListeners();
                  })
              : const LoginScreen();
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
