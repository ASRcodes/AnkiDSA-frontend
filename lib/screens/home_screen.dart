import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/study_store.dart';
import '../services/reminder_service.dart';
import '../widgets/reminder_settings.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import '../widgets/problem_card.dart';
import 'add_problem_screen.dart';
import 'review_screen.dart';
import 'problems_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _index = 0;
  Timer? _timer;
  StreamSubscription<void>? _reminderOpens;
  bool _active = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reminderOpens = context.read<ReminderService?>()?.queueOpens.listen((_) {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      setState(() => _index = 0);
      context.read<StudyStore>().refresh(silent: true);
    });
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_active && mounted) context.read<StudyStore>().refresh(silent: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      context.read<StudyStore>().refresh(silent: true);
      context.read<ReminderService?>()?.refresh();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reminderOpens?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _add() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const AddProblemScreen()));
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final store = context.watch<StudyStore>();
    final reminders = context.watch<ReminderService?>();
    final content = IndexedStack(
        index: _index,
        children: [_queue(), const ProblemsScreen(), const StatsScreen()]);
    return Scaffold(
        appBar: wide
            ? null
            : AppBar(title: const Brand(), toolbarHeight: 78, actions: [
                IconButton(
                    tooltip: 'Refresh collection',
                    onPressed: store.loading ? null : () => store.refresh(),
                    icon: const Icon(Icons.refresh_rounded, size: 21)),
                PopupMenuButton<String>(
                    tooltip: 'Account',
                    onSelected: (action) => action == 'reminders'
                        ? showReminderSettings(context)
                        : context.read<AuthService>().logout(),
                    itemBuilder: (_) => [
                          if (reminders?.available == true)
                            const PopupMenuItem(
                                value: 'reminders', child: Text('Reminders')),
                          const PopupMenuItem(
                              value: 'logout', child: Text('Sign out'))
                        ])
              ]),
        body: SafeArea(
            child: Row(children: [
          if (wide)
            Container(
              width: 238,
              decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: AppColors.line))),
              padding: const EdgeInsets.fromLTRB(26, 32, 22, 26),
              child: CustomScrollView(slivers: [
                SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Brand(),
                          const SizedBox(height: 54),
                          const Padding(
                              padding: EdgeInsets.only(left: 12),
                              child: Eyebrow('YOUR PRACTICE')),
                          const SizedBox(height: 18),
                          _nav(0, 'Review queue', Icons.inbox_outlined,
                              store.queue.length),
                          _nav(1, 'Collection', Icons.bookmarks_outlined, null),
                          _nav(2, 'Insights', Icons.insights_outlined, null),
                          const SizedBox(height: 30),
                          SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                  onPressed: _add,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add a problem'))),
                          const Spacer(),
                          Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                  color: AppColors.sage,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.spa_outlined, size: 23),
                                    const SizedBox(height: 12),
                                    Text('Small sessions.\nLasting progress.',
                                        style: editorial(18)),
                                    const SizedBox(height: 10),
                                    const Text(
                                        'A few thoughtful minutes can keep a good idea with you.',
                                        style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 11,
                                            height: 1.7))
                                  ])),
                          const SizedBox(height: 24),
                          if (reminders?.available == true)
                            TextButton.icon(
                                onPressed: () => showReminderSettings(context),
                                icon: const Icon(Icons.notifications_outlined),
                                label: const Text('Reminders')),
                          Row(children: [
                            CircleAvatar(
                                radius: 17,
                                backgroundColor: AppColors.sage,
                                child: Text(
                                    (context.watch<AuthService>().name ?? 'A')
                                        .characters
                                        .first
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.green))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(
                                    context.watch<AuthService>().name ??
                                        'My account',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12))),
                            IconButton(
                                tooltip: 'Sign out',
                                onPressed: () =>
                                    context.read<AuthService>().logout(),
                                icon: const Icon(Icons.logout, size: 18))
                          ])
                        ]))
              ]),
            ),
          Expanded(child: content)
        ])),
        floatingActionButton: wide
            ? null
            : FloatingActionButton.extended(
                onPressed: _add,
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Add problem')),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                backgroundColor: AppColors.paper,
                indicatorColor: AppColors.sage,
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: const [
                    NavigationDestination(
                        icon: Icon(Icons.inbox_outlined), label: 'Review'),
                    NavigationDestination(
                        icon: Icon(Icons.bookmarks_outlined),
                        label: 'Collection'),
                    NavigationDestination(
                        icon: Icon(Icons.insights_outlined), label: 'Insights')
                  ]));
  }

  Widget _nav(int index, String title, IconData icon, int? count) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
          color: _index == index ? AppColors.sage : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => setState(() => _index = index),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  child: Row(children: [
                    Icon(icon,
                        size: 19,
                        color: _index == index
                            ? AppColors.green
                            : AppColors.muted),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(title,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: _index == index
                                    ? FontWeight.w700
                                    : FontWeight.w500))),
                    if (count != null)
                      Text('$count',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted))
                  ])))));
  Widget _queue() {
    final store = context.watch<StudyStore>(),
        queue = context.watch<StudyStore>().queue;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final showProgressRing =
        !narrow && MediaQuery.textScalerOf(context).scale(14) < 20;
    final today = DateTime.tryParse(store.stats?.today ?? '') ?? DateTime.now();
    return PageBody(onRefresh: () => store.refresh(), children: [
      Row(children: [
        Expanded(child: Eyebrow(DateFormat('EEEE, d MMMM').format(today))),
        if (!narrow)
          IconButton(
              tooltip: 'Refresh collection',
              onPressed: store.loading ? null : () => store.refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 19))
      ]),
      const SizedBox(height: 18),
      Text('Your daily practice.', style: editorial(narrow ? 34 : 44)),
      const SizedBox(height: 12),
      const Text('A few familiar problems. A little stronger recall.',
          style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 30),
      if (store.error != null)
        ErrorBanner(message: store.error!, retry: () => store.refresh()),
      if (store.loading && store.stats == null) const LinearProgressIndicator(),
      if (store.stats != null) ...[
        Container(
            width: double.infinity,
            padding: EdgeInsets.all(narrow ? 25 : 34),
            decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Eyebrow('A MOMENT FOR YOUR MEMORY',
                        color: Color(0xFFB6CEAF)),
                    const SizedBox(height: 16),
                    Text(
                        queue.isEmpty
                            ? 'Room for something new.'
                            : '${queue.length} idea${queue.length == 1 ? '' : 's'} to revisit.',
                        style: editorial(narrow ? 28 : 35,
                            color: AppColors.paper)),
                    const SizedBox(height: 12),
                    Text(
                        queue.isEmpty
                            ? 'Your review queue is clear. Come back tomorrow.'
                            : 'Recall the pattern. Check your notes. Let it settle.',
                        style: const TextStyle(
                            color: Color(0xFFC9D9CB),
                            fontSize: 12,
                            height: 1.7)),
                    if (!showProgressRing) ...[
                      const SizedBox(height: 12),
                      Text('${store.stats!.reviewsToday} reviewed today',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFC9D9CB))),
                    ],
                    if (queue.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.paper,
                              foregroundColor: AppColors.green),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ReviewScreen(problem: queue.first))),
                          icon: const Icon(Icons.arrow_forward, size: 17),
                          label: const Text('Begin a review'))
                    ],
                  ])),
              if (showProgressRing) ...[
                const SizedBox(width: 24),
                SizedBox(
                    width: 106,
                    height: 106,
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                              value:
                                  store.stats!.reviewsToday + queue.length == 0
                                      ? 1
                                      : store.stats!.reviewsToday /
                                          (store.stats!.reviewsToday +
                                              queue.length),
                              strokeWidth: 3,
                              backgroundColor: const Color(0xFF52745D),
                              color: const Color(0xFFD9E4BD))),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${store.stats!.reviewsToday}',
                            style: editorial(32, color: AppColors.paper)),
                        const Text('reviewed today',
                            style: TextStyle(
                                fontSize: 9, color: Color(0xFFC9D9CB)))
                      ])
                    ]))
              ]
            ])),
        const SizedBox(height: 30),
        SizedBox(
            width: double.infinity,
            child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 16,
                runSpacing: 8,
                children: [
                  const Eyebrow('READY WHEN YOU ARE'),
                  Text(
                      store.stats!.overdueCount > 0
                          ? '${store.stats!.overdueCount} carried forward'
                          : 'One problem at a time',
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 11))
                ])),
        const SizedBox(height: 16),
        if (queue.isEmpty)
          EmptyState(
              title: store.problems.isEmpty
                  ? 'Your collection starts here.'
                  : 'A good place to pause.',
              message: store.problems.isEmpty
                  ? 'Add a problem you have solved, along with the insight you want to keep.'
                  : 'You have revisited everything due today.\nYour next session will be here when it is time.',
              icon: Icons.check_circle_outline,
              action: store.problems.isEmpty
                  ? OutlinedButton(
                      onPressed: _add,
                      child: const Text('Add my first problem'))
                  : null),
        ...queue.asMap().entries.map((e) => ProblemCard(
            problem: e.value,
            number: e.key + 1,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ReviewScreen(problem: e.value))))),
      ],
    ]);
  }
}
