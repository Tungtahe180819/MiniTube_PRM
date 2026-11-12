import 'package:flutter/material.dart';

import '../../../../core/validation/validators.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../auth/presentation/pages/password_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      avatar = TextEditingController(),
      phone = TextEditingController(),
      birth = TextEditingController(),
      bio = TextEditingController();
  String? loadedId, gender;
  @override
  void dispose() {
    for (final c in [name, avatar, phone, birth, bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final auth = AuthScope.of(context);
    try {
      await auth.run(
        () => auth.repository.updateProfile(
          name.text,
          avatar.text,
          phoneNumber: phone.text,
          dateOfBirth: birth.text,
          gender: gender ?? '',
          bio: bio.text,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Changes saved.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> logout() async {
    final auth = AuthScope.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Unsaved profile changes will be discarded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      await auth.logout();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context), user = AuthScope.of(context).user;
    if (user == null) {
      loadedId = null;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle_outlined, size: 64),
            const SizedBox(height: 16),
            const Text('Login to manage your profile'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }
    if (loadedId != user.id) {
      loadedId = user.id;
      name.text = user.displayName;
      avatar.text = user.avatarUrl ?? '';
      phone.text = user.phoneNumber ?? '';
      birth.text = user.dateOfBirth ?? '';
      bio.text = user.bio;
      gender = user.gender;
    }
    final initial = user.displayName.isEmpty
        ? '?'
        : user.displayName.substring(0, 1).toUpperCase();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: const Text('My channel'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/my-channel'),
                ),
                ListTile(
                  title: const Text('Manage videos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/manage'),
                ),
                Center(
                  child: ClipOval(
                    child: user.avatarUrl?.isNotEmpty == true
                        ? Image.network(
                            user.avatarUrl!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            webHtmlElementStrategy:
                                WebHtmlElementStrategy.prefer,
                            errorBuilder: (_, e, s) => CircleAvatar(
                              radius: 36,
                              child: Text(
                                initial,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 36,
                            child: Text(
                              initial,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: user.email,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email (read-only)',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: name,
                  enabled: !auth.busy,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  validator: (v) => Validators.requiredText(v, min: 2, max: 50),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phone,
                  enabled: !auth.busy,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone number (optional)',
                    hintText: '+84901234567',
                    helperText: user.phoneVerified
                        ? 'Saved phone verified'
                        : 'Save, then verify to enable password recovery',
                  ),
                  validator: (v) {
                    final p = (v ?? '').replaceAll(RegExp(r'[\s()-]'), '');
                    return p.isEmpty ||
                            RegExp(r'^(0\d{9}|\+[1-9]\d{7,14})$').hasMatch(p)
                        ? null
                        : 'Enter a valid phone number.';
                  },
                ),
                if (user.phoneNumber != null && !user.phoneVerified)
                  TextButton(
                    onPressed: auth.busy
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => PasswordPage(
                                verifyPhone: true,
                                phone: user.phoneNumber!,
                              ),
                            ),
                          ),
                    child: const Text('Verify saved phone'),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: birth,
                  readOnly: true,
                  enabled: !auth.busy,
                  decoration: InputDecoration(
                    labelText: 'Date of birth (optional)',
                    suffixIcon: IconButton(
                      onPressed: auth.busy
                          ? null
                          : () => setState(() => birth.clear()),
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                  onTap: () async {
                    final now = DateTime.now();
                    final selected = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.tryParse(birth.text) ??
                          DateTime(now.year - 18),
                      firstDate: DateTime(1900),
                      lastDate: now,
                    );
                    if (selected != null && mounted) {
                      setState(
                        () => birth.text =
                            '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}',
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender (optional)',
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Not specified')),
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                    DropdownMenuItem(
                      value: 'prefer_not_to_say',
                      child: Text('Prefer not to say'),
                    ),
                  ],
                  onChanged: auth.busy
                      ? null
                      : (v) => setState(() => gender = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: bio,
                  enabled: !auth.busy,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio (optional)',
                  ),
                  validator: (v) => (v ?? '').trim().length > 500
                      ? 'Maximum 500 characters.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: avatar,
                  enabled: !auth.busy,
                  decoration: const InputDecoration(
                    labelText: 'Avatar URL (optional)',
                  ),
                  validator: Validators.httpsUrl,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: auth.busy ? null : save,
                  child: Text(auth.busy ? 'Please wait…' : 'Save profile'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: auth.busy
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const PasswordPage(),
                          ),
                        ),
                  child: const Text('Change password'),
                ),
                OutlinedButton(
                  onPressed: auth.busy || user.googleLinked
                      ? null
                      : () async {
                          try {
                            await auth.run(auth.repository.linkGoogle);
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Google account linked.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                  child: Text(
                    user.googleLinked ? 'Google linked' : 'Link Google account',
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: auth.busy ? null : logout,
                  child: const Text('Log out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
