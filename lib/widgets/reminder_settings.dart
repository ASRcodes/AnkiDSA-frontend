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
                Text('Your daily review reminder.', style: editorial(30)),
                const SizedBox(height: 12),
                const Text(
                    'Get a morning reminder when questions are due. Tap it to see exactly which questions to revisit today. Your notes stay in the app.'),
                const SizedBox(height: 20),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Daily reminders'),
                  value: reminders.enabled,
                  onChanged: reminders.busy ||
                          (!reminders.available && !reminders.enabled)
                      ? null
                      : reminders.setEnabled,
                ),
                const SizedBox(height: 12),
                const ReminderStatus(),
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

class ReminderStatus extends StatelessWidget {
  const ReminderStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<ReminderService>();
    final String status;
    if (reminders.registered) {
      status =
          'This device is registered for reminders when questions are due.';
    } else if (reminders.enabled) {
      status =
          'Your preference is saved. Device registration has not been confirmed.';
    } else if (reminders.available) {
      status = 'Daily reminders are off for this device.';
    } else {
      status =
          'Daily reminders are unavailable right now. Retry the connection.';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(status),
        if (reminders.error != null) ...[
          const SizedBox(height: 12),
          Text(reminders.error!, style: const TextStyle(color: AppColors.clay)),
        ],
        if (!reminders.available ||
            (reminders.enabled && !reminders.registered) ||
            reminders.error != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: reminders.busy ? null : () => reminders.refresh(),
            icon: const Icon(Icons.refresh),
            label: Text(reminders.busy ? 'Connecting…' : 'Retry connection'),
          ),
        ],
      ],
    );
  }
}
