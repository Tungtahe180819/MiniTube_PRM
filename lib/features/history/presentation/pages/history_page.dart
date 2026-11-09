import 'package:flutter/material.dart';

import '../../../../core/domain/models.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../video/data/repositories/video_repository_impl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.repository});
  final MockVideoRepository repository;
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String? account, error;
  List<HistoryItem> entries = [];
  bool busy = false;
  bool more = false;
  int page = 0, ticket = 0;
  @override
  void initState() {
    super.initState();
    widget.repository.revision.addListener(refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = AuthScope.of(context).user?.id;
    if (id != account) {
      account = id;
      entries = [];
      page = 0;
      ticket++;
      if (id != null) load();
    }
  }

  void refresh() {
    if (account != null) load();
  }

  @override
  void dispose() {
    ticket++;
    widget.repository.revision.removeListener(refresh);
    super.dispose();
  }

  Future<void> load({bool append = false}) async {
    final id = account;
    if (id == null) return;
    final current = ++ticket;
    setState(() => busy = true);
    try {
      final result = await widget.repository.fetchHistory(
        id,
        page: append ? page + 1 : 1,
      );
      if (!mounted || ticket != current) return;
      setState(() {
        entries = append ? [...entries, ...result.items] : result.items;
        page = result.page;
        more = result.hasMore;
        error = null;
      });
    } catch (e) {
      if (mounted && ticket == current) setState(() => error = e.toString());
    } finally {
      if (mounted && ticket == current) setState(() => busy = false);
    }
  }

  Future<void> remove({String? id}) async {
    final user = account;
    if (user == null) return;
    if (id == null) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Clear watch history?'),
          content: const Text('Videos will not be deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Clear all'),
            ),
          ],
        ),
      );
      if (yes != true || !mounted) return;
    }
    try {
      await widget.repository.removeHistory(user, videoId: id);
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (account == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Login to view your watch history.'),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Watch history',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextButton(
                onPressed: busy || entries.isEmpty ? null : () => remove(),
                child: const Text('Clear all'),
              ),
            ],
          ),
          if (error != null)
            TextButton(onPressed: () => load(), child: Text('$error — Retry')),
          if (!busy && entries.isEmpty && error == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No watch history yet. Play a video from Home to get started.',
              ),
            ),
          for (final e in entries)
            ListTile(
              title: Text(e.video.title),
              subtitle: Text(
                '${e.video.channel.name} • ${e.lastWatchedAt.toLocal()}',
              ),
              onTap: () async {
                await Navigator.pushNamed(
                  context,
                  '/video',
                  arguments: e.video.id,
                );
                if (mounted) load();
              },
              trailing: IconButton(
                tooltip: 'Remove from history',
                onPressed: busy ? null : () => remove(id: e.video.id),
                icon: const Icon(Icons.close),
              ),
            ),
          if (busy) const Center(child: CircularProgressIndicator()),
          if (more && !busy)
            OutlinedButton(
              onPressed: () => load(append: true),
              child: const Text('Load more'),
            ),
        ],
      ),
    );
  }
}
