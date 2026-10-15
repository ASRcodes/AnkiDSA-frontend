import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/reminder_service.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import '../widgets/reminder_settings.dart';
import 'password_recovery_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final reminders = context.watch<ReminderService?>();
    return PageBody(children: [
      const Eyebrow('YOUR SPACE'),
      const SizedBox(height: 16),
      Semantics(
          container: true,
          header: true,
          child: Text('A practice of your own.', style: editorial(34))),
      const SizedBox(height: 28),
      _section('Profile', Icons.person_outline, [
        Text(auth.name ?? 'Your account',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SelectableText(auth.email ?? '',
            style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 16),
        const Text(
            'Your collection and review history belong to this account. Sign in on another device to pick up where you left off.'),
      ]),
      _section('Reminders', Icons.notifications_outlined, [
        Text(reminders?.available == true
            ? (reminders!.enabled
                ? 'Daily reminders are on for this device.'
                : 'Make a little room for recall each morning.')
            : 'Daily push reminders are available in the configured Android app. Your review queue is always available here.'),
        const SizedBox(height: 12),
        const Text(
            'Morning reminders are best effort during the beta. Delivery time may vary; open your queue any time to see what is due.',
            style: TextStyle(color: AppColors.muted, fontSize: 12)),
        if (reminders?.available == true) ...[
          const SizedBox(height: 16),
          OutlinedButton(
              onPressed: () => showReminderSettings(context),
              child: const Text('Manage reminders')),
        ],
      ]),
      _section('Account security', Icons.lock_outline, [
        const Text(
            'Use a unique password. A password reset signs out existing sessions on all devices.'),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 12, children: [
          OutlinedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen())),
              child: const Text('Reset password')),
          TextButton.icon(
              onPressed: auth.logout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign out')),
        ]),
      ]),
      const Text('AnkiDSA · Keep what you learn',
          style: TextStyle(color: AppColors.muted, fontSize: 12)),
    ]);
  }

  Widget _section(String title, IconData icon, List<Widget> children) =>
      Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 22),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(10)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, size: 20),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)))
            ]),
            const SizedBox(height: 22),
            ...children,
          ]));
}
