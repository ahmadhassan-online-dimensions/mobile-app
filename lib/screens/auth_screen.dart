import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Same sign-in options as the website: Continue with Google, or email
/// (POST /users/login, /users/register, /users/google). Pops `true` on success.
class AuthScreen extends StatefulWidget {
  final String? reason;

  const AuthScreen({super.key, this.reason});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false;
  bool busy = false;
  bool hidePassword = true;
  String? error;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _submit() {
    if (!form.currentState!.validate()) return;
    final state = AppScope.read(context);
    _run(
      () => register ? state.register(name.text, email.text, password.text) : state.signIn(email.text, password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: const Border(),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Wordmark(size: 18),
      ),
      body: SafeArea(
        child: Form(
          key: form,
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              children: [
                Eyebrow(register ? 'New client' : 'Welcome back'),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: register
                      ? const SplitHeading('Create your\n', italic: 'account.', key: ValueKey('r'))
                      : const SplitHeading('Sign ', italic: 'in.', key: ValueKey('s')),
                ),
                const SizedBox(height: 10),
                Text(widget.reason ?? 'Your bag and orders, on every device.', style: AppText.body()),
                const SizedBox(height: 28),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.paper,
                    side: const BorderSide(color: AppColors.lineStrong),
                    minimumSize: const Size(48, 56),
                  ),
                  onPressed: busy ? null : () => _run(AppScope.read(context).signInWithGoogle),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'G',
                        style: AppText.sans(size: 18, weight: FontWeight.w700, color: const Color(0xFF4285F4)),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Continue with Google',
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(size: 15, weight: FontWeight.w500, color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR USE YOUR EMAIL', style: AppText.caps(size: 10.5)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  child: register
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: name,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(labelText: 'Name'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim())
                      ? null
                      : 'Please enter a valid email',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: password,
                  obscureText: hidePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: [register ? AutofillHints.newPassword : AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: register ? 'At least 6 characters' : null,
                    suffixIcon: IconButton(
                      tooltip: hidePassword ? 'Show password' : 'Hide password',
                      icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                      onPressed: () => setState(() => hidePassword = !hidePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your password';
                    if (register && v.length < 6) return 'Use at least 6 characters';
                    return null;
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: 14),
                  Semantics(
                    liveRegion: true,
                    child: Text(error!, style: AppText.sans(size: 14, color: AppColors.error)),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: busy ? null : _submit,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(register ? 'CREATE ACCOUNT' : 'SIGN IN'),
                ),
                const SizedBox(height: 14),
                Center(
                  child: UnderlineLink(
                    register ? 'Already a client? Sign in' : 'New here? Create an account',
                    color: AppColors.gold,
                    onTap: busy
                        ? null
                        : () => setState(() {
                            register = !register;
                            error = null;
                          }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
