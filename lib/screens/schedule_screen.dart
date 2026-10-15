import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/study_store.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import '../widgets/problem_card.dart';
import 'problem_detail_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StudyStore>();
    final today = DateTime.tryParse(store.stats?.today ?? '') ?? DateTime.now();
    final dates = store.problems.map((p) => p.nextReviewDate).toSet().toList()
      ..sort();
    final peak = store.problems.length.clamp(1, 100000);
    return PageBody(onRefresh: store.refresh, children: [
      const Eyebrow('MAKE SPACE FOR RECALL'),
      const SizedBox(height: 16),
      Semantics(
          container: true,
          header: true,
          child: Text('A rhythm that lasts.', style: editorial(34))),
      const SizedBox(height: 12),
      const Text('Your next sessions, shaped by what you remember.',
          style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 28),
      if (store.loading && store.stats == null) const StudyLoading(),
      if (store.error != null)
        ErrorBanner(message: store.error!, retry: store.refresh),
      if (store.stats != null && dates.isEmpty)
        const EmptyState(
            title: 'Your next chapter starts with one problem.',
            message:
                'Add something you have solved. Each review will shape its next date.',
            icon: Icons.event_available_outlined),
      for (final date in dates) ...[
        Builder(builder: (context) {
          final due =
              store.problems.where((p) => p.nextReviewDate == date).toList();
          final parsed = DateTime.tryParse(date);
          final days = parsed
              ?.difference(DateTime(today.year, today.month, today.day))
              .inDays;
          return Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                              parsed == null
                                  ? date
                                  : DateFormat('EEE, d MMM').format(parsed),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                              days == null
                                  ? ''
                                  : days < 0
                                      ? 'Ready to catch up'
                                      : days == 0
                                          ? 'Today'
                                          : days == 1
                                              ? 'Tomorrow'
                                              : '$days days ahead',
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
                          Text('${due.length} to revisit',
                              style: const TextStyle(
                                  color: AppColors.green, fontSize: 12)),
                        ]),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                        value: due.length / peak,
                        minHeight: 3,
                        backgroundColor: AppColors.line),
                    const SizedBox(height: 12),
                    for (final p in due)
                      ProblemCard(
                          problem: p,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ProblemDetailScreen(problem: p)))),
                  ]));
        }),
      ],
    ]);
  }
}
