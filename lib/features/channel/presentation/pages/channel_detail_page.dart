import 'package:flutter/material.dart';

import '../../../video/data/repositories/video_repository_impl.dart';
import '../../../video/presentation/widgets/video_card.dart';

class ChannelDetailPage extends StatelessWidget {
  const ChannelDetailPage({
    super.key,
    required this.repository,
    required this.id,
  });
  final MockVideoRepository repository;
  final String id;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Channel')),
    body: ValueListenableBuilder(
      valueListenable: repository.revision,
      builder: (context, _, child) {
        final channel = repository.channel(id);
        final videos =
            repository.items.where((v) => v.channel.id == id).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
