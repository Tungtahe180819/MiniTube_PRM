import 'package:flutter/material.dart';

import '../../../../core/validation/validators.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../video/data/repositories/video_repository_impl.dart';

class MyChannelPage extends StatefulWidget {
  const MyChannelPage({super.key, required this.repository});
  final MockVideoRepository repository;
  @override
  State<MyChannelPage> createState() => _MyChannelPageState();
}

class _MyChannelPageState extends State<MyChannelPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      description = TextEditingController(),
      avatar = TextEditingController();
  bool loaded = false, busy = false;
  bool loading = true;
  String? loadError;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!loaded) {
      loaded = true;
      load();
    }
  }

  Future<void> load() async {
    final user = AuthScope.of(context).user;
    if (user == null) return;
    try {
      final c = await widget.repository.fetchMyChannel(user);
      if (!mounted) return;
      setState(() {
        loading = false;
        name.text = c.name;
        description.text = c.description;
        avatar.text = c.avatarUrl ?? '';
        loadError = null;
      });
    } catch (e) {
      if (mounted) setState(() => loadError = e.toString());
    }
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    avatar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;
    return Scaffold(
      appBar: AppBar(title: const Text('My channel')),
      body: user != null && loading && loadError == null
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
          ? Center(
              child: TextButton(
                onPressed: load,
                child: Text("$loadError — Retry"),
              ),
            )
          : user == null
          ? const Center(child: Text('Please login to manage your channel.'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Form(
                      key: form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: name,
                            decoration: const InputDecoration(
                              labelText: 'Channel name',
                            ),
                            validator: (v) =>
                                Validators.requiredText(v, min: 2, max: 80),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: description,
                            maxLines: 4,
                            maxLength: 1000,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                            ),
                            validator: (v) => (v ?? '').trim().length > 1000
                                ? 'Maximum 1,000 characters.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: avatar,
                            decoration: const InputDecoration(
                              labelText: 'Avatar URL (optional)',
                            ),
                            validator: Validators.httpsUrl,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: busy
                                ? null
                                : () async {
                                    if (!form.currentState!.validate()) return;
                                    setState(() => busy = true);
                                    try {
                                      await widget.repository.saveChannel(
                                        user,
                                        name.text,
                                        description.text,
                                        avatar.text.trim().isEmpty
                                            ? null
                                            : avatar.text.trim(),
                                      );
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(this.context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text('Changes saved.'),
                                            ),
                                          );
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          this.context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );
                                      }
                                    } finally {
                                      if (mounted) setState(() => busy = false);
                                    }
                                  },
                            child: Text(busy ? 'Saving…' : 'Save channel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/manage'),
                            child: const Text('Manage videos'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
