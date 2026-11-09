import 'package:minitube/core/errors/app_exception.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minitube/core/domain/models.dart';
import 'package:minitube/features/auth/data/repositories/remote_auth_repository.dart';
import 'package:minitube/features/video/data/repositories/remote_video_repository.dart';
void main(){test('Flutter API adapters register upload list edit delete and logout',() async {
 final auth=RemoteAuthRepository();
 final user=await auth.register('Flutter API Test','flutter-${DateTime.now().microsecondsSinceEpoch}@minitube.test','TestOnly1234');
 final repo=RemoteVideoRepository();
 final progressValues=<double>[];repo.uploadProgress.addListener((){final v=repo.uploadProgress.value;if(v!=null)progressValues.add(v);});
 final bytes=Uint8List(64);bytes[3]=64;bytes.setRange(4,8,'ftyp'.codeUnits);bytes.setRange(8,12,'isom'.codeUnits);
 final video=await repo.persistVideo(user,const VideoWrite(title:'Flutter API upload',description:'Adapter transport test',localVideoPath:'/test.mp4',categoryId:'1',thumbnailUrl:'https://example.com/thumbnail-one.jpg'),file:PlatformFile(name:'test.mp4',size:bytes.length,bytes:bytes));
 try {
  expect(video.thumbnailUrl,'https://example.com/thumbnail-one.jpg');
  expect(video.videoUrl,startsWith('http://localhost:3000/api/v1/videos/'));
  expect((await repo.videos(query:'Flutter API upload')).items.any((v)=>v.id==video.id),isTrue);
  await repo.loadMine();expect(repo.items.any((v)=>v.id==video.id),isTrue);
  final edited=await repo.persistVideo(user,const VideoWrite(title:'Edited via Flutter',description:'',localVideoPath:'/unused',categoryId:'2',thumbnailUrl:'https://example.com/thumbnail-two.jpg'),id:video.id);
  expect(edited.title,'Edited via Flutter');
  expect(edited.thumbnailUrl,'https://example.com/thumbnail-two.jpg');

  final replaced=await repo.persistVideo(user,const VideoWrite(title:'Replacement via Flutter',description:'',localVideoPath:'/test.mp4',categoryId:'1'),id:video.id,file:PlatformFile(name:'replace.mp4',size:bytes.length,bytes:bytes));
  expect(replaced.id,video.id);expect(replaced.title,'Replacement via Flutter');

  expect(progressValues.any((p)=>p>0),isTrue);
  void cancelAtStart(){if(repo.uploadProgress.value!=null)repo.cancelUpload();}
  repo.uploadProgress.addListener(cancelAtStart);
  try {
   await expectLater(repo.persistVideo(user,const VideoWrite(title:'Canceled replacement',description:'',localVideoPath:'/test.mp4',categoryId:'1'),id:video.id,file:PlatformFile(name:'cancel.mp4',size:bytes.length,bytes:bytes)),throwsA(isA<AppException>()));
   expect(repo.uploadProgress.value,isNull);
   expect(repo.video(video.id).title,'Replacement via Flutter');
  } finally {repo.uploadProgress.removeListener(cancelAtStart);}
 } finally {await repo.removeVideo(video.id,user);await auth.logout();}
},skip:!const bool.fromEnvironment('RUN_API_TESTS'));}

