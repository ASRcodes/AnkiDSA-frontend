import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';

class Brand extends StatelessWidget {
  final bool inverse;
  const Brand({super.key, this.inverse = false});
  @override
  Widget build(BuildContext context) => Semantics(
      label: 'AnkiDSA',
      image: true,
      child: ExcludeSemantics(
          child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: MediaQuery.withNoTextScaling(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset(
                    inverse
                        ? 'assets/brand/ankidsa-icon-inverse.png'
                        : 'assets/brand/ankidsa-icon.png',
                    width: 43,
                    height: 43,
                    filterQuality: FilterQuality.high),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AnkiDSA',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: inverse ? AppColors.paper : AppColors.dark)),
                  Text('KEEP WHAT YOU LEARN',
                      style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 1.6,
                          color: inverse
                              ? AppColors.paper.withValues(alpha: .65)
                              : AppColors.muted))
                ])
              ])))));
}

class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  const Eyebrow(this.text, {super.key, this.color = AppColors.muted});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.7,
          color: color));
}

class PageBody extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  const PageBody({super.key, required this.children, this.onRefresh});
  @override
  Widget build(BuildContext context) {
    final list = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width < 600 ? 22 : 40,
            30,
            MediaQuery.sizeOf(context).width < 600 ? 22 : 40,
            100),
        children: [
          Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children)))
        ]);
    return onRefresh == null
        ? list
        : RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

class EmptyState extends StatelessWidget {
  final String title, message;
  final IconData icon;
  final Widget? action;
  const EmptyState(
      {super.key,
      required this.title,
      required this.message,
      this.icon = Icons.auto_awesome_outlined,
      this.action});
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Icon(icon, size: 34, color: AppColors.green),
        const SizedBox(height: 18),
        Text(title, style: editorial(24), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.6)),
        if (action != null) ...[const SizedBox(height: 22), action!]
      ]));
}

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const ErrorBanner({super.key, required this.message, required this.retry});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFF4E8DE),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.wifi_off_outlined, color: AppColors.clay),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        TextButton(onPressed: retry, child: const Text('Retry'))
      ]));
}

void showMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

class StudyLoading extends StatefulWidget {
  const StudyLoading({super.key});
  @override
  State<StudyLoading> createState() => _StudyLoadingState();
}

class _StudyLoadingState extends State<StudyLoading> {
  bool _slow = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
      liveRegion: true,
      label: _slow
          ? 'Waking up AnkiDSA. This can take about a minute.'
          : 'Loading your practice',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: 16),
        Text(_slow ? 'Waking up your workspace…' : 'Preparing your practice…',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
            _slow
                ? 'The first connection can take about a minute. You can stay here while we reconnect.'
                : 'Your collection will be here in a moment.',
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 20),
        for (var i = 0; i < 3; i++)
          ExcludeSemantics(
              child: Container(
                  height: 76,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(10)),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                          widthFactor: .6 - i * .1,
                          child:
                              Container(height: 10, color: AppColors.sage))))),
      ]));
}
