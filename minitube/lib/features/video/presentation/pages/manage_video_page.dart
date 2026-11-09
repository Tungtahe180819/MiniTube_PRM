import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../data/repositories/remote_video_repository.dart';

import 'package:file_picker/file_picker.dart';

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
  String? loadError;
  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if (widget.repository is RemoteVideoRepository) {
      try {
        await (widget.repository as RemoteVideoRepository).loadMine();
        if (mounted) setState(() => loadError = null);
      } catch (e) {
        if (mounted) setState(() => loadError = e.toString());
      }
    }
  }

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
      try {
        await widget.repository.removeVideo(v.id, user);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
      if (!mounted) return;
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
                if (loadError != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(loadError!),
                        TextButton(
                          onPressed: reload,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  );
                }
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
      mediaPath = TextEditingController(),
      thumbnail = TextEditingController();
  String category = '1';
  String? selectedName, fileError;
  PlatformFile? selectedFile;
  bool uploading = false;
  bool dirty = false, saved = false;
  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      final v = widget.repository.video(widget.id!);
      title.text = v.title;
      description.text = v.description;
      mediaPath.text = v.videoUrl;
      thumbnail.text = v.thumbnailUrl ?? '';
      category = v.category.id;
    }
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    mediaPath.dispose();
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
      canPop: !uploading && (!dirty || saved),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !uploading) leave();
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
                            OutlinedButton.icon(
                              onPressed: uploading
                                  ? null
                                  : () async {
                                      try {
                                        final result = await FilePicker.platform
                                            .pickFiles(
                                              type: FileType.custom,
                                              allowedExtensions: ['mp4'],
                                              withData: kIsWeb,
                                            );
                                        if (result == null || !mounted) return;
                                        final file = result.files.single;
                                        if (file.size == 0 ||
                                            file.size > 100 * 1024 * 1024 ||
                                            !file.name.toLowerCase().endsWith(
                                              '.mp4',
                                            ) ||
                                            (file.path == null &&
                                                file.bytes == null &&
                                                file.readStream == null)) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Choose a readable MP4 file up to 100 MB.',
                                                    ),
                                                  ),
                                                );
                                          }
                                          return;
                                        }
                                        setState(() {
                                          mediaPath.text =
                                              file.path ?? file.name;
                                          selectedFile = file;
                                          fileError = null;
                                          selectedName = file.name;
                                          dirty = true;
                                        });
                                      } catch (_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Unable to read video. Please choose another file.',
                                                  ),
                                                ),
                                              );
                                        }
                                      }
                                    },
                              icon: const Icon(Icons.video_file_outlined),
                              label: Text(
                                widget.id == null
                                    ? 'Choose video from device'
                                    : 'Replace video file',
                              ),
                            ),
                            Text(
                              selectedName ??
                                  (widget.id == null
                                      ? 'No file selected. MP4, maximum 100 MB.'
                                      : 'Keep current video unless a replacement is selected.'),
                            ),
                            if (fileError != null)
                              Text(
                                fileError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
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
                            if (uploading &&
                                widget.repository is RemoteVideoRepository)
                              ValueListenableBuilder<double?>(
                                valueListenable:
                                    (widget.repository as RemoteVideoRepository)
                                        .uploadProgress,
                                builder: (context, progress, child) => Column(
                                  children: [
                                    LinearProgressIndicator(value: progress),
                                    const SizedBox(height: 8),
                                    Text(
                                      progress == null
                                          ? 'Preparing upload…'
                                          : progress >= 1
                                          ? 'File sent. Server is saving…'
                                          : 'Uploading ${(progress * 100).floor()}%',
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          (widget.repository
                                                  as RemoteVideoRepository)
                                              .cancelUpload(),
                                      child: const Text('Cancel upload'),
                                    ),
                                  ],
                                ),
                              ),
                            FilledButton(
                              onPressed: uploading
                                  ? null
                                  : () async {
                                      setState(
                                        () => fileError =
                                            mediaPath.text.trim().isEmpty
                                            ? 'Choose a video file from your device.'
                                            : null,
                                      );
                                      if (!form.currentState!.validate() ||
                                          fileError != null) {
                                        return;
                                      }
                                      setState(() => uploading = true);
                                      try {
                                        await widget.repository.persistVideo(
                                          user,
                                          VideoWrite(
                                            title: title.text,
                                            description: description.text,
                                            localVideoPath: mediaPath.text,
                                            thumbnailUrl:
                                                thumbnail.text.trim().isEmpty
                                                ? null
                                                : thumbnail.text.trim(),
                                            categoryId: category,
                                          ),
                                          id: widget.id,
                                          file: selectedFile,
                                        );
                                        if (!mounted) return;
                                        setState(() => saved = true);
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (mounted) {
                                                Navigator.pop(context);
                                              }
                                            });
                                      } catch (e) {
                                        if (mounted) {
                                          setState(
                                            () => fileError = e.toString(),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => uploading = false);
                                        }
                                      }
                                    },
                              child: Text(
                                uploading
                                    ? 'Uploading…'
                                    : widget.id == null
                                    ? 'Add video from file'
                                    : 'Save changes',
                              ),
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
