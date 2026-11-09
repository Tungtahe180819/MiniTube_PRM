import 'package:flutter/material.dart';

import '../../../../core/domain/models.dart';
import '../../../video/data/repositories/video_repository_impl.dart';
import '../../../video/presentation/widgets/video_card.dart';

class ChannelDetailPage extends StatefulWidget {
  const ChannelDetailPage({
    super.key,
    required this.repository,
    required this.id,
  });
  final MockVideoRepository repository;
  final String id;
  @override
  State<ChannelDetailPage> createState() => _ChannelDetailPageState();
}

class _ChannelDetailPageState extends State<ChannelDetailPage> {
  late Future<(Channel, List<Video>)> result;
  Future<(Channel, List<Video>)> load() async => (
    await widget.repository.fetchChannel(widget.id),
    await widget.repository.channelVideos(widget.id),
  );
  @override
  void initState() {
    super.initState();
    result = load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Channel')),
    body: FutureBuilder(
      future: result,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(() => result = load()),
              child: Text('${snapshot.error} — Retry'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final (channel, videos) = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              channel.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(channel.description),
            const SizedBox(height: 24),
            Text('${videos.length} videos'),
            for (final v in videos) VideoCard(video: v),
          ],
        );
      },
    ),
  );
}
