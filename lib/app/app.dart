import 'package:flutter/material.dart';

import 'router/app_router.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/presentation/auth_controller.dart';
import 'theme/app_theme.dart';

class MiniTubeApp extends StatefulWidget {
  const MiniTubeApp({super.key});
  @override
  State<MiniTubeApp> createState() => _MiniTubeAppState();
}

class _MiniTubeAppState extends State<MiniTubeApp> {
  late final auth = AuthController(MockAuthRepository());
  @override
  void dispose() {
    auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthScope(
    controller: auth,
    child: MaterialApp(
      title: 'MiniTube',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      onGenerateRoute: AppRouter.generate,
    ),
  );
}
