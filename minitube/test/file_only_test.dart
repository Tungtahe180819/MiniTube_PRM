import 'package:flutter_test/flutter_test.dart';
import 'package:minitube/core/domain/models.dart';
import 'package:minitube/features/video/data/repositories/video_repository_impl.dart';
void main() {
 test('Video creation rejects URLs and accepts local file references', () {
  final repo=MockVideoRepository();
  const user=User(id:'1',email:'demo@minitube.app',displayName:'Demo');
  for(final source in ['', 'https://example.com/a.mp4','http://example.com/a.mp4','data:video/mp4;base64,AAAA']) {
   expect(() => repo.saveVideo(user,VideoWrite(title:'Test',description:'',localVideoPath:source,categoryId:'1')),throwsStateError);
  }
  final video=repo.saveVideo(user,const VideoWrite(title:'Local',description:'',localVideoPath:'/local/sample.mp4',categoryId:'1'));
  expect(video.videoUrl,'/local/sample.mp4');
 });
}
