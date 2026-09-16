import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'password_recovery_screen.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _register = false, _loading = false, _obscure = true;
  String? _error;
  bool _recoveryAvailable = false;
  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final api = ApiService();
    try {
      final options = await api.request('/api/auth/options');
      if (mounted) {
        setState(
            () => _recoveryAvailable = options['passwordRecovery'] == true);
      }
    } catch (_) {
      // Sign-in remains available when optional account settings cannot be loaded.
    } finally {
      api.dispose();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().authenticate(
          _email.text, _password.text, _name.text,
          register: _register);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final form = Center(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: AutofillGroup(
                    child: Form(
                        key: _form,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!wide) ...[
                                const Brand(),
                                const SizedBox(height: 48)
                              ],
                              const Eyebrow('A little every day'),
                              const SizedBox(height: 16),
                              Text(
                                  _register
                                      ? 'Make it\nstay with you.'
                                      : 'Back for\nanother good day.',
                                  style: editorial(40)),
                              const SizedBox(height: 18),
                              Text(
                                  _register
                                      ? 'Build a collection of ideas you can call on.'
                                      : 'Your patterns are waiting. Pick up where you left off.',
                                  style: const TextStyle(
                                      color: AppColors.muted, height: 1.6)),
                              const SizedBox(height: 32),
                              if (_register) ...[
                                TextFormField(
                                    controller: _name,
                                    autofillHints: const [AutofillHints.name],
                                    decoration: const InputDecoration(
                                        labelText: 'Your name'),
                                    maxLength: 80),
                                const SizedBox(height: 16)
                              ],
                              TextFormField(
                                  controller: _email,
                                  autofillHints: const [AutofillHints.email],
                                  keyboardType: TextInputType.emailAddress,
                                  decoration:
                                      const InputDecoration(labelText: 'Email'),
                                  validator: (v) =>
                                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                              .hasMatch(v?.trim() ?? '')
                                          ? null
                                          : 'Enter a valid email address.'),
                              const SizedBox(height: 16),
                              TextFormField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  autofillHints: [
                                    _register
                                        ? AutofillHints.newPassword
                                        : AutofillHints.password
                                  ],
                                  decoration: InputDecoration(
                                      labelText: 'Password',
                                      helperText: _register
                                          ? 'At least 10 characters.'
                                          : '',
                                      suffixIcon: IconButton(
                                          tooltip: _obscure
                                              ? 'Show password'
                                              : 'Hide password',
                                          icon: Icon(
                                              _obscure
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                              size: 20),
                                          onPressed: () => setState(
                                              () => _obscure = !_obscure))),
                                  validator: (v) => (v?.length ?? 0) >= 10 &&
                                          (v?.length ?? 0) <= 64
                                      ? null
                                      : 'Use 10–64 characters.',
                                  onFieldSubmitted: (_) {
                                    if (!_loading) _submit();
                                  }),
                              if (!_register && _recoveryAvailable)
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _loading
                                          ? null
                                          : () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      ForgotPasswordScreen(
                                                          initialEmail: _email
                                                              .text
                                                              .trim()))),
                                      child:
                                          const Text('Forgot your password?'),
                                    )),
                              if (_error != null ||
                                  context.watch<AuthService>().startupError !=
                                      null) ...[
                                const SizedBox(height: 16),
                                Text(
                                    _error ??
                                        context
                                            .read<AuthService>()
                                            .startupError!,
                                    style:
                                        const TextStyle(color: AppColors.clay))
                              ],
                              const SizedBox(height: 24),
                              SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                      onPressed: _loading ? null : _submit,
                                      child: _loading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2))
                                          : Text(_register
                                              ? 'Create my account'
                                              : 'Sign in'))),
                              const SizedBox(height: 12),
                              TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () => setState(() {
                                            _register = !_register;
                                            _error = null;
                                          }),
                                  child: Text(_register
                                      ? 'Already have an account? Sign in'
                                      : 'New here? Create an account')),
                              if (const bool.fromEnvironment('DEMO_MODE'))
                                TextButton(
                                    onPressed: () {
                                      _email.text = 'demo@ankidsa.local';
                                      _password.text = 'DemoRecall!2026';
                                      setState(() => _register = false);
                                    },
                                    child: const Text('Fill demo account')),
                              const SizedBox(height: 30),
                              const Text(
                                  'Remember the approach. Trust your practice.',
                                  style: TextStyle(
                                      color: AppColors.muted, fontSize: 11)),
                            ]))))));
    return Scaffold(
        body: SafeArea(
            child: wide
                ? Row(children: [
                    Expanded(
                        child: Container(
                            color: AppColors.green,
                            padding: const EdgeInsets.all(56),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Brand(inverse: true),
                                  const Spacer(),
                                  const Eyebrow('FOR THE IDEAS WORTH KEEPING',
                                      color: Color(0xFFAEC7AF)),
                                  const SizedBox(height: 24),
                                  Text(
                                      'You solved it.\nNow make it\nsecond nature.',
                                      style: editorial(56,
                                          color: AppColors.paper)),
                                  const SizedBox(height: 28),
                                  const Text(
                                      'A thoughtful place to revisit your DSA patterns.\nLess starting over. More moving forward.',
                                      style: TextStyle(
                                          color: Color(0xFFC7D7CA),
                                          height: 1.8,
                                          fontSize: 15)),
                                  const SizedBox(height: 56),
                                  Row(
                                      children: List.generate(
                                          4,
                                          (i) => Expanded(
                                              child: Container(
                                                  height: 4,
                                                  margin: const EdgeInsets.only(
                                                      right: 12),
                                                  color: Color.lerp(
                                                      const Color(0xFF486B55),
                                                      const Color(0xFFD4DDBC),
                                                      i / 3))))),
                                  const SizedBox(height: 12),
                                  const Text(
                                      'RECALL     →     REFLECT     →     REPEAT',
                                      style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 1.7,
                                          color: Color(0xFFAEC7AF))),
                                  const Spacer(),
                                  const Text(
                                      'A LITTLE PRACTICE, LASTING RECALL.',
                                      style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 1.6,
                                          color: Color(0xFFAEC7AF))),
                                ]))),
                    Expanded(child: form)
                  ])
                : form));
  }
}
