import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minitube/core/domain/models.dart';
import 'package:minitube/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:minitube/features/auth/presentation/auth_controller.dart';
import 'package:minitube/features/video/data/repositories/video_repository_impl.dart';
import 'package:minitube/features/video/presentation/pages/video_detail_page.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakePlayer extends VideoPlayerPlatform {
  int created = 0;
  Duration position = const Duration(seconds: 12);
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async =>
      ++created;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(minutes: 2),
      size: const Size(1280, 720),
    ),
  );
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
  @override
  Future<void> dispose(int playerId) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<Duration> getPosition(int playerId) async => position;
  @override
  Future<void> seekTo(int playerId, Duration position) async {
    this.position = position;
  }
}

void main() {
  testWidgets('Fullscreen preserves playback and exits with Escape and Back', (
    tester,
  ) async {
    final previous = VideoPlayerPlatform.instance;
    final platform = FakePlayer();
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = previous);
    final repository = MockVideoRepository();
    final original = repository.items.first;
    repository.items[0] = Video(
      id: original.id,
      title: original.title,
      channel: original.channel,
      category: original.category,
      createdAt: original.createdAt,
      videoUrl: '/test.mp4',
    );
    final auth = AuthController(MockAuthRepository());
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      AuthScope(
        controller: auth,
        child: MaterialApp(
          home: VideoDetailPage(repository: repository, videoId: original.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final controller = tester
        .widget<VideoPlayer>(find.byType(VideoPlayer))
        .controller;
    await controller.seekTo(const Duration(seconds: 12));
    await controller.play();
    await tester.pump();
    await tester.tap(find.byTooltip('Fullscreen'));
    await tester.pump();
    expect(find.byType(AppBar), findsNothing);
    expect(
      tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
      same(controller),
    );
    expect(controller.value.position, const Duration(seconds: 12));
    expect(controller.value.isPlaying, isTrue);
    expect(platform.created, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Video details'), findsOneWidget);
    await tester.tap(find.byTooltip('Fullscreen'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Video details'), findsOneWidget);
    expect(controller.value.isPlaying, isTrue);
    expect(platform.created, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
