import 'package:flutter_test/flutter_test.dart';
import 'package:minitube/core/domain/models.dart';
import 'package:minitube/features/video/data/repositories/video_repository_impl.dart';
void main() {
 test('CRUD enforces ownership and channel edits propagate to videos', () {
  final repo = MockVideoRepository();
  const owner = User(id:'1', email:'a@demo.app', displayName:'A');
  const other = User(id:'2', email:'b@demo.app', displayName:'B');
  const input = VideoWrite(title:'New video',description:'Description',videoUrl:'https://example.com/a.mp4',categoryId:'1');
  final v = repo.saveVideo(owner,input);
  expect(repo.video(v.id).title,'New video');
  expect(() => repo.saveVideo(other,input,id:v.id),throwsStateError);
  expect(() => repo.deleteVideo(v.id,other),throwsStateError);
  repo.updateChannel(owner,'Updated channel','About',null);
  expect(repo.video(v.id).channel.name,'Updated channel');
  repo.saveVideo(owner,const VideoWrite(title:'Edited video',description:'',videoUrl:'https://example.com/b.mp4',categoryId:'2'),id:v.id);
  expect(repo.video(v.id).title,'Edited video');
  repo.addComment(v.id,owner,'Comment');
  repo.deleteVideo(v.id,owner);
  expect(() => repo.video(v.id),throwsStateError);
  expect(repo.comments(v.id),isEmpty);
  const newcomer = User(id:'3',email:'c@demo.app',displayName:'New');
  expect(repo.items.where((v) => v.channel.ownerId == newcomer.id),isEmpty);
  expect(repo.myChannel(newcomer).name,'New');
 });
}
