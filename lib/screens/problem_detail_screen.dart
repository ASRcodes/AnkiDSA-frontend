import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/problem.dart';
import '../services/study_store.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'add_problem_screen.dart';
import 'review_screen.dart';

class ProblemDetailScreen extends StatelessWidget {
  final Problem problem;
  const ProblemDetailScreen({super.key, required this.problem});
  @override
  Widget build(BuildContext context) {
    final current =
        context.watch<StudyStore>().problems.where((p) => p.id == problem.id);
    final p = current.isEmpty ? problem : current.first;
    if (current.isEmpty && context.watch<StudyStore>().stats != null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Problem notebook')),
          body: PageBody(children: [
            EmptyState(
                title: 'This page has been put away.',
                message: 'This problem is no longer in your collection.',
                icon: Icons.bookmark_remove_outlined,
                action: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to my collection'))),
          ]));
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Problem notebook')),
        body: PageBody(children: [
          Eyebrow('${p.difficultyLabel} · ${p.statusLabel}'),
          const SizedBox(height: 16),
          Text(p.title, style: editorial(34)),
          const SizedBox(height: 22),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.tags.map((tag) => Chip(label: Text(tag))).toList()),
          const SizedBox(height: 20),
          Wrap(spacing: 12, runSpacing: 12, children: [
            OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AddProblemScreen(problem: p))),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit notes')),
            TextButton.icon(
                onPressed: () async {
                  final url = Uri.tryParse(p.leetcodeUrl);
                  if (url == null ||
                      url.scheme != 'https' ||
                      url.host != 'leetcode.com') {
                    return;
                  }
                  try {
                    if (!await launchUrl(url,
                            mode: LaunchMode.externalApplication) &&
                        context.mounted) {
                      showMessage(context,
                          'Could not open LeetCode. Please try again.');
                    }
                  } catch (_) {
                    if (context.mounted) {
                      showMessage(context, 'Could not open LeetCode.');
                    }
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open LeetCode')),
          ]),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 22),
          const Eyebrow('THE INSIGHT TO KEEP'),
          const SizedBox(height: 16),
          SelectableText(
              p.notes?.trim().isNotEmpty == true
                  ? p.notes!
                  : 'A blank page for your next insight. Add a note about the pattern, trade-offs, or the step that made it click.',
              style: const TextStyle(height: 1.8)),
          const SizedBox(height: 32),
          Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('YOUR RECALL'),
                    const SizedBox(height: 12),
                    Text('Next review · ${p.nextReviewDate}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                        '${p.repetitions} successful repetitions · ${p.interval} day interval',
                        style: const TextStyle(color: AppColors.muted)),
                    if (context
                        .watch<StudyStore>()
                        .queue
                        .any((item) => item.id == p.id)) ...[
                      const SizedBox(height: 18),
                      FilledButton.icon(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ReviewScreen(problem: p))),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Review this problem')),
                    ],
                  ])),
        ]));
  }
}
