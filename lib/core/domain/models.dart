class User {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });
  final String id, email, displayName;
  final String? avatarUrl;
  factory User.fromJson(Map<String, dynamic> j) => User(
    id: '${j['id']}',
    email: j['email'] ?? '',
    displayName: j['displayName'] ?? '',
    avatarUrl: j['avatarUrl'],
  );
}

class Channel {
  const Channel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description = '',
    this.avatarUrl,
  });
  final String id, ownerId, name, description;
  final String? avatarUrl;
  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
    id: '${j['id']}',
    ownerId: '${j['ownerId'] ?? ''}',
    name: j['name'] ?? '',
    description: j['description'] ?? '',
    avatarUrl: j['avatarUrl'],
  );
}

class Category {
  const Category(this.id, this.name);
  final String id, name;
  factory Category.fromJson(Map<String, dynamic> j) =>
      Category('${j['id']}', j['name'] as String);
}

class Video {
  const Video({
    required this.id,
    required this.title,
    required this.channel,
    required this.category,
    required this.createdAt,
    this.description = '',
    this.videoUrl = '',
    this.thumbnailUrl,
  });
  final String id, title, description, videoUrl;
  final String? thumbnailUrl;
  final Channel channel;
  final Category category;
  final DateTime createdAt;
  factory Video.fromJson(Map<String, dynamic> j) => Video(
    id: '${j['id']}',
    title: j['title'] ?? '',
    description: j['description'] ?? '',
    videoUrl: j['videoUrl'] ?? '',
    thumbnailUrl: j['thumbnailUrl'],
    channel: Channel.fromJson(j['channel'] as Map<String, dynamic>),
    category: Category.fromJson(j['category'] as Map<String, dynamic>),
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

class VideoWrite {
  const VideoWrite({
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.categoryId,
    this.thumbnailUrl,
  });
  final String title, description, videoUrl, categoryId;
  final String? thumbnailUrl;
  Map<String, dynamic> toJson() => {
    'title': title.trim(),
    'description': description.trim(),
    'videoUrl': videoUrl.trim(),
    'thumbnailUrl': thumbnailUrl?.trim().isEmpty == true
        ? null
        : thumbnailUrl?.trim(),
    'categoryId': categoryId,
  };
}

class Comment {
  const Comment({
    required this.id,
    required this.videoId,
    required this.author,
    required this.content,
    required this.createdAt,
  });
  final String id, videoId, content;
  final User author;
  final DateTime createdAt;
  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
    id: '${j['id']}',
    videoId: '${j['videoId']}',
    author: User.fromJson(j['author'] as Map<String, dynamic>),
    content: j['content'] ?? '',
    createdAt: DateTime.parse(j['createdAt']),
  );
}

class HistoryItem {
  const HistoryItem(this.video, this.lastWatchedAt);
  final Video video;
  final DateTime lastWatchedAt;
  factory HistoryItem.fromJson(Map<String, dynamic> j) => HistoryItem(
    Video.fromJson(j['video'] as Map<String, dynamic>),
    DateTime.parse(j['lastWatchedAt']),
  );
}

class PageResult<T> {
  const PageResult(this.items, this.total, this.page, this.pageSize);
  final List<T> items;
  final int total, page, pageSize;
  bool get hasMore => page * pageSize < total;
}
