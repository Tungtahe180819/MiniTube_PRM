import 'package:flutter/material.dart';

import '../../features/channel/presentation/pages/channel_detail_page.dart';

import '../../features/video/presentation/pages/manage_video_page.dart';
import '../../features/channel/presentation/pages/my_channel_page.dart';

import '../../features/video/presentation/pages/video_detail_page.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/video/data/repositories/video_repository_impl.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

abstract final class AppRouter {
  static final videos = MockVideoRepository();
  static const destinations = <String, String>{
    '/login': 'Login',
    '/register': 'Register',
    '/video': 'Video details',
    '/manage': 'Manage videos',
    '/add': 'Add video',
    '/edit': 'Edit video',
    '/channel': 'Channel details',
    '/my-channel': 'My channel',
  };
  static Route<dynamic> generate(
    RouteSettings settings,
  ) => MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => settings.name == '/'
        ? const AppShell()
        : settings.name == '/channel'
        ? ChannelDetailPage(
            repository: videos,
            id: settings.arguments as String,
          )
        : settings.name == '/manage'
        ? ManageVideoPage(repository: videos)
        : settings.name == '/my-channel'
        ? MyChannelPage(repository: videos)
        : settings.name == '/add' || settings.name == '/edit'
        ? VideoEditorPage(
            repository: videos,
            id: settings.name == '/edit' ? settings.arguments as String : null,
          )
        : settings.name == '/video'
        ? VideoDetailPage(
            repository: videos,
            videoId: settings.arguments is String
                ? settings.arguments as String
                : '',
          )
        : settings.name == '/login' || settings.name == '/register'
        ? LoginPage(register: settings.name == '/register')
        : Scaffold(
            appBar: AppBar(
              title: Text(destinations[settings.name] ?? 'Page unavailable'),
            ),
            body: FoundationPage(
              title: destinations[settings.name] ?? 'Page unavailable',
            ),
          ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  bool wasAuthenticated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authenticated = AuthScope.of(context).user != null;
    if (authenticated && !wasAuthenticated) {
      index = 0;
    }
    wasAuthenticated = authenticated;
  }

  final videos = AppRouter.videos;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(
        children: [
          Icon(Icons.play_circle_fill, color: Colors.red),
          SizedBox(width: 8),
          Text('MiniTube', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
      actions: [
        IconButton(
          tooltip: AuthScope.of(context).user == null ? 'Login' : 'My profile',
          onPressed: () async {
            if (AuthScope.of(context).user != null) {
              setState(() => index = 3);
              return;
            }
            await Navigator.pushNamed(context, '/login');
            if (context.mounted && AuthScope.of(context).user != null) {
              setState(() => index = 0);
            }
          },
          icon: Icon(
            AuthScope.of(context).user == null
                ? Icons.account_circle_outlined
                : Icons.account_circle,
          ),
        ),
      ],
    ),
    body: IndexedStack(
      index: index,
      children: [
        HomePage(repository: videos),
        HomePage(repository: videos, search: true),
        const FoundationPage(title: 'History'),
        const ProfilePage(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
        NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}

class FoundationPage extends StatelessWidget {
  const FoundationPage({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            const Text(
              'MiniTube frontend foundation',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This screen is a navigation preview. Features will be added in the next implementation stages.',
              textAlign: TextAlign.center,
            ),
            if (title == 'Profile') ...[
              const SizedBox(height: 24),
              for (final entry in AppRouter.destinations.entries)
                ListTile(
                  title: Text(entry.value),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, entry.key),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}
