import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/problem.dart';
import '../services/study_store.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class AddProblemScreen extends StatefulWidget {
  final Problem? problem;
  const AddProblemScreen({super.key, this.problem});
  @override
  State<AddProblemScreen> createState() => _AddProblemScreenState();
}

class _AddProblemScreenState extends State<AddProblemScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _url, _title, _tags, _notes;
  late String _difficulty;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final p = widget.problem;
    _url = TextEditingController(text: p?.leetcodeUrl);
    _title = TextEditingController(text: p?.title);
    _tags = TextEditingController(text: p?.tags.join(', '));
    _notes = TextEditingController(text: p?.notes);
    _difficulty = p?.difficulty ?? 'MEDIUM';
  }

  @override
  void dispose() {
    for (final c in [_url, _title, _tags, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<StudyStore>().save({
        'leetcodeUrl': _url.text.trim(),
        'title': _title.text.trim(),
        'difficulty': _difficulty,
        'tags': _tags.text.trim(),
        'notes': _notes.text.trim(),
        if (widget.problem != null) 'version': widget.problem!.version
      }, id: widget.problem?.id);
      if (mounted) {
        showMessage(
            context,
            widget.problem == null
                ? 'Added to your collection.'
                : 'Your notes are saved.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Remove this problem?'),
                content: const Text(
                    'Its notes and review history will also be removed.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Keep it')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Remove problem'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await context.read<StudyStore>().delete(widget.problem!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(widget.problem == null ? 'Add a problem' : 'Your problem',
              style: const TextStyle(fontSize: 16))),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(26, 20, 26, 60),
                  children: [
                    const Eyebrow('SAVE THE IDEA BEHIND THE ANSWER'),
                    const SizedBox(height: 18),
                    Text(
                        widget.problem == null
                            ? 'What did you learn?'
                            : widget.problem!.title,
                        style: editorial(34)),
                    const SizedBox(height: 12),
                    Text(
                        widget.problem == null
                            ? 'A short note today. A useful reminder tomorrow.'
                            : 'Next review: ${widget.problem!.nextReviewDate} · ${widget.problem!.statusLabel}',
                        style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 30),
                    Form(
                        key: _form,
                        child: Column(children: [
                          TextFormField(
                              controller: _url,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                  labelText: 'LeetCode URL',
                                  hintText:
                                      'https://leetcode.com/problems/two-sum/'),
                              validator: (v) {
                                final u = Uri.tryParse(v?.trim() ?? '');
                                return u?.scheme == 'https' &&
                                        u?.host == 'leetcode.com' &&
                                        RegExp(r'^/problems/[a-z0-9-]+(/.*)?$')
                                            .hasMatch(u?.path ?? '')
                                    ? null
                                    : 'Enter a LeetCode problem URL.';
                              }),
                          const SizedBox(height: 18),
                          TextFormField(
                              controller: _title,
                              maxLength: 500,
                              decoration: const InputDecoration(
                                  labelText: 'Problem title'),
                              validator: (v) => (v?.trim().isEmpty ?? true)
                                  ? 'Add a title.'
                                  : null),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                              initialValue: _difficulty,
                              decoration: const InputDecoration(
                                  labelText: 'Difficulty'),
                              items: ['EASY', 'MEDIUM', 'HARD']
                                  .map((d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                          d[0] + d.substring(1).toLowerCase())))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _difficulty = v!)),
                          const SizedBox(height: 18),
                          TextFormField(
                              controller: _tags,
                              maxLength: 2000,
                              decoration: const InputDecoration(
                                  labelText: 'Patterns',
                                  hintText: 'array, hash-map, two-pointers',
                                  helperText:
                                      'Separate patterns with commas.')),
                          const SizedBox(height: 10),
                          TextFormField(
                              controller: _notes,
                              maxLines: 7,
                              maxLength: 20000,
                              decoration: const InputDecoration(
                                  labelText: 'What clicked?',
                                  alignLabelWithHint: true,
                                  hintText:
                                      'The key insight, the edge case you missed, or why this approach works…')),
                        ])),
                    const SizedBox(height: 6),
                    const Text(
                        'Write the approach in your own words. Your future self will thank you.',
                        style: TextStyle(
                            color: AppColors.muted, fontSize: 12, height: 1.7)),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: const TextStyle(color: AppColors.clay))
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving
                            ? 'Saving…'
                            : widget.problem == null
                                ? 'Add to my collection'
                                : 'Save changes')),
                    if (widget.problem != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                          onPressed: () async {
                            final ok = await launchUrl(
                                Uri.parse(widget.problem!.leetcodeUrl),
                                mode: LaunchMode.externalApplication);
                            if (!ok && context.mounted) {
                              showMessage(context, 'Could not open LeetCode.');
                            }
                          },
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Open on LeetCode')),
                      const SizedBox(height: 18),
                      TextButton(
                          onPressed: _saving ? null : _delete,
                          child: const Text('Remove problem',
                              style: TextStyle(color: AppColors.clay)))
                    ],
                  ]))));
}
