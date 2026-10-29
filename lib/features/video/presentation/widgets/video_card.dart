import 'package:flutter/material.dart';

import '../../../../core/domain/models.dart';

class VideoCard extends StatelessWidget {
  const VideoCard({super.key, required this.video});
  final Video video;
  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF455A86),
      const Color(0xFF347B68),
      const Color(0xFFA86656),
    ];
    final icons = [
      Icons.school_outlined,
      Icons.landscape_outlined,
      Icons.palette_outlined,
    ];
    final i = (int.tryParse(video.category.id) ?? 1) - 1;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, '/video', arguments: video.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: colors[i % 3],
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        icons[i % 3],
                        size: 64,
                        color: Colors.white70,
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 16,
                      child: Text(
                        video.category.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 12,
                      bottom: 12,
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(video.channel.name),
                  const SizedBox(height: 4),
                  Text(
                    '${video.createdAt.toLocal().year}-${video.createdAt.toLocal().month.toString().padLeft(2, '0')}-${video.createdAt.toLocal().day.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
