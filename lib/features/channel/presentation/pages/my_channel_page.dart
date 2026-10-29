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
  bool loaded = false;
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
    if (user != null && !loaded) {
      final c = widget.repository.myChannel(user);
      name.text = c.name;
      description.text = c.description;
      avatar.text = c.avatarUrl ?? '';
      loaded = true;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My channel')),
      body: user == null
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
                            onPressed: () {
                              if (!form.currentState!.validate()) return;
                              widget.repository.updateChannel(
                                user,
                                name.text,
                                description.text,
                                avatar.text.trim().isEmpty
                                    ? null
                                    : avatar.text.trim(),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Changes saved.')),
                              );
                            },
                            child: const Text('Save channel'),
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
