import 'package:flutter/material.dart';

import '../../../../core/validation/validators.dart';
import '../../../auth/presentation/auth_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), avatar = TextEditingController();
  String? loadedId;
  @override
  void dispose() {
    name.dispose();
    avatar.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final auth = AuthScope.of(context);
    try {
      await auth.run(
        () => auth.repository.updateProfile(name.text, avatar.text),
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
    final accepted = await showDialog<bool>(
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
    if (accepted != true || !mounted) return;
    await auth.logout();
    name.clear();
    avatar.clear();
    loadedId = null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context), user = AuthScope.of(context).user;
    if (user == null) {
      loadedId = null;
      name.clear();
      avatar.clear();
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
    }
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
                CircleAvatar(
                  radius: 36,
                  child: Text(
                    user.displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(height: 16),
                Text(user.email, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextFormField(
                  controller: name,
                  enabled: !auth.busy,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  validator: (v) => Validators.requiredText(v, min: 2, max: 50),
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
