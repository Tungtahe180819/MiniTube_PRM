import 'package:flutter/material.dart';

import '../../../../core/domain/models.dart';
import '../../../../core/validation/validators.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/repositories/video_repository_impl.dart';

class ManageVideoPage extends StatefulWidget {
  const ManageVideoPage({super.key, required this.repository});
  final MockVideoRepository repository;
  @override
  State<ManageVideoPage> createState() => _ManageVideoPageState();
}

class _ManageVideoPageState extends State<ManageVideoPage> {
  Future<void> remove(Video v, User user) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete video?'),
        content: const Text(
          'Related comments and watch history will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      widget.repository.deleteVideo(v.id, user);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;
    return Scaffold(
      appBar: AppBar(title: const Text('Manage videos')),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton(
              tooltip: 'Add video',
              onPressed: () async {
                await Navigator.pushNamed(context, '/add');
                if (mounted) setState(() {});
              },
              child: const Icon(Icons.add),
            ),
      body: user == null
          ? const Center(child: Text('Please login to manage videos.'))
          : ValueListenableBuilder(
              valueListenable: widget.repository.revision,
              builder: (context, _, child) {
                final videos =
                    widget.repository.items
                        .where((v) => v.channel.ownerId == user.id)
                        .toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return videos.isEmpty
                    ? const Center(
                        child: Text('No videos yet. Add your first video.'),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 90),
                        children: [
                          for (final v in videos)
                            ListTile(
                              title: Text(v.title),
                              subtitle: Text(v.category.name),
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/video',
                                arguments: v.id,
                              ),
                              trailing: Wrap(
                                children: [
                                  IconButton(
                                    tooltip: 'Edit video',
                                    onPressed: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        '/edit',
                                        arguments: v.id,
                                      );
                                      if (mounted) setState(() {});
                                    },
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete video',
                                    onPressed: () => remove(v, user),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
              },
            ),
    );
  }
}

class VideoEditorPage extends StatefulWidget {
  const VideoEditorPage({super.key, required this.repository, this.id});
  final MockVideoRepository repository;
  final String? id;
  @override
  State<VideoEditorPage> createState() => _VideoEditorPageState();
}

class _VideoEditorPageState extends State<VideoEditorPage> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(),
      description = TextEditingController(),
      url = TextEditingController(),
      thumbnail = TextEditingController();
  String category = '1';
  bool dirty = false, saved = false;
  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      final v = widget.repository.video(widget.id!);
      title.text = v.title;
      description.text = v.description;
      url.text = v.videoUrl;
      thumbnail.text = v.thumbnailUrl ?? '';
      category = v.category.id;
    }
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    url.dispose();
    thumbnail.dispose();
    super.dispose();
  }

  Future<void> leave() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Discard your unsaved changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      setState(() => saved = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;
    final allowed =
        user != null &&
        (widget.id == null ||
            widget.repository.video(widget.id!).channel.ownerId == user.id);
    return PopScope(
      canPop: !dirty || saved,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.id == null ? 'Add video' : 'Edit video'),
        ),
        body: !allowed
            ? const Center(
                child: Text(
                  'You do not have permission to perform this action.',
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Form(
                        key: form,
                        onChanged: () {
                          if (!dirty) setState(() => dirty = true);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: title,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                              ),
                              validator: (v) => Validators.requiredText(v),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: description,
                              maxLines: 4,
                              maxLength: 2000,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                              ),
                              validator: (v) => (v ?? '').trim().length > 2000
                                  ? 'Maximum 2,000 characters.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: url,
                              decoration: const InputDecoration(
                                labelText: 'Video URL (HTTPS MP4)',
                              ),
                              validator: (v) =>
                                  Validators.httpsUrl(v, required: true),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: thumbnail,
                              decoration: const InputDecoration(
                                labelText: 'Thumbnail URL (optional)',
                              ),
                              validator: Validators.httpsUrl,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: category,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                              items: [
                                for (final c
                                    in MockVideoRepository.categoryList)
                                  DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                              ],
                              onChanged: (v) => setState(() {
                                category = v!;
                                dirty = true;
                              }),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () {
                                if (!form.currentState!.validate()) return;
                                widget.repository.saveVideo(
                                  user,
                                  VideoWrite(
                                    title: title.text,
                                    description: description.text,
                                    videoUrl: url.text,
                                    thumbnailUrl: thumbnail.text.trim().isEmpty
                                        ? null
                                        : thumbnail.text.trim(),
                                    categoryId: category,
                                  ),
                                  id: widget.id,
                                );
                                setState(() => saved = true);
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) Navigator.pop(context);
                                });
                              },
                              child: const Text('Save video'),
                            ),
                          ],
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
