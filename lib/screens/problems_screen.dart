import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/study_store.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import '../widgets/problem_card.dart';
import 'add_problem_screen.dart';

class ProblemsScreen extends StatefulWidget {
  const ProblemsScreen({super.key});
  @override
  State<ProblemsScreen> createState() => _ProblemsScreenState();
}

class _ProblemsScreenState extends State<ProblemsScreen> {
  String _query = '', _difficulty = 'ALL';
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StudyStore>();
    final found = store.problems
        .where((p) =>
            (_difficulty == 'ALL' || p.difficulty == _difficulty) &&
            ('${p.title} ${p.tags.join(' ')}')
                .toLowerCase()
                .contains(_query.toLowerCase()))
        .toList();
    return PageBody(onRefresh: () => store.refresh(), children: [
      const Eyebrow('YOUR PERSONAL PATTERN LIBRARY'),
      const SizedBox(height: 18),
      Text('Worth remembering.',
          style: editorial(MediaQuery.sizeOf(context).width < 600 ? 34 : 44)),
      const SizedBox(height: 12),
      const Text('The problems you solved. The insights you made your own.',
          style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 30),
      TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
              hintText: 'Search a problem or pattern',
              prefixIcon: Icon(Icons.search, size: 21))),
      const SizedBox(height: 16),
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['ALL', 'EASY', 'MEDIUM', 'HARD']
              .map((d) => ChoiceChip(
                  label: Text(d == 'ALL'
                      ? 'All problems'
                      : d[0] + d.substring(1).toLowerCase()),
                  selected: _difficulty == d,
                  onSelected: (_) => setState(() => _difficulty = d),
                  selectedColor: AppColors.sage,
                  showCheckmark: false,
                  side: const BorderSide(color: AppColors.line)))
              .toList()),
      const SizedBox(height: 26),
      if (store.error != null)
        ErrorBanner(message: store.error!, retry: () => store.refresh()),
      if (store.loading && store.stats == null) const LinearProgressIndicator(),
      if (store.stats != null) ...[
        Row(children: [
          Expanded(
              child: Eyebrow(
                  '${found.length} PROBLEM${found.length == 1 ? '' : 'S'}')),
          const Text('Next review first',
              style: TextStyle(color: AppColors.muted, fontSize: 11))
        ]),
        const SizedBox(height: 16),
        if (found.isEmpty)
          EmptyState(
              title: store.problems.isEmpty
                  ? 'A clean page.'
                  : 'No matches this time.',
              message: store.problems.isEmpty
                  ? 'Start with one problem and the idea behind its solution.'
                  : 'Try another title, pattern, or difficulty.',
              icon: Icons.bookmarks_outlined,
              action: store.problems.isEmpty
                  ? OutlinedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddProblemScreen())),
                      child: const Text('Add a problem'))
                  : TextButton(
                      onPressed: () => setState(() => _difficulty = 'ALL'),
                      child: const Text('Show all difficulties'))),
        ...found.map((p) => ProblemCard(
            problem: p,
            showStatus: true,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddProblemScreen(problem: p))))),
      ],
    ]);
  }
}
