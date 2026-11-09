import 'package:flutter/material.dart';

import '../../../video/data/repositories/video_repository_impl.dart';

import '../../../../core/domain/models.dart';
import '../../../video/domain/repositories/video_repository.dart';
import '../../../video/presentation/widgets/video_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.repository, this.search = false});
  final VideoRepository repository;
  final bool search;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final query = TextEditingController();
  List<Category> categories = [];
  List<Video> items = [];
  String? categoryId, error;
  String submitted = '';
  bool loading = false, hasMore = false, started = false;
  int page = 0, total = 0, request = 0;
  @override
  void initState() {
    super.initState();
    if (widget.repository is MockVideoRepository) {
      (widget.repository as MockVideoRepository).revision.addListener(
        refreshFeed,
      );
    }
    if (!widget.search) load();
  }

  void refreshFeed() {
    if (started) load();
  }

  @override
  void dispose() {
    if (widget.repository is MockVideoRepository) {
      (widget.repository as MockVideoRepository).revision.removeListener(
        refreshFeed,
      );
    }
    request++;
    query.dispose();
    super.dispose();
  }

  Future<void> load({bool more = false}) async {
    final ticket = ++request;
    final nextPage = more ? page + 1 : 1;
    setState(() {
      loading = true;
      error = null;
      started = true;
      if (!more) {
        items = [];
        hasMore = false;
      }
    });
    try {
      final cats = await widget.repository.categories();
      final result = await widget.repository.videos(
        query: submitted,
        categoryId: categoryId,
        page: nextPage,
      );
      if (!mounted || ticket != request) return;
      setState(() {
        categories = cats;
        items = more ? [...items, ...result.items] : result.items;
        page = nextPage;
        total = result.total;
        hasMore = result.hasMore;
        loading = false;
      });
    } catch (_) {
      if (!mounted || ticket != request) return;
      setState(() {
        error = 'Unable to load videos. Please try again.';
        loading = false;
      });
    }
  }

  void search() {
    if (query.text.trim().length > 100) return;
    submitted = query.text.trim();
    load();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () => load(),
    child: ListView(
      key: PageStorageKey(widget.search ? 'search-feed' : 'home-feed'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.search
                      ? 'Find your next watch'
                      : 'Discover something good',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.search
                      ? 'Search videos by title.'
                      : 'Fresh perspectives from the MiniTube community.',
                ),
                const SizedBox(height: 20),
                if (widget.search) ...[
                  TextField(
                    key: const Key('video-search'),
                    controller: query,
                    maxLength: 100,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => search(),
                    decoration: InputDecoration(
                      labelText: 'Search videos',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          query.clear();
                          search();
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: search,
                    child: const Text('Search videos'),
                  ),
                  const SizedBox(height: 16),
                ],
                if (categories.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('All'),
                            selected: categoryId == null,
                            onSelected: (_) {
                              categoryId = null;
                              load();
                            },
                          ),
                        ),
                        for (final c in categories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(c.name),
                              selected: categoryId == c.id,
                              onSelected: (_) {
                                categoryId = c.id;
                                load();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if (!started)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Enter a title to start exploring.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (started && !loading && error == null)
                  Text(
                    '$total videos${submitted.isEmpty ? '' : ' for “$submitted”'}',
                  ),
                for (final video in items)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: VideoCard(video: video),
                  ),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(error!),
                        TextButton(
                          onPressed: () => load(more: items.isNotEmpty),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                if (started && !loading && error == null && items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No matching videos found.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (hasMore && !loading && error == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: OutlinedButton(
                      onPressed: () => load(more: true),
                      child: const Text('Load more'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
