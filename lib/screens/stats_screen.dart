import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/study_store.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StudyStore>(),
        s = context.watch<StudyStore>().stats;
    return PageBody(onRefresh: () => store.refresh(), children: [
      const Eyebrow('THE PRACTICE ADDS UP'),
      const SizedBox(height: 18),
      Text('Look how far you’ve come.',
          style: editorial(MediaQuery.sizeOf(context).width < 600 ? 32 : 42)),
      const SizedBox(height: 12),
      const Text('A record of showing up, one useful idea at a time.',
          style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 30),
      if (store.error != null)
        ErrorBanner(message: store.error!, retry: () => store.refresh()),
      if (store.loading && s == null) const LinearProgressIndicator(),
      if (s != null) ...[
        LayoutBuilder(builder: (context, box) {
          final minWidth = MediaQuery.textScalerOf(context).scale(90) + 44;
          final columns =
              ((box.maxWidth + 12) / (minWidth + 12)).floor().clamp(1, 4);
          final w = (box.maxWidth - 12 * (columns - 1)) / columns;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            _metric('REVIEWS COMPLETED', '${s.totalReviews}',
                '${s.reviewsToday} today', w),
            _metric(
                'SUCCESSFUL RECALL',
                s.retentionRate == null
                    ? '—'
                    : '${s.retentionRate!.toStringAsFixed(0)}%',
                'Hard, Good or Easy',
                w),
            _metric('DAY STREAK', '${s.streak}', 'Keep making time', w),
            _metric('MASTERED', '${s.masteredCount}',
                'Review interval > 21 days', w),
          ]);
        }),
        const SizedBox(height: 32),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(16)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Eyebrow('YOUR LAST 12 WEEKS'),
              const SizedBox(height: 14),
              Text('A little, often.', style: editorial(25)),
              const SizedBox(height: 8),
              const Text('Each square is a day you made room for practice.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 24),
              LayoutBuilder(builder: (context, box) {
                final cell = ((box.maxWidth - 44) / 12).clamp(10.0, 28.0);
                final today = DateTime.parse(s.today),
                    start = DateTime.parse(s.today)
                        .subtract(const Duration(days: 83));
                return Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: List.generate(
                        12,
                        (week) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(7, (day) {
                              final date =
                                      start.add(Duration(days: week * 7 + day)),
                                  count = s.activity[DateFormat('yyyy-MM-dd')
                                          .format(start.add(Duration(
                                              days: week * 7 + day)))] ??
                                      0;
                              return Tooltip(
                                  message:
                                      '${DateFormat('MMM d').format(date)} · $count reviews',
                                  child: Semantics(
                                      label:
                                          '${DateFormat('MMM d').format(date)}: $count reviews',
                                      child: Container(
                                          width: cell,
                                          height: cell,
                                          margin:
                                              const EdgeInsets.only(bottom: 4),
                                          decoration: BoxDecoration(
                                              color: count == 0
                                                  ? const Color(0xFFF0F1E9)
                                                  : count < 3
                                                      ? const Color(0xFFBFCEAE)
                                                      : count < 6
                                                          ? const Color(
                                                              0xFF799B70)
                                                          : AppColors.green,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              border: date == today
                                                  ? Border.all(
                                                      color: AppColors.clay)
                                                  : null))));
                            }))));
              }),
              const SizedBox(height: 12),
              const Text('LESS  ░  ▒  ▓  MORE',
                  style: TextStyle(
                      fontSize: 9, letterSpacing: 1.4, color: AppColors.muted)),
            ])),
        const SizedBox(height: 32),
        const Eyebrow('IN YOUR COLLECTION'),
        const SizedBox(height: 18),
        ...[
          ('Easy', s.easyCount, AppColors.green),
          ('Medium', s.mediumCount, const Color(0xFFAD924F)),
          ('Hard', s.hardCount, AppColors.clay)
        ].map((row) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(children: [
              SizedBox(
                  width: 70,
                  child: Text(row.$1, style: const TextStyle(fontSize: 12))),
              Expanded(
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                          value: s.totalProblems == 0
                              ? 0
                              : row.$2 / s.totalProblems,
                          minHeight: 7,
                          backgroundColor: AppColors.line,
                          color: row.$3))),
              SizedBox(
                  width: 40,
                  child: Text('${row.$2}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted)))
            ]))),
        const SizedBox(height: 8),
        Text(
            '${s.totalProblems} problems collected · ${s.learningCount} learning · ${s.overdueCount} carried forward',
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    ]);
  }

  Widget _metric(String label, String value, String detail, double width) =>
      Container(
          width: width,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(14)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.muted, letterSpacing: 1)),
            const SizedBox(height: 18),
            FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: editorial(38))),
            const SizedBox(height: 8),
            Text(detail,
                style: const TextStyle(color: AppColors.muted, fontSize: 10))
          ]));
}
