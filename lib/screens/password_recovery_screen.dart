import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class RecoveryPage extends StatelessWidget {
  final String title, description;
  final List<Widget> children;
  final VoidCallback onBack;
  const RecoveryPage(
      {super.key,
      required this.title,
      required this.description,
      required this.children,
      required this.onBack});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: onBack)),
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Brand(),
              const SizedBox(height: 44),
              Text(title, style: editorial(36)),
              const SizedBox(height: 16),
              Text(description,
                  style: const TextStyle(color: AppColors.muted, height: 1.6)),
              const SizedBox(height: 30),
              ...children,
              const SizedBox(height: 18),
              TextButton(
                  onPressed: onBack, child: const Text('Back to AnkiDSA')),
            ]),
          ),
        ))),
      );
}

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  final VoidCallback? onDone;
  final ApiService? api;
  const ForgotPasswordScreen(
      {super.key, this.initialEmail = '', this.onDone, this.api});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  late final _api = widget.api ?? ApiService();
  bool _busy = false, _sent = false;
  String? _error;
  void _back() {
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.request('/api/auth/forgot-password',
          method: 'POST', body: {'email': _email.text.trim()});
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RecoveryPage(
        title: _sent ? 'Check your inbox.' : 'Find your way back.',
        description: _sent
            ? 'If an account matches that email, you will receive a reset link. Check your inbox and spam folder. The link is valid for 30 minutes.'
            : 'Enter the email you use for AnkiDSA. We will help you choose a new password.',
        onBack: _back,
        children: [
          if (_sent) ...[
            const Icon(Icons.mark_email_read_outlined,
                size: 44, color: AppColors.green),
            const SizedBox(height: 18),
            TextButton(
                onPressed: () => setState(() => _sent = false),
                child: const Text('Use a different email')),
          ] else
            Form(
                key: _form,
                child: Column(children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(value?.trim() ?? '')
                        ? null
                        : 'Enter a valid email address.',
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    Text(_error!, style: const TextStyle(color: AppColors.clay))
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(_busy ? 'Sending…' : 'Send a reset link'),
                      )),
                ])),
        ],
      );
}

class ResetPasswordScreen extends StatefulWidget {
  final String? token;
  final VoidCallback onDone;
  final Future<void> Function()? onPasswordChanged;
  final ApiService? api;
  const ResetPasswordScreen(
      {super.key,
      required this.token,
      required this.onDone,
      this.onPasswordChanged,
      this.api});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController(),
      _confirmation = TextEditingController();
  late final _api = widget.api ?? ApiService();
  bool _busy = false, _complete = false, _obscure = true;
  String? _error;
  bool get _validToken =>
      RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(widget.token ?? '');
  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.request('/api/auth/reset-password',
          method: 'POST',
          body: {'token': widget.token, 'password': _password.text});
      await widget.onPasswordChanged?.call();
      if (mounted) setState(() => _complete = true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RecoveryPage(
        title: _complete ? 'You are ready to return.' : 'A fresh start.',
        description: _complete
            ? 'Your password has been changed. Sign in with your new password to continue. Previous sessions have been signed out.'
            : 'Choose a password with 10–64 characters that you do not use for another account.',
        onBack: widget.onDone,
        children: [
          if (_complete) ...[
            const Icon(Icons.check_circle_outline,
                size: 44, color: AppColors.green),
            const SizedBox(height: 24),
            SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: widget.onDone,
                    child: const Text('Return to sign in'))),
          ] else if (!_validToken) ...[
            const Text('This recovery link is incomplete. Request a new link.',
                style: TextStyle(color: AppColors.clay)),
            const SizedBox(height: 18),
            FilledButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen())),
                child: const Text('Request a new link')),
          ] else
            Form(
                key: _form,
                child: AutofillGroup(
                    child: Column(children: [
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                        labelText: 'New password',
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        )),
                    validator: (value) =>
                        (value?.length ?? 0) >= 10 && (value?.length ?? 0) <= 64
                            ? null
                            : 'Use 10–64 characters.',
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _confirmation,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(
                        labelText: 'Confirm new password'),
                    validator: (value) => value == _password.text
                        ? null
                        : 'The passwords do not match.',
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    Text(_error!,
                        style: const TextStyle(color: AppColors.clay)),
                    TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen())),
                        child: const Text('Request a new link')),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(_busy ? 'Saving…' : 'Set new password'),
                      )),
                ]))),
        ],
      );
}
