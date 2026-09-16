import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ankidsa/models/problem.dart';
import 'package:ankidsa/screens/review_screen.dart';
import 'package:ankidsa/services/study_store.dart';
import 'package:ankidsa/theme.dart';

void main() {
  const problem = Problem(
      id: 1,
      version: 0,
      leetcodeUrl: 'https://leetcode.com/problems/two-sum/',
      title: 'Two Sum',
      difficulty: 'EASY',
      tags: ['hash-map'],
      notes: 'Remember the complement.',
      easinessFactor: 2.5,
      interval: 0,
      repetitions: 0,
      nextReviewDate: '2026-09-16',
      status: 'NEW');
  testWidgets('recall hides both notes and pattern hints until reveal',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => StudyStore(),
        child: MaterialApp(
            theme: appTheme(), home: const ReviewScreen(problem: problem))));
    expect(find.text('hash-map'), findsNothing);
    expect(find.text('Remember the complement.'), findsNothing);
    await tester.tap(find.text('Reveal my notes'));
    await tester.pumpAndSettle();
    expect(find.text('Remember the complement.'), findsOneWidget);
    expect(find.text('hash-map'), findsOneWidget);
    await tester.ensureVisible(find.text('Good'));
    expect(tester.takeException(), isNull);
  });
}
