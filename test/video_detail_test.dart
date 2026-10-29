import 'package:flutter_test/flutter_test.dart';
import 'package:minitube/core/domain/models.dart';
import 'package:minitube/features/video/data/repositories/video_repository_impl.dart';
void main() {
  test('Video lookup and comment ownership validation', () {
    final repo = MockVideoRepository();
    const owner = User(id: '1', email: 'demo@minitube.app', displayName: 'Demo');
    expect(repo.video('1').videoUrl, startsWith('https://'));
    expect(() => repo.video('missing'), throwsStateError);
    expect(() => repo.addComment('1', owner, '   '), throwsStateError);
    final comment = repo.addComment('1', owner, ' Hello ');
    expect(repo.comments('1').single.content, 'Hello');
    expect(repo.comments('2'), isEmpty);
    expect(() => repo.deleteComment(comment.id, '2'), throwsStateError);
    expect(repo.comments('1').length, 1);
    repo.deleteComment(comment.id, '1');
    expect(repo.comments('1'), isEmpty);
  });
}
