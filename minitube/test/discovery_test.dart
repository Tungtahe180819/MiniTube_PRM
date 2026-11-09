import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minitube/app/app.dart';
import 'package:minitube/features/video/data/repositories/video_repository_impl.dart';

void main() {
  test('Feed pagination, title search and category filtering agree', () async {
    final repo = MockVideoRepository();
    final first = await repo.videos();
    final second = await repo.videos(page: 2);
    expect(first.items.length, 20);
    expect(first.total, 45);
    expect(first.hasMore, isTrue);
    expect(
      first.items
          .map((v) => v.id)
          .toSet()
          .intersection(second.items.map((v) => v.id).toSet()),
      isEmpty,
    );
    final filtered = await repo.videos(query: ' FLUTTER ', categoryId: '1');
    expect(filtered.items, isNotEmpty);
    expect(
      filtered.items.every(
        (v) =>
            v.title.toLowerCase().contains('flutter') && v.category.id == '1',
      ),
      isTrue,
    );
    expect((await repo.videos(query: 'no-such-video')).total, 0);
  });
  testWidgets(
    'Home loads categories and search handles matching and empty results',
    (tester) async {
      await tester.pumpWidget(const MiniTubeApp());
      await tester.pumpAndSettle();
      expect(find.text('45 videos'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.search).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('video-search')), 'Flutter');
      await tester.tap(find.widgetWithText(FilledButton, 'Search videos'));
      await tester.pumpAndSettle();
      expect(find.text('5 videos for “Flutter”'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('video-search')),
        'no-such-video',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Search videos'));
      await tester.pumpAndSettle();
      expect(find.text('No matching videos found.'), findsOneWidget);
    },
  );
}
