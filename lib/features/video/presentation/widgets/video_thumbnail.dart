import 'package:flutter/material.dart';

class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({super.key, required this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) return const SizedBox.shrink();
    return Image.network(
      url!,
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (context, error, stack) => const SizedBox.shrink(),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
