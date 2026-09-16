import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/reminder_service.dart';
import '../theme.dart';

Future<void> showReminderSettings(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Consumer<ReminderService>(
            builder: (context, reminders, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A little nudge.', style: editorial(30)),
                const SizedBox(height: 12),
                const Text(
                    'Once a day, when you have problems due. Your notes and problem details stay in the app.'),
                const SizedBox(height: 20),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Daily reminders'),
                  value: reminders.enabled,
                  onChanged: reminders.busy ? null : reminders.setEnabled,
                ),
                if (reminders.error != null) ...[
                  const SizedBox(height: 12),
                  Text(reminders.error!,
                      style: const TextStyle(color: AppColors.clay)),
                ],
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
