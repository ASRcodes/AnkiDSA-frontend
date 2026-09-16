import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ankidsa/models/problem.dart';
import 'package:ankidsa/models/stats.dart';
import 'package:ankidsa/screens/home_screen.dart';
import 'package:ankidsa/screens/review_screen.dart';
import 'package:ankidsa/services/auth_service.dart';
import 'package:ankidsa/services/study_store.dart';
import 'package:ankidsa/theme.dart';

void main() {
  final problem = Problem.fromJson({
    'id': 1,
    'title': 'Longest Substring Without Repeating Characters',
    'difficulty': 'MEDIUM',
    'leetcodeUrl':
        'https://leetcode.com/problems/longest-substring-without-repeating-characters/',
    'nextReviewDate': '2026-09-16',
    'notes': 'Move the left boundary forward when a duplicate enters.',
    'tags': ['sliding-window'],
  });
  for (final size in [const Size(320, 568), const Size(1024, 500)]) {
    testWidgets('navigation and recall remain usable with large text at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = AuthService()..name = 'A person with a longer account name';
      final store = StudyStore()
        ..problems = [problem]
        ..stats = Stats.fromJson({
          'totalProblems': 12345,
          'totalReviews': 123456,
          'retentionRate': 100,
          'streak': 120,
          'today': '2026-09-16'
        });
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>(create: (_) => auth),
          ChangeNotifierProvider<StudyStore>(create: (_) => store),
        ],
        child: MaterialApp(
          theme: appTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const HomeScreen(),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Insights'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final homeContext = tester.element(find.byType(HomeScreen));
      Navigator.of(homeContext).push(
          MaterialPageRoute(builder: (_) => ReviewScreen(problem: problem)));
      await tester.pumpAndSettle();
      final scrollable = find.descendant(
          of: find.byType(ReviewScreen), matching: find.byType(Scrollable));
      await tester.scrollUntilVisible(find.text('Reveal my notes'), 180,
          scrollable: scrollable);
      await tester.tap(find.text('Reveal my notes'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Good'), 180,
          scrollable: scrollable);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
