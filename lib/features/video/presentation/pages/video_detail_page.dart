import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/domain/models.dart';
import '../../../../core/validation/validators.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/repositories/video_repository_impl.dart';

class VideoDetailPage extends StatefulWidget {
  const VideoDetailPage({
    super.key,
    required this.repository,
    required this.videoId,
  });
  final MockVideoRepository repository;
  final String videoId;
  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage>
    with WidgetsBindingObserver {
  Video? video;
  VideoPlayerController? player;
  String? error;
  final draft = TextEditingController();
  final form = GlobalKey<FormState>();
  int generation = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initialize();
  }

  Future<void> initialize() async {
    final ticket = ++generation;
    final old = player;
    player = null;
    if (old != null) {
      old.removeListener(changed);
      await old.dispose();
    }
    if (!mounted) return;
    setState(() => error = null);
    try {
      video = widget.repository.video(widget.videoId);
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(video!.videoUrl),
      );
      player = controller;
      await controller.initialize().timeout(const Duration(seconds: 15));
      if (!mounted || generation != ticket) return;
      controller.addListener(changed);
      setState(() {});
    } catch (_) {
      if (mounted && generation == ticket) {
        setState(
          () => error = video == null ? 'This video is no longer available.' : 'Unable to play this video. Check your connection and try again.',
        );
      }
    }
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) player?.pause();
  }

  @override
  void dispose() {
    generation++;
    WidgetsBinding.instance.removeObserver(this);
    player?.removeListener(changed);
    player?.dispose();
    draft.dispose();
    super.dispose();
  }

  String time(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  Future<void> remove(Comment comment) async {
    final user = AuthScope.of(context).user;
    if (user == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete comment?'),
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
        widget.repository.deleteComment(comment.id, user.id);
        setState(() {});
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to delete this comment.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;
    final controller = player;
    final ready = controller?.value.isInitialized == true;
    final failed = error != null || controller?.value.hasError == true;
    final comments = widget.repository.comments(widget.videoId);
    return Scaffold(
      appBar: AppBar(title: const Text('Video details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AspectRatio(
                aspectRatio: ready ? controller!.value.aspectRatio : 16 / 9,
                child: ColoredBox(
                  color: Colors.black,
                  child: failed
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  error ?? 'Unable to play this video.',
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                TextButton(
                                  onPressed: initialize,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ready
                      ? VideoPlayer(controller!)
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
              if (ready && !failed)
                Row(
                  children: [
                    IconButton(
                      tooltip: controller!.value.isPlaying ? 'Pause' : 'Play',
                      onPressed: () => controller.value.isPlaying
                          ? controller.pause()
                          : controller.play(),
                      icon: Icon(
                        controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${time(controller.value.position)} / ${time(controller.value.duration)}',
                    ),
                  ],
                ),
              if (video != null) ...[
                const SizedBox(height: 20),
                Text(
                  video!.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    player?.pause();
                    await Navigator.pushNamed(
                      context,
                      '/channel',
                      arguments: video!.channel.id,
                    );
                    if (mounted) {
                      setState(
                        () => video = widget.repository.video(widget.videoId),
                      );
                    }
                  },
                  child: Text(
                    '${video!.channel.name} · ${video!.category.name}',
                  ),
                ),
                const SizedBox(height: 16),
                Text(video!.description),
                const Divider(height: 40),
                Text(
                  'Comments (${comments.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (user == null)
                  TextButton(
                    onPressed: () {
                      player?.pause();
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('Login to leave a comment'),
                  )
                else
                  Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: draft,
                          maxLength: 500,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Add a comment',
                          ),
                          validator: (v) =>
                              Validators.requiredText(v, max: 500),
                        ),
                        FilledButton(
                          onPressed: () {
                            if (!form.currentState!.validate()) return;
                            widget.repository.addComment(
                              widget.videoId,
                              user,
                              draft.text,
                            );
                            draft.clear();
                            form.currentState!.reset();
                            setState(() {});
                          },
                          child: const Text('Post comment'),
                        ),
                      ],
                    ),
                  ),
                if (comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No comments yet. Start the conversation.'),
                  ),
                for (final comment in comments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      comment.author.id == user?.id
                          ? user!.displayName
                          : comment.author.displayName,
                    ),
                    subtitle: Text(comment.content),
                    trailing: user?.id == comment.author.id
                        ? IconButton(
                            tooltip: 'Delete comment',
                            onPressed: () => remove(comment),
                            icon: const Icon(Icons.delete_outline),
                          )
                        : null,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
