import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:minitube/core/media/upload_source.dart';
import 'package:minitube/core/errors/app_exception.dart';

void main() {
  test('Uploads bytes without needing a path', () async {
    final data = Uint8List.fromList([1, 2, 3]);
    final file = PlatformFile(name: 'video.mp4', size: 3, bytes: data);
    expect(await uploadSource(file).expand((e) => e).toList(), [1, 2, 3]);
  });
  test('Uploads a provided file stream without bytes or path', () async {
    final file = PlatformFile(
      name: 'video.mp4',
      size: 3,
      readStream: Stream.value([4, 5, 6]),
    );
    expect(await uploadSource(file).expand((e) => e).toList(), [4, 5, 6]);
  });
  test(
    'Missing file content produces a useful error instead of null failure',
    () {
      expect(
        () => uploadSource(PlatformFile(name: 'video.mp4', size: 3)),
        throwsA(isA<AppException>()),
      );
    },
  );
}
