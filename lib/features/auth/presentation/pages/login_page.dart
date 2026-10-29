import 'package:flutter/material.dart';

import '../../../../core/validation/validators.dart';
import '../auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.register = false});
  final bool register;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool hidden = true;
  String? error;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final auth = AuthScope.of(context);
    if (auth.busy || !form.currentState!.validate()) return;
    setState(() => error = null);
    try {
      await auth.run(
        () => widget.register
            ? auth.repository.register(name.text, email.text, password.text)
            : auth.repository.login(email.text, password.text),
      );
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = AuthScope.of(context).busy;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.register ? 'Create account' : 'Login'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.play_circle_fill,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.register ? 'Join MiniTube' : 'Welcome back',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      if (widget.register) ...[
                        TextFormField(
                          controller: name,
                          enabled: !busy,
                          decoration: const InputDecoration(
                            labelText: 'Display name',
                          ),
                          validator: (v) =>
                              Validators.requiredText(v, min: 2, max: 50),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: email,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: password,
                        enabled: !busy,
                        obscureText: hidden,
                        autofillHints: [
                          widget.register
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            tooltip: hidden ? 'Show password' : 'Hide password',
                            onPressed: () => setState(() => hidden = !hidden),
                            icon: Icon(
                              hidden
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: widget.register
                            ? Validators.password
                            : (v) => (v ?? '').isEmpty
                                  ? 'Enter your password.'
                                  : null,
                      ),
                      if (widget.register) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: confirm,
                          enabled: !busy,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                          ),
                          validator: (v) => v == password.text
                              ? null
                              : 'Passwords do not match.',
                        ),
                      ],
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            semanticsLabel: error,
                          ),
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: busy ? null : submit,
                        child: Text(
                          busy
                              ? 'Please wait…'
                              : widget.register
                              ? 'Create account'
                              : 'Login',
                        ),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      LoginPage(register: !widget.register),
                                ),
                              ),
                        child: Text(
                          widget.register
                              ? 'Already have an account? Login'
                              : 'Create an account',
                        ),
                      ),
                      if (!widget.register)
                        const Text(
                          'Demo: demo@minitube.app / Demo1234',
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
