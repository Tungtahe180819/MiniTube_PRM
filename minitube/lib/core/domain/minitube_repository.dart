import 'models.dart';

abstract class MiniTubeRepository {
  bool get isMock;
  void Function()? onSessionExpired;
  Future<User> login(String email, String password);
  Future<User> register(String name, String email, String password);
  Future<void> logout();
  Future<User> updateProfile(String name, String? avatarUrl);
  Future<List<Category>> categories();
  Future<PageResult<Video>> videos({
    String? query,
    String? categoryId,
    String? channelId,
    bool mine = false,
    int page = 1,
  });
  Future<Video> video(String id);
  Future<Video> createVideo(VideoWrite input);
  Future<Video> updateVideo(String id, VideoWrite input);
  Future<void> deleteVideo(String id);
  Future<Channel> channel(String id);
  Future<Channel> myChannel();
  Future<Channel> updateChannel(
    String name,
    String description,
    String? avatarUrl,
  );
  Future<PageResult<Comment>> comments(String videoId, {int page = 1});
  Future<Comment> addComment(String videoId, String content);
  Future<void> deleteComment(String id);
  Future<PageResult<HistoryItem>> history({int page = 1});
  Future<void> recordHistory(String videoId);
  Future<void> deleteHistory(String? videoId);
  void dispose() {}
}
