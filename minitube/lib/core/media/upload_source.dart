import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../errors/app_exception.dart';

Stream<List<int>> uploadSource(PlatformFile file) {
  if (file.bytes != null) return Stream.value(file.bytes!);
  if (file.readStream != null) return file.readStream!;
  if (!kIsWeb && file.path != null) return file.xFile.openRead();
  throw const AppException(
    'This file cannot be read. Please choose the video again.',
  );
}
