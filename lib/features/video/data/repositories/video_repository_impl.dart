import 'package:flutter/foundation.dart' show ValueNotifier;

import '../../../../core/domain/models.dart';
import '../../domain/repositories/video_repository.dart';

class MockVideoRepository implements VideoRepository {
  final revision = ValueNotifier<int>(0);
  static const categoryList = [
    Category('1', 'Learning'),
    Category('2', 'Nature'),
    Category('3', 'Creative'),
  ];
  late final List<Video> items = List.generate(45, (i) {
    final category = categoryList[i % 3];
    final subjects = [
      'Flutter layouts',
      'A walk through the forest',
      'Finding your creative rhythm',
      'Building better habits',
      'The quiet ocean',
      'A sketchbook story',
      'Dart essentials',
      'Mountain mornings',
      'Music and motion',
    ];
    return Video(
      id: '${i + 1}',
      title:
          '${subjects[i % subjects.length]}${i >= 9 ? ' — Episode ${i ~/ 9 + 1}' : ''}',
      channel: Channel(
        id: '${i % 2 + 1}',
        ownerId: '${i % 2 + 1}',
        name: i.isEven ? 'Demo Creator' : 'Everyday Studio',
      ),
      category: category,
      createdAt: DateTime.utc(2026, 10, 29).subtract(Duration(hours: i * 12)),
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      description: 'A little inspiration from the MiniTube demo collection.',
    );
  });
  @override
  Future<List<Category>> categories() async => categoryList;
  @override
  Future<PageResult<Video>> videos({
    String? query,
    String? categoryId,
    int page = 1,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final q = (query ?? '').trim().toLowerCase();
    final filtered =
        items
            .where(
              (v) =>
                  (categoryId == null || v.category.id == categoryId) &&
                  v.title.toLowerCase().contains(q),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return PageResult(
      filtered.skip((page - 1) * 20).take(20).toList(),
      filtered.length,
      page,
      20,
    );
  }

  Video video(String id) => items.firstWhere(
    (v) => v.id == id,
    orElse: () => throw StateError('This video is no longer available.'),
  );
  final List<Comment> commentItems = [];
  List<Comment> comments(String id) =>
      commentItems.where((c) => c.videoId == id).toList().reversed.toList();
  Comment addComment(String id, User author, String content) {
    video(id);
    final text = content.trim();
    if (text.isEmpty || text.length > 500) {
      throw StateError('Enter 1–500 characters.');
    }
    final comment = Comment(
      id: '${++_commentId}',
      videoId: id,
      author: author,
      content: text,
      createdAt: DateTime.now().toUtc(),
    );
    commentItems.add(comment);
    return comment;
  }

  int _commentId = 0;
  void deleteComment(String id, String userId) {
    final comment = commentItems.firstWhere((c) => c.id == id);
    if (comment.author.id != userId) {
      throw StateError('You do not have permission to delete this comment.');
    }
    commentItems.remove(comment);
  }

  final Map<String, Channel> channels = {};
  Channel myChannel(User user) => channels.putIfAbsent(
    user.id,
    () => Channel(
      id: user.id,
      ownerId: user.id,
      name: user.id == '1' ? 'Demo Creator' : user.displayName,
    ),
  );
  Channel channel(String id) {
    for (final c in channels.values) {
      if (c.id == id) return c;
    }
    return items.firstWhere((v) => v.channel.id == id).channel;
  }

  void updateChannel(
    User user,
    String name,
    String description,
    String? avatar,
  ) {
    final old = myChannel(user);
    channels[user.id] = Channel(
      id: old.id,
      ownerId: user.id,
      name: name.trim(),
      description: description.trim(),
      avatarUrl: avatar,
    );
    for (var i = 0; i < items.length; i++) {
      final v = items[i];
      if (v.channel.ownerId == user.id) {
        items[i] = Video(
          id: v.id,
          title: v.title,
          channel: channels[user.id]!,
          category: v.category,
          createdAt: v.createdAt,
          description: v.description,
          videoUrl: v.videoUrl,
          thumbnailUrl: v.thumbnailUrl,
        );
      }
    }
    revision.value++;
  }

  int nextId = 46;
  Video saveVideo(User user, VideoWrite input, {String? id}) {
    final old = id == null ? null : video(id);
    if (old != null && old.channel.ownerId != user.id) {
      throw StateError('Permission denied.');
    }
    final value = Video(
      id: id ?? '${nextId++}',
      title: input.title.trim(),
      description: input.description.trim(),
      videoUrl: input.videoUrl.trim(),
      thumbnailUrl: input.thumbnailUrl,
      channel: myChannel(user),
      category: categoryList.firstWhere((c) => c.id == input.categoryId),
      createdAt: old?.createdAt ?? DateTime.now().toUtc(),
    );
    if (old != null) items.remove(old);
    items.add(value);
    revision.value++;
    return value;
  }

  void deleteVideo(String id, User user) {
    final old = video(id);
    if (old.channel.ownerId != user.id) throw StateError('Permission denied.');
    items.remove(old);
    commentItems.removeWhere((c) => c.videoId == id);
    revision.value++;
  }
}
