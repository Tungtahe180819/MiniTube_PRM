import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/validation/validators.dart';
import '../../../../core/errors/app_exception.dart';
import '../auth_controller.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({
    super.key,
    this.reset = false,
    this.verifyPhone = false,
    this.phone = '',
  });
  final bool reset, verifyPhone;
  final String phone;
  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final form = GlobalKey<FormState>();
  final phone = TextEditingController(),
      code = TextEditingController(),
      current = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  String? challenge, developmentCode, error;
  bool busy = false;
  int remaining = 0;
  Timer? timer;
  bool get usesOtp => widget.reset || widget.verifyPhone;
  @override
  void initState() {
    super.initState();
    phone.text = widget.phone;
  }

  @override
  void dispose() {
    timer?.cancel();
    for (final controller in [phone, code, current, password, confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> requestCode() async {
    if (busy || remaining > 0) return;
    if (phone.text.trim().isEmpty) {
      setState(() => error = 'Enter your phone number.');
      return;
    }
    final auth = AuthScope.of(context);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await auth.repository.requestPhoneCode(
        phone.text,
        reset: widget.reset,
      );
      if (!mounted) return;
      setState(() {
        challenge = result['challengeId'];
        developmentCode = result['developmentCode'];
        remaining = (result['retryAfter'] as num?)?.toInt() ?? 60;
        code.clear();
      });
      startCooldown(remaining);
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString());
        if (e is AppException && e.retryAfter != null) {
          startCooldown(e.retryAfter!);
        }
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void startCooldown(int seconds) {
    timer?.cancel();
    setState(() => remaining = seconds.clamp(0, 900));
    if (remaining == 0) return;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || remaining <= 1) {
        t.cancel();
        if (mounted) {
          setState(() {
            remaining = 0;
            error = null;
          });
        }
      } else {
        setState(() => remaining--);
      }
    });
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    final auth = AuthScope.of(context);
    if (usesOtp && challenge == null) {
      setState(() => error = 'Request a verification code first.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (widget.verifyPhone) {
        await auth.run(
          () => auth.repository.verifyPhone(challenge!, code.text.trim()),
        );
      } else if (widget.reset) {
        await auth.repository.resetPassword(
          challenge!,
          code.text.trim(),
          password.text,
        );
        auth.clearSession();
      } else {
        await auth.repository.changePassword(current.text, password.text);
        auth.clearSession();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.verifyPhone
                ? 'Phone verified.'
                : 'Password updated. Please log in again.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.verifyPhone
              ? 'Verify phone'
              : widget.reset
              ? 'Forgot password'
              : 'Change password',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (usesOtp) ...[
                    Text(
                      widget.verifyPhone
                          ? 'Verify the number saved in your profile.'
                          : 'Use the phone number previously verified in My Profile.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phone,
                      readOnly: widget.verifyPhone,
                      enabled: !busy && challenge == null,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '+84901234567',
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Enter your phone number.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: busy || remaining > 0 ? null : requestCode,
                      child: Text(
                        remaining > 0
                            ? 'Resend in ${remaining}s'
                            : 'Request code',
                      ),
                    ),
                    if (developmentCode != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'DEVELOPMENT ONLY — No SMS sent.\nDemo code: $developmentCode\nExpires in 5 minutes. Maximum 5 attempts.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (challenge != null)
                      TextFormField(
                        controller: code,
                        enabled: !busy,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Verification code',
                        ),
                        validator: (v) => RegExp(r'^\d{6}$').hasMatch(v ?? '')
                            ? null
                            : 'Enter six digits.',
                      ),
                  ] else ...[
                    TextFormField(
                      controller: current,
                      enabled: !busy,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current password',
                      ),
                      validator: (v) => (v ?? '').isEmpty
                          ? 'Enter your current password.'
                          : null,
                    ),
                  ],
                  if (!widget.verifyPhone) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: password,
                      enabled: !busy,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New password',
                      ),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirm,
                      enabled: !busy,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm new password',
                      ),
                      validator: (v) =>
                          v == password.text ? null : 'Passwords do not match.',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'All existing MiniTube sessions will be signed out.',
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
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: busy || usesOtp && challenge == null
                        ? null
                        : submit,
                    child: Text(
                      busy
                          ? 'Please wait…'
                          : widget.verifyPhone
                          ? 'Verify phone'
                          : 'Save new password',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
