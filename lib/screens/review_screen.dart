import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/problem.dart';
import '../services/study_store.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class ReviewScreen extends StatefulWidget {
  final Problem problem;
  const ReviewScreen({super.key, required this.problem});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _revealed = false, _submitting = false;
  String? _error, _requestId;
  int? _quality;
  Map<String, dynamic>? _result;
  Future<void> _review(int quality) async {
    if (_submitting) return;
    if (_quality != quality) {
      _requestId = const Uuid().v4();
      _quality = quality;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await context
          .read<StudyStore>()
          .review(widget.problem, quality, _requestId!);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<StudyStore>().queue;
    return Scaffold(
        appBar: AppBar(
            title: const Text('A moment to recall',
                style: TextStyle(fontSize: 15))),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(28, 30, 28, 60),
                    children: [
                      Row(children: [
                        const Expanded(child: Eyebrow('YOUR DAILY PRACTICE')),
                        Text(
                            _result != null
                                ? 'COMPLETE'
                                : _revealed
                                    ? '02 / REFLECT'
                                    : '01 / RECALL',
                            style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.4,
                                color: AppColors.muted))
                      ]),
                      const SizedBox(height: 35),
                      Text(widget.problem.title,
                          style: editorial(
                              MediaQuery.sizeOf(context).width < 600
                                  ? 34
                                  : 44)),
                      const SizedBox(height: 14),
                      Text(widget.problem.difficultyLabel,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                      const SizedBox(height: 36),
                      if (_result != null) ...[
                        Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                                color: AppColors.sage,
                                borderRadius: BorderRadius.circular(18)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                      _result!['status'] == 'MASTERED'
                                          ? Icons.workspace_premium_outlined
                                          : Icons.check_circle_outline,
                                      size: 36,
                                      color: AppColors.green),
                                  const SizedBox(height: 20),
                                  Text(_result!['message'] ?? 'Review saved.',
                                      style: editorial(28)),
                                  const SizedBox(height: 12),
                                  Text(
                                      'Scheduled for ${_result!['nextReviewDate']}.\nOne more idea, a little easier to reach.',
                                      style: const TextStyle(
                                          color: AppColors.muted, height: 1.8))
                                ])),
                        const SizedBox(height: 28),
                        FilledButton(
                            onPressed: () {
                              final next = queue
                                  .where((p) => p.id != widget.problem.id)
                                  .firstOrNull;
                              if (next != null) {
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            ReviewScreen(problem: next)));
                              } else {
                                Navigator.pop(context, true);
                              }
                            },
                            child: Text(
                                queue.any((p) => p.id != widget.problem.id)
                                    ? 'Next problem →'
                                    : 'Back to my queue')),
                        const SizedBox(height: 12),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Finish this session')),
                      ] else ...[
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                                color: AppColors.surface,
                                border: Border.all(color: AppColors.line),
                                borderRadius: BorderRadius.circular(16)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.lightbulb_outline,
                                      size: 25, color: AppColors.green),
                                  const SizedBox(height: 20),
                                  Text(
                                      _revealed
                                          ? 'How did your recall compare?'
                                          : 'What is the idea\nbehind the solution?',
                                      style: editorial(28)),
                                  const SizedBox(height: 16),
                                  Text(
                                      _revealed
                                          ? 'Notice what came easily and what needed a nudge.'
                                          : 'Think through the pattern, the steps, and the complexity.\nTake your time before checking your notes.',
                                      style: const TextStyle(
                                          color: AppColors.muted,
                                          height: 1.8,
                                          fontSize: 13))
                                ])),
                        const SizedBox(height: 24),
                        if (!_revealed) ...[
                          FilledButton.icon(
                              onPressed: () => setState(() => _revealed = true),
                              icon: const Icon(Icons.visibility_outlined,
                                  size: 18),
                              label: const Text('Reveal my notes')),
                          const SizedBox(height: 12),
                          TextButton.icon(
                              onPressed: () async {
                                final ok = await launchUrl(
                                    Uri.parse(widget.problem.leetcodeUrl),
                                    mode: LaunchMode.externalApplication);
                                if (!ok && context.mounted) {
                                  showMessage(
                                      context, 'Could not open LeetCode.');
                                }
                              },
                              icon: const Icon(Icons.open_in_new, size: 14),
                              label:
                                  const Text('Read the problem on LeetCode')),
                        ] else ...[
                          const Eyebrow('YOUR NOTES'),
                          const SizedBox(height: 16),
                          SelectionArea(
                              child: Text(
                                  widget.problem.notes?.isNotEmpty == true
                                      ? widget.problem.notes!
                                      : 'No notes yet. After this review, add the insight you want to remember from your collection.',
                                  style: const TextStyle(
                                      fontSize: 16, height: 1.9))),
                          const SizedBox(height: 18),
                          Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.problem.tags
                                  .map((t) => Chip(
                                      label: Text(t,
                                          style: const TextStyle(fontSize: 11)),
                                      backgroundColor: AppColors.sage,
                                      side: BorderSide.none))
                                  .toList()),
                          const SizedBox(height: 36),
                          const Eyebrow('HOW MUCH CAME BACK?'),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                              builder: (context, box) =>
                                  Wrap(spacing: 10, runSpacing: 10, children: [
                                    _rating('Forgot', 'Start again', 1,
                                        AppColors.clay, box.maxWidth),
                                    _rating('Hard', 'Needed effort', 3,
                                        const Color(0xFF91752D), box.maxWidth),
                                    _rating('Good', 'Remembered it', 4,
                                        AppColors.green, box.maxWidth),
                                    _rating('Easy', 'Came naturally', 5,
                                        const Color(0xFF46675E), box.maxWidth),
                                  ])),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 22),
                          Text(_error!,
                              style: const TextStyle(color: AppColors.clay)),
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child:
                                  const Text('Return to the refreshed queue'))
                        ],
                      ],
                    ]))));
  }

  Widget _rating(String label, String detail, int quality, Color color,
          double width) =>
      SizedBox(
          width: width < 520 ? (width - 10) / 2 : (width - 30) / 4,
          child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
                  backgroundColor: color.withValues(alpha: .06)),
              onPressed: _submitting ? null : () => _review(quality),
              child: Column(children: [
                Text(_submitting && _quality == quality ? 'Saving…' : label,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(detail,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 10))
              ])));
}
