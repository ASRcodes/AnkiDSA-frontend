import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ankidsa/models/recovery_link.dart';
import 'package:ankidsa/screens/password_recovery_screen.dart';
import 'package:ankidsa/services/api_service.dart';
import 'package:ankidsa/theme.dart';

void main() {
  test(
      'recovery tokens are read from fragments, never ordinary query parameters',
      () {
    expect(RecoveryLink.fromUri(Uri.parse('https://app.example/?token=secret')),
        isNull);
    final link = RecoveryLink.fromUri(
        Uri.parse('https://app.example/#/reset-password?token=example'));
    expect(link?.mode, RecoveryMode.reset);
    expect(link?.token, 'example');
    expect(
        RecoveryLink.fromUri(Uri.parse('https://app.example/#/forgot-password'))
            ?.mode,
        RecoveryMode.request);
  });

  testWidgets(
      'password confirmation prevents a request and a successful reset returns to normal sign-in',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var requests = 0, sessionsCleared = 0, returns = 0;
    final api = ApiService(client: MockClient((request) async {
      requests++;
      expect(request.url.path, '/api/auth/reset-password');
      expect(jsonDecode(request.body)['password'], 'ReplacementPassword123');
      return http.Response('', 204);
    }));
    await tester.pumpWidget(MaterialApp(
        theme: appTheme(),
        home: ResetPasswordScreen(
          token: 'a' * 43,
          api: api,
          onDone: () => returns++,
          onPasswordChanged: () async {
            sessionsCleared++;
          },
        )));
    await tester.enterText(
        find.byType(TextFormField).at(0), 'ReplacementPassword123');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'DifferentPassword123');
    await tester.tap(find.text('Set new password'));
    await tester.pumpAndSettle();
    expect(find.text('The passwords do not match.'), findsOneWidget);
    expect(requests, 0);
    await tester.enterText(
        find.byType(TextFormField).at(1), 'ReplacementPassword123');
    await tester.tap(find.text('Set new password'));
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(sessionsCleared, 1);
    expect(find.text('Return to sign in'), findsOneWidget);
    expect(returns, 0);
    await tester.tap(find.text('Return to sign in'));
    expect(returns, 1);
  });

  testWidgets('incomplete recovery links do not expose a password form',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: appTheme(),
        home: ResetPasswordScreen(
          token: 'incomplete',
          onDone: () {},
        )));
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Request a new link'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
