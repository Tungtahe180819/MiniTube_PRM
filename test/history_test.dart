import 'package:flutter_test/flutter_test.dart';
import 'package:minitube/core/domain/models.dart';
import 'package:minitube/features/video/data/repositories/video_repository_impl.dart';

void main() {
  test(
    'History upserts, isolates accounts, paginates and cascades deletion',
    () {
      final repo = MockVideoRepository();
      repo.recordHistory('1', '1');
      repo.recordHistory('1', '1');
      repo.recordHistory('2', '1');
      expect(repo.history('1').total, 1);
      repo.deleteHistory('1', videoId: '1');
      expect(repo.history('1').items, isEmpty);
      expect(repo.history('2').total, 1);
      for (var i = 1; i <= 25; i++) {
        repo.recordHistory('1', '$i');
      }
      expect(repo.history('1').items.length, 20);
      expect(repo.history('1', page: 2).items.length, 5);
      repo.deleteVideo(
        '1',
        const User(id: '1', email: 'demo@minitube.app', displayName: 'Demo'),
      );
      expect(repo.history('1').total, 24);
      expect(repo.history('2').total, 0);
      repo.deleteHistory('1');
      expect(repo.history('1').total, 0);
    },
  );
}
