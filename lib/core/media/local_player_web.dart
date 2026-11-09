import 'package:video_player/video_player.dart';

VideoPlayerController localPlayer(String path) =>
    VideoPlayerController.networkUrl(Uri.parse(path));
